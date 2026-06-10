package handlers

import (
	"database/sql"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	"reserva-backend/dto"
	"reserva-backend/security"

	"errors"

	"github.com/gin-gonic/gin"
	"github.com/go-sql-driver/mysql"
	"github.com/google/uuid"
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
		Image:    sql.NullString{String: req.Image, Valid: req.Image != ""},
		Cedula:   sql.NullString{String: req.Cedula, Valid: req.Cedula != ""},
	})

	if err != nil {
		var mysqlErr *mysql.MySQLError
		if errors.As(err, &mysqlErr) && mysqlErr.Number == 1062 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "el correo ya está registrado"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error creando usuario"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "usuario creado"})
}

func (h *UserHandler) GetUsers(c *gin.Context) {
	users, err := h.q.GetUsers(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo usuarios"})
		return
	}
	c.JSON(http.StatusOK, users)
}

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

func (h *UserHandler) UpdateUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}

	var req updateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var result sql.Result

	if req.Password != "" {
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
			Image:    sql.NullString{String: req.Image, Valid: req.Image != ""},
			Cedula:   sql.NullString{String: req.Cedula, Valid: req.Cedula != ""},
			Estado:   req.Estado,
			ID:       int32(id),
		})
	} else {
		result, err = h.q.UpdateUserWithoutPassword(c.Request.Context(), dto.UpdateUserWithoutPasswordParams{
			Name:   req.Name,
			Role:   sql.NullString{String: req.Role, Valid: req.Role != ""},
			Email:  req.Email,
			Image:  sql.NullString{String: req.Image, Valid: req.Image != ""},
			Cedula: sql.NullString{String: req.Cedula, Valid: req.Cedula != ""},
			ID:     int32(id),
		})
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error actualizando usuario"})
		return
	}

	_ = result
	c.JSON(http.StatusOK, gin.H{"message": "usuario actualizado"})
}

func (h *UserHandler) ToggleUserStatus(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}

	result, err := h.q.ToggleUserStatus(c.Request.Context(), int32(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error alternando estado del usuario"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "usuario no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "estado del usuario alternado"})
}

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

func (h *UserHandler) DownloadUserImg(c *gin.Context) {
	filename := c.Param("filename")
	if filename == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "filename requerido"})
		return
	}

	fileUrl := "utils/images/users/" + filename
	c.File(fileUrl)
}
