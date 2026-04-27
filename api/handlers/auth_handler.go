package handlers

import (
	"context"
	"net/http"

	"reserva-backend/dto"
	"reserva-backend/security"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	q *dto.Queries
}

func NewAuthHandler(q *dto.Queries) *AuthHandler {
	return &AuthHandler{q}
}

/* =========================
   DTOs
========================= */

type loginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type loginResponse struct {
	AccessToken string  `json:"access_token"`
	Payload     payload `json:"payload"`
}

type payload struct {
	ID    int32  `json:"id"`
	Email string `json:"email"`
	Role  string `json:"role"`
}

/* =========================
   LOGIN
========================= */

func (h *AuthHandler) Login(c *gin.Context) {

	var req loginRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	user, err := h.q.GetUserByEmail(context.Background(), req.Email)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "usuario no existe"})
		return
	}

	err = security.CheckPassword(req.Password, user.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "password incorrecto"})
		return
	}

	token, err := security.CreateToken(user.ID, user.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error generando token"})
		return
	}

	c.JSON(http.StatusOK, loginResponse{
		AccessToken: token,
		Payload: payload{
			ID:    user.ID,
			Email: user.Email,
			Role:  user.Role.String,
		},
	})
}
