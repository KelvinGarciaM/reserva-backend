package handlers

import (
	"context"
	"database/sql"
	"net/http"
	"time"

	"reserva-backend/dto"
	"reserva-backend/security"

	"github.com/gin-gonic/gin"
)

/* =========================
   STRUCT
========================= */

type AuthHandler struct {
	q     *dto.Queries
	token security.Builder
}

func NewAuthHandler(q *dto.Queries, token security.Builder) *AuthHandler {
	return &AuthHandler{
		q:     q,
		token: token,
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
// @Description Autentica un usuario y retorna un token JWT
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

	// Validar request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	// Buscar usuario
	user, err := h.q.GetUserByEmail(context.Background(), req.Email)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "usuario no existe"})
		return
	}

	// Verificar contraseña
	err = security.CheckPassword(req.Password, user.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "password incorrecto"})
		return
	}
	image := ""
	if user.Image.Valid {
		image = user.Image.String
	}
	// Crear token ( usando Builder)
	token, err := h.token.CreateToken(
		user.ID,
		user.Email,
		user.Role.String,
		user.Name,
		image,
		time.Hour*24,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error generando token"})
		return
	}

	// Respuesta
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
