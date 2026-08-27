package handlers

import (
	"database/sql"
	"net/http"
	"time"

	"reserva-backend/repository"
	"reserva-backend/security"

	"github.com/gin-gonic/gin"
)

/* =========================
   STRUCT
========================= */

type AuthHandler struct {
	usuarios *repository.UsuarioRepository
	token    security.Builder
}

func NewAuthHandler(
	usuarios *repository.UsuarioRepository,
	token security.Builder,
) *AuthHandler {
	return &AuthHandler{
		usuarios: usuarios,
		token:    token,
	}
}

/* =========================
   DTOs
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
	Cedula sql.NullString `json:"cedula"`
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
// @Description Autentica un usuario y retorna un token PASETO
// @Tags auth
// @Accept json
// @Produce json
// @Param credentials body loginRequest true "Credenciales del usuario"
// @Success 200 {object} loginResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /login [post]
func (h *AuthHandler) Login(c *gin.Context) {
	var req loginRequest

	// Validar el JSON recibido.
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Datos de inicio de sesión inválidos",
		})
		return
	}

	// Buscar usuario activo en SQL Server.
	user, err := h.usuarios.ObtenerPorEmail(
		c.Request.Context(),
		req.Email,
	)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Usuario no existe o se encuentra inactivo",
		})
		return
	}

	// Comparar la contraseña recibida con el hash bcrypt.
	if err := security.CheckPassword(
		req.Password,
		user.Password,
	); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Contraseña incorrecta",
		})
		return
	}

	// Convertir la imagen nullable a string.
	image := ""

	if user.Image.Valid {
		image = user.Image.String
	}

	// Crear token PASETO.
	token, err := h.token.CreateToken(
		user.ID,
		user.Email,
		user.Role.String,
		user.Name,
		image,
		time.Hour*24,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Error generando el token de acceso",
		})
		return
	}

	// Responder al frontend.
	c.JSON(http.StatusOK, loginResponse{
		AccessToken: token,
		User: loginUser{
			ID:     user.ID,
			Name:   user.Name,
			Email:  user.Email,
			Role:   user.Role.String,
			Image:  image,
			Cedula: user.Cedula,
		},
	})
}
