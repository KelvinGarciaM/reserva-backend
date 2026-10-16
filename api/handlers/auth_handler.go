package handlers

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"net/url"
	"time"

	"reserva-backend/repository"
	"reserva-backend/security"

	"github.com/gin-gonic/gin"
)

const (
	rolAdmin     = "Administrador"
	rolRecepcion = "Recepcionista"
)

const duracionSesion = 24 * time.Hour

// CredencialBD es el login real del motor SQL Server que se usa según el rol.
type CredencialBD struct {
	Usuario string
	Clave   string
}

type AuthHandler struct {
	usuarios *repository.UsuarioRepository // tabla usuario (email + hash bcrypt)
	token    security.Builder
	sessions *security.SessionStore
	baseDSN  string                  // DB_SOURCE: solo plantilla (servidor y base)
	cuentas  map[string]CredencialBD // rol de la app -> login del motor
}

func NewAuthHandler(
	usuarios *repository.UsuarioRepository,
	token security.Builder,
	sessions *security.SessionStore,
	baseDSN string,
	admin CredencialBD,
	recepcion CredencialBD,
) *AuthHandler {
	return &AuthHandler{
		usuarios: usuarios,
		token:    token,
		sessions: sessions,
		baseDSN:  baseDSN,
		cuentas: map[string]CredencialBD{
			rolAdmin:     admin,
			rolRecepcion: recepcion,
		},
	}
}

/* =========================
   DTOs (los mismos del login original)
========================= */

type loginRequest struct {
	Email    string `json:"email" binding:"required"`
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
// @Summary Iniciar sesión
// @Description Valida el usuario en la tabla usuario y abre la conexión con el login del motor que corresponde a su rol
// @Tags auth
// @Accept json
// @Produce json
// @Param credentials body loginRequest true "Credenciales del usuario"
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

	// 1. Buscar al usuario activo en la tabla usuario.
	user, err := h.usuarios.ObtenerPorEmail(c.Request.Context(), req.Email)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Usuario no existe o se encuentra inactivo",
		})
		return
	}

	// 2. Comparar la contraseña con el hash bcrypt.
	if err := security.CheckPassword(req.Password, user.Password); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Contraseña incorrecta",
		})
		return
	}

	// 3. Según el rol del usuario, se elige el login del motor.
	rol := user.Role.String
	cred, ok := h.cuentas[rol]
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{
			"error": "Tu usuario no tiene un rol asignado en el sistema",
		})
		return
	}

	// 4. Se abre la conexión con el login del motor (admin o recepción).
	db, err := h.abrirConexion(c.Request.Context(), cred.Usuario, cred.Clave)
	if err != nil {
		log.Printf("no se pudo abrir la conexión del rol %s: %v", rol, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "No fue posible conectar con la base de datos",
		})
		return
	}

	// 5. Doble verificación: el motor debe confirmar el mismo rol.
	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	var rolMotor string
	err = db.QueryRowContext(ctx, `
		SELECT CASE
			WHEN IS_MEMBER('rol_admin_hotel') = 1 THEN 'Administrador'
			WHEN IS_MEMBER('rol_recepcion')   = 1 THEN 'Recepcionista'
			ELSE ''
		END
	`).Scan(&rolMotor)

	if err != nil || rolMotor != rol {
		_ = db.Close()
		c.JSON(http.StatusForbidden, gin.H{
			"error": "El rol del usuario no coincide con el rol de la base de datos",
		})
		return
	}

	// 6. Se abre la sesión en el servidor (la conexión queda guardada).
	sessionID := h.sessions.Create(&security.Session{
		DB:        db,
		Username:  user.Email,
		Role:      rol,
		ExpiresAt: time.Now().Add(duracionSesion),
	})

	image := ""
	if user.Image.Valid {
		image = user.Image.String
	}

	// 7. Token PASETO (lleva el id de sesión, nunca contraseñas).
	token, err := h.token.CreateToken(
		user.ID,
		user.Email,
		rol,
		user.Name,
		image,
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

	// 8. Auditoría (si falla, no bloquea el ingreso).
	h.registrarSesion(ctx, db, "LOGIN", user.Email, c.ClientIP(), "Inicio de sesión")

	c.JSON(http.StatusOK, loginResponse{
		AccessToken: token,
		User: loginUser{
			ID:     user.ID,
			Name:   user.Name,
			Email:  user.Email,
			Role:   rol,
			Image:  image,
			Cedula: user.Cedula,
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

// abrirConexion toma DB_SOURCE (formato URL), pone el login del motor
// correspondiente al rol y comprueba que el motor lo acepte.
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
