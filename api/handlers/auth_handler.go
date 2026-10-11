package handlers

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"net/url"
	"time"

	"reserva-backend/security"

	"github.com/gin-gonic/gin"
)

// Valores de rol que ya usa el frontend y las rutas (RequireRole).
const (
	rolAdmin     = "Administrador"
	rolRecepcion = "Recepcionista"
)

const duracionSesion = 24 * time.Hour

type AuthHandler struct {
	token    security.Builder
	sessions *security.SessionStore
	baseDSN  string // DB_SOURCE: se usa solo como plantilla (servidor y base)
}

func NewAuthHandler(
	token security.Builder,
	sessions *security.SessionStore,
	baseDSN string,
) *AuthHandler {
	return &AuthHandler{token: token, sessions: sessions, baseDSN: baseDSN}
}

/* =========================
   DTOs
========================= */

type loginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type loginUser struct {
	ID     int32          `json:"id"`
	Name   string         `json:"name"`
	Email  string         `json:"email"`
	Role   string         `json:"role"`
	Image  string         `json:"image"`
	Cedula sql.NullString `json:"cedula" swaggerignore:"true"`
}

type loginResponse struct {
	AccessToken string    `json:"access_token"`
	User        loginUser `json:"user"`
}

/* =========================
   LOGIN
========================= */

// Login godoc
// @Summary Iniciar sesión con un usuario de SQL Server
// @Description Valida las credenciales contra el motor de base de datos y retorna un token PASETO
// @Tags auth
// @Accept json
// @Produce json
// @Param credentials body loginRequest true "Usuario y contraseña del motor"
// @Success 200 {object} loginResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req loginRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Datos de inicio de sesión inválidos",
		})
		return
	}

	// 1. El propio SQL Server valida usuario y contraseña.
	db, err := h.abrirConexion(c.Request.Context(), req.Username, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Usuario o contraseña incorrectos",
		})
		return
	}

	// 2. Se consulta quién es y a qué rol del motor pertenece.
	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	var (
		nombreBD    string
		principalID int32
		rol         string
		cedula      sql.NullString
	)

	err = db.QueryRowContext(ctx, `
		SELECT
			USER_NAME(),
			DATABASE_PRINCIPAL_ID(),
			CASE
				WHEN IS_MEMBER('rol_admin_hotel') = 1 THEN 'Administrador'
				WHEN IS_MEMBER('rol_recepcion')   = 1 THEN 'Recepcionista'
				ELSE ''
			END,
			dbo.fn_RecepcionistaActual()
	`).Scan(&nombreBD, &principalID, &rol, &cedula)

	if err != nil {
		_ = db.Close()
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "No fue posible consultar el rol del usuario",
		})
		return
	}

	if rol == "" {
		_ = db.Close()
		c.JSON(http.StatusForbidden, gin.H{
			"error": "Tu usuario no tiene un rol asignado en el sistema",
		})
		return
	}

	// 3. Se abre la sesión en el servidor (la conexión queda guardada).
	sessionID := h.sessions.Create(&security.Session{
		DB:        db,
		Username:  req.Username,
		Role:      rol,
		ExpiresAt: time.Now().Add(duracionSesion),
	})

	// 4. Token PASETO (no lleva la contraseña, solo el id de sesión).
	token, err := h.token.CreateToken(
		principalID,
		req.Username,
		rol,
		nombreBD,
		"",
		sessionID,
		duracionSesion,
	)
	if err != nil {
		h.sessions.Delete(sessionID)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Error generando el token de acceso",
		})
		return
	}

	// 5. Auditoría de inicio de sesión (si falla, no bloquea el ingreso).
	h.registrarSesion(ctx, db, "LOGIN", req.Username, c.ClientIP(), "Inicio de sesión")

	c.JSON(http.StatusOK, loginResponse{
		AccessToken: token,
		User: loginUser{
			ID:     principalID,
			Name:   nombreBD,
			Email:  req.Username,
			Role:   rol,
			Image:  "",
			Cedula: cedula,
		},
	})
}

/* =========================
   LOGOUT
========================= */

// Logout godoc
// @Summary Cerrar sesión
// @Description Registra el cierre de sesión y cierra la conexión del usuario
// @Tags auth
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /logout [post]
func (h *AuthHandler) Logout(c *gin.Context) {
	idAny, ok := c.Get("session_id")
	sessionID, _ := idAny.(string)

	if !ok || sessionID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "sesión no válida"})
		return
	}

	if sess, found := h.sessions.Get(sessionID); found {
		h.registrarSesion(c.Request.Context(), sess.DB, "LOGOUT", sess.Username, c.ClientIP(), "Cierre de sesión")
	}

	h.sessions.Delete(sessionID)

	c.JSON(http.StatusOK, gin.H{"message": "sesión cerrada"})
}

/* =========================
   AUXILIARES
========================= */

// abrirConexion toma DB_SOURCE (formato URL), cambia usuario y contraseña
// por los que escribió la persona y comprueba que el motor los acepte.
func (h *AuthHandler) abrirConexion(ctx context.Context, usuario, clave string) (*sql.DB, error) {
	u, err := url.Parse(h.baseDSN)
	if err != nil {
		return nil, err
	}
	u.User = url.UserPassword(usuario, clave)

	db, err := sql.Open("sqlserver", u.String())
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(2)
	db.SetConnMaxLifetime(30 * time.Minute)

	pingCtx, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()

	if err := db.PingContext(pingCtx); err != nil {
		_ = db.Close()
		return nil, err
	}

	return db, nil
}

func (h *AuthHandler) registrarSesion(
	ctx context.Context,
	db *sql.DB,
	accion, usuario, ip, detalle string,
) {
	_, err := db.ExecContext(
		ctx,
		`EXEC dbo.pa_Auditoria_RegistrarSesion
			@accion = @Accion,
			@usuarioApp = @Usuario,
			@ipOrigen = @Ip,
			@detalle = @Detalle`,
		sql.Named("Accion", accion),
		sql.Named("Usuario", usuario),
		sql.Named("Ip", ip),
		sql.Named("Detalle", detalle),
	)
	if err != nil {
		log.Printf("auditoría de sesión (%s) no registrada: %v", accion, err)
	}
}
