package handlers

import (
	"database/sql"
	"errors"
	"net/http"

	"reserva-backend/dto"

	"github.com/gin-gonic/gin"
)

type RecepcionistaHandler struct {
	q *dto.Queries
}

func NewRecepcionistaHandler(q *dto.Queries) *RecepcionistaHandler {
	return &RecepcionistaHandler{q}
}

/* =========================
   REQUESTS
========================= */

type createRecepcionistaRequest struct {
	Cedula    string `json:"cedula" binding:"required"`
	Nombre    string `json:"nombre" binding:"required"`
	Apellidos string `json:"apellidos" binding:"required"`
	Telefono  string `json:"telefono" binding:"required"`
	Correo    string `json:"correo" binding:"required"`
}

type updateRecepcionistaRequest struct {
	Cedula    string `json:"cedula" binding:"required"`
	Nombre    string `json:"nombre" binding:"required"`
	Apellidos string `json:"apellidos" binding:"required"`
	Telefono  string `json:"telefono" binding:"required"`
	Correo    string `json:"correo" binding:"required"`
	Estado    int8   `json:"estado" binding:"required"`
}

type recepcionistaCedulaRequest struct {
	Cedula string `json:"cedula" binding:"required"`
}

/* =========================
   CREATE
========================= */
// CreateRecepcionista godoc
// @Summary Crear recepcionista
// @Description Registra un nuevo recepcionista en el sistema
// @Tags recepcionistas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recepcionista body createRecepcionistaRequest true "Datos del recepcionista"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas [post]
func (h *RecepcionistaHandler) CreateRecepcionista(c *gin.Context) {
	var req createRecepcionistaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.CreateRecepcionista(c.Request.Context(), dto.CreateRecepcionistaParams{
		Cedula:    req.Cedula,
		Nombre:    req.Nombre,
		Apellidos: req.Apellidos,
		Telefono:  req.Telefono,
		Correo:    req.Correo,
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error creando recepcionista"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se creó el recepcionista"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "recepcionista creado"})
}

/* =========================
   GET
========================= */
// GetRecepcionistas godoc
// @Summary Obtener todos los recepcionistas
// @Description Devuelve la lista completa de recepcionistas
// @Tags recepcionistas
// @Produce json
// @Security BearerAuth
// @Success 200 {array} object
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas [get]
func (h *RecepcionistaHandler) GetRecepcionistas(c *gin.Context) {
	data, err := h.q.GetRecepcionistas(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo recepcionistas"})
		return
	}

	c.JSON(http.StatusOK, data)
}

// GetRecepcionistaByCedula godoc
// @Summary Obtener recepcionista por cédula
// @Description Busca un recepcionista por su número de cédula
// @Tags recepcionistas
// @Produce json
// @Security BearerAuth
// @Param cedula path string true "Cédula del recepcionista"
// @Success 200 {object} object
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas/{cedula} [get]
func (h *RecepcionistaHandler) GetRecepcionistaByCedula(c *gin.Context) {
	cedula := c.Param("cedula")

	data, err := h.q.GetRecepcionistaByCedula(c.Request.Context(), cedula)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "no existe"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error"})
		return
	}

	c.JSON(http.StatusOK, data)
}

// SearchRecepcionistas godoc
// @Summary Buscar recepcionistas
// @Description Busca recepcionistas por nombre, apellidos, cédula o correo
// @Tags recepcionistas
// @Produce json
// @Security BearerAuth
// @Param q query string true "Término de búsqueda"
// @Success 200 {array} object
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas/buscar [get]
func (h *RecepcionistaHandler) SearchRecepcionistas(c *gin.Context) {
	query := c.Query("q")

	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "q requerido"})
		return
	}

	data, err := h.q.SearchRecepcionistas(
		c.Request.Context(),
		dto.SearchRecepcionistasParams{
			CONCAT:   query,
			CONCAT_2: query,
			CONCAT_3: query,
			CONCAT_4: query,
			CONCAT_5: query,
		},
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error buscando"})
		return
	}

	c.JSON(http.StatusOK, data)
}

/* =========================
   UPDATE
========================= */
// UpdateRecepcionista godoc
// @Summary Actualizar recepcionista
// @Description Actualiza los datos de un recepcionista existente
// @Tags recepcionistas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recepcionista body updateRecepcionistaRequest true "Datos a actualizar"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas [put]
func (h *RecepcionistaHandler) UpdateRecepcionista(c *gin.Context) {
	var req updateRecepcionistaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.UpdateRecepcionista(c.Request.Context(), dto.UpdateRecepcionistaParams{
		Nombre:    req.Nombre,
		Apellidos: req.Apellidos,
		Telefono:  req.Telefono,
		Correo:    req.Correo,
		Estado:    req.Estado,
		Cedula:    req.Cedula,
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error actualizando"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "actualizado"})
}

/* =========================
   DELETE / TOGGLE
========================= */
// DeleteRecepcionista godoc
// @Summary Eliminar recepcionista (soft delete)
// @Description Desactiva un recepcionista en el sistema
// @Tags recepcionistas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recepcionista body recepcionistaCedulaRequest true "Cédula del recepcionista"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas [delete]
func (h *RecepcionistaHandler) DeleteRecepcionista(c *gin.Context) {
	var req recepcionistaCedulaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.DeleteRecepcionista(c.Request.Context(), req.Cedula)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "desactivado"})
}

// ToggleRecepcionistaEstado godoc
// @Summary Activar/Desactivar recepcionista
// @Description Cambia el estado de un recepcionista (activo/inactivo)
// @Tags recepcionistas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recepcionista body recepcionistaCedulaRequest true "Cédula del recepcionista"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas/toggle [put]
func (h *RecepcionistaHandler) ToggleRecepcionistaEstado(c *gin.Context) {
	var req recepcionistaCedulaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.ToggleRecepcionistaEstado(c.Request.Context(), req.Cedula)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "estado actualizado"})
}
