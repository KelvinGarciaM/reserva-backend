package handlers

import (
	"database/sql"
	"net/http"

	"reserva-backend/dto"
	"reserva-backend/security"

	"errors"

	"github.com/gin-gonic/gin"
	"github.com/go-sql-driver/mysql"
)

type UserHandler struct {
	q *dto.Queries
}

func NewUserHandler(q *dto.Queries) *UserHandler {
	return &UserHandler{q}
}

/* =========================
   REQUESTS
========================= */

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
	Estado   int8   `json:"estado"`
}

type deleteRequest struct {
	ID int32 `json:"id" binding:"required"`
}

/* =========================
   HANDLERS
========================= */

// Register godoc
// @Summary Crear usuario
// @Description Registra un nuevo usuario en el sistema
// @Tags users
// @Accept json
// @Produce json
// @Param user body registerRequest true "Datos del usuario"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /users [post]
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

	err = h.q.CreateUser(c.Request.Context(), dto.CreateUserParams{
		Name:     req.Name,
		Email:    req.Email,
		Password: hash,
		Role:     sql.NullString{String: req.Role, Valid: req.Role != ""},
	})

	if err != nil {

		var mysqlErr *mysql.MySQLError

		if errors.As(err, &mysqlErr) && mysqlErr.Number == 1062 {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "el correo ya está registrado",
			})
			return
		}

		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "error creando usuario",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "usuario creado"})
}

// GetUsers godoc
// @Summary Obtener todos los usuarios
// @Description Devuelve la lista de usuarios activos
// @Tags users
// @Produce json
// @Security BearerAuth
// @Success 200 {array} object
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /users [get]
func (h *UserHandler) GetUsers(c *gin.Context) {
	users, err := h.q.GetUsers(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo usuarios"})
		return
	}

	c.JSON(http.StatusOK, users)
}

// GetUserByEmail godoc
// @Summary Obtener usuario por email
// @Description Busca un usuario por su correo electrónico
// @Tags users
// @Produce json
// @Security BearerAuth
// @Param email path string true "Email del usuario"
// @Success 200 {array} object
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /users/{email} [get]
func (h *UserHandler) GetUserByEmail(c *gin.Context) {
	email := c.Param("email")

	user, err := h.q.GetUserByEmail(c.Request.Context(), email)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "usuario no encontrado o inactivo"})
		return
	}

	user.Password = ""

	c.JSON(http.StatusOK, user)
}

// UpdateUser godoc
// @Summary Actualizar usuario
// @Description Actualiza datos del usuario (con o sin password)
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param user body updateRequest true "Datos a actualizar"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /users [put]
func (h *UserHandler) UpdateUser(c *gin.Context) {
	var req updateRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	var (
		result sql.Result
		err    error
	)

	if req.Password != "" {
		// con password
		hash, errHash := security.HashPassword(req.Password)
		if errHash != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "error al encriptar password"})
			return
		}

		result, err = h.q.UpdateUserWithPassword(c.Request.Context(), dto.UpdateUserWithPasswordParams{
			Name:     req.Name,
			Role:     sql.NullString{String: req.Role, Valid: req.Role != ""},
			Email:    req.Email,
			Password: hash,
			Estado:   req.Estado,
			ID:       req.ID,
		})

	} else {

		result, err = h.q.UpdateUserWithoutPassword(c.Request.Context(), dto.UpdateUserWithoutPasswordParams{
			Name:   req.Name,
			Role:   sql.NullString{String: req.Role, Valid: req.Role != ""},
			Email:  req.Email,
			Estado: req.Estado,
			ID:     req.ID,
		})
	}

	// error DB
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error actualizando usuario"})
		return
	}

	// validar existencia
	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "usuario no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "usuario actualizado"})
}

// DeleteUser godoc
// @Summary Eliminar usuario (soft delete)
// @Description Cambia el estado del usuario en vez de borrarlo físicamente
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param user body deleteRequest true "ID del usuario"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /users [delete]
func (h *UserHandler) DeleteUser(c *gin.Context) {
	var req deleteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.DeleteUser(c.Request.Context(), req.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error actualizando usuario"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "usuario no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "estado del usuario actualizado",
	})
}
