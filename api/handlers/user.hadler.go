package handlers

import (
	"database/sql"
	"errors"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	"reserva-backend/repository"
	"reserva-backend/security"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UserHandler struct {
	repository *repository.UsuarioRepository
}

func NewUserHandler(
	repository *repository.UsuarioRepository,
) *UserHandler {
	return &UserHandler{
		repository: repository,
	}
}

/* =========================
   REQUESTS
========================= */

type registerRequest struct {
	Name     string `json:"name" binding:"required"`
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
	Role     string `json:"role"`
	Image    string `json:"image"`
	Cedula   string `json:"cedula"`
}

type updateRequest struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Role     string `json:"role"`
	Estado   int8   `json:"estado"`
	Image    string `json:"image"`
	Cedula   string `json:"cedula"`
}

/* =========================
   HANDLERS
========================= */

// Register godoc
// @Summary Crear usuario
// @Description Registra un nuevo usuario en el sistema
// @Tags usuarios
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param datos body registerRequest true "Datos del usuario"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Router /users [post]
func (h *UserHandler) Register(c *gin.Context) {
	var req registerRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "datos inválidos",
		})
		return
	}

	hash, err := security.HashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "error al encriptar password",
		})
		return
	}

	_, err = h.repository.Crear(
		c.Request.Context(),
		req.Name,
		req.Email,
		hash,
		req.Role,
		req.Image,
		req.Cedula,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "usuario creado",
	})
}

// GetUsers godoc
// @Summary Obtener usuarios
// @Description Obtiene la lista de usuarios registrados
// @Tags usuarios
// @Produce json
// @Security BearerAuth
// @Success 200 {array} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /users [get]
func (h *UserHandler) GetUsers(c *gin.Context) {

	users, err := h.repository.Listar(
		c.Request.Context(),
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "error obteniendo usuarios",
		})
		return
	}

	c.JSON(http.StatusOK, users)
}

// GetUserByEmail godoc
// @Summary Obtener usuario por correo
// @Description Obtiene un usuario activo utilizando su correo electrónico
// @Tags usuarios
// @Produce json
// @Security BearerAuth
// @Param email path string true "Correo electrónico del usuario"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /users/{email} [get]
func (h *UserHandler) GetUserByEmail(c *gin.Context) {

	email := c.Param("email")

	user, err := h.repository.ObtenerPorEmail(
		c.Request.Context(),
		email,
	)

	if err != nil {

		if errors.Is(err, sql.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "usuario no encontrado o inactivo",
			})
			return
		}

		c.JSON(http.StatusNotFound, gin.H{
			"error": "usuario no encontrado o inactivo",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":         user.ID,
		"name":       user.Name,
		"role":       user.Role,
		"email":      user.Email,
		"password":   "",
		"image":      user.Image,
		"cedula":     user.Cedula,
		"created_at": user.CreatedAt,
		"updated_at": user.UpdatedAt,
		"estado":     user.Estado,
	})
}

// UpdateUser godoc
// @Summary Actualizar usuario
// @Description Actualiza la información de un usuario existente
// @Tags usuarios
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del usuario"
// @Param datos body updateRequest true "Datos actualizados del usuario"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /users/{id} [put]
func (h *UserHandler) UpdateUser(c *gin.Context) {

	idStr := c.Param("id")

	id, err := strconv.Atoi(idStr)
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "id inválido",
		})
		return
	}

	var req updateRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	var passwordHash *string
	var estado *int8

	if req.Password != "" {

		hash, err := security.HashPassword(req.Password)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "error al encriptar password",
			})
			return
		}

		passwordHash = &hash

		// El backend original solo actualizaba estado
		// cuando se utilizaba UpdateUserWithPassword.
		estado = &req.Estado
	}

	_, err = h.repository.Actualizar(
		c.Request.Context(),
		int32(id),
		req.Name,
		req.Email,
		req.Role,
		req.Image,
		req.Cedula,
		passwordHash,
		estado,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "usuario actualizado",
	})
}

// ToggleUserStatus godoc
// @Summary Activar o desactivar usuario
// @Description Alterna el estado del usuario entre activo e inactivo
// @Tags usuarios
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del usuario"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /users/{id} [delete]
func (h *UserHandler) ToggleUserStatus(c *gin.Context) {

	idStr := c.Param("id")

	id, err := strconv.Atoi(idStr)

	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "id inválido",
		})
		return
	}

	_, err = h.repository.ToggleEstado(
		c.Request.Context(),
		int32(id),
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "estado del usuario alternado",
	})
}

// UploadUserImg godoc
// @Summary Subir imagen de usuario
// @Description Sube una imagen para utilizarla en el perfil de un usuario
// @Tags usuarios
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param file formData file true "Imagen del usuario"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /users/upload [post]
func (h *UserHandler) UploadUserImg(c *gin.Context) {
	fileHeader, err := c.FormFile("file0")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "archivo no encontrado"})
		return
	}

	file, err := fileHeader.Open()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "error abriendo archivo"})
		return
	}
	defer file.Close()

	upDir := "utils/images/users"
	if _, err := os.Stat(upDir); os.IsNotExist(err) {
		if err := os.MkdirAll(upDir, os.ModePerm); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "error creando directorio"})
			return
		}
	}

	filename := uuid.New().String() + "_" + filepath.Base(fileHeader.Filename)
	dst, err := os.Create(filepath.Join(upDir, filename))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error creando archivo"})
		return
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error guardando archivo"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"filename": filename,
		"message":  "imagen cargada exitosamente",
	})
}

// DownloadUserImg godoc
// @Summary Obtener imagen de usuario
// @Description Descarga o muestra una imagen de usuario almacenada en el servidor
// @Tags usuarios
// @Produce application/octet-stream
// @Security BearerAuth
// @Param filename path string true "Nombre del archivo"
// @Success 200 {file} binary
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /users/download/{filename} [get]
func (h *UserHandler) DownloadUserImg(c *gin.Context) {
	filename := c.Param("filename")
	if filename == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "filename requerido"})
		return
	}

	fileUrl := "utils/images/users/" + filename
	c.File(fileUrl)
}
