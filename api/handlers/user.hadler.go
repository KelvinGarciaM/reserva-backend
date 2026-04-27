package handlers

import (
	"context"
	"database/sql"
	"net/http"

	"reserva-backend/dto"
	"reserva-backend/security"

	"github.com/gin-gonic/gin"
)

type UserHandler struct {
	q *dto.Queries
}

func NewUserHandler(q *dto.Queries) *UserHandler {
	return &UserHandler{q}
}

type registerRequest struct {
	Name     string `json:"name" binding:"required"`
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
	Role     string `json:"role"`
}

type updateRequest struct {
	ID       int32  `json:"id" binding:"required"`
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Role     string `json:"role"`
}

type deleteRequest struct {
	ID int32 `json:"id" binding:"required"`
}

/* =========================
   HANDLERS
========================= */

func (h *UserHandler) Register(c *gin.Context) {

	var req registerRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	hash, err := security.HashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error al encriptar password"})
		return
	}

	err = h.q.CreateUser(context.Background(), dto.CreateUserParams{
		Name:     req.Name,
		Email:    req.Email,
		Password: hash,
		Role:     sql.NullString{String: req.Role, Valid: req.Role != ""},
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error creando usuario"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "usuario creado"})
}

func (h *UserHandler) GetUsers(c *gin.Context) {

	users, err := h.q.GetUsers(context.Background())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo usuarios"})
		return
	}

	c.JSON(http.StatusOK, users)
}

func (h *UserHandler) GetUserByEmail(c *gin.Context) {

	email := c.Param("email")

	user, err := h.q.GetUserByEmail(context.Background(), email)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "usuario no encontrado"})
		return
	}

	c.JSON(http.StatusOK, user)
}

func (h *UserHandler) UpdateUser(c *gin.Context) {

	var req updateRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	hash, err := security.HashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error al encriptar password"})
		return
	}

	err = h.q.UpdateUser(context.Background(), dto.UpdateUserParams{
		ID:       req.ID,
		Name:     req.Name,
		Email:    req.Email,
		Password: hash,
		Role:     sql.NullString{String: req.Role, Valid: req.Role != ""},
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error actualizando usuario"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "usuario actualizado"})
}

func (h *UserHandler) DeleteUser(c *gin.Context) {

	var req deleteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	err := h.q.DeleteUser(context.Background(), req.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error eliminando usuario"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "usuario eliminado"})
}
