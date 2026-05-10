package handlers

import (
	"net/http"
	"reserva-backend/dto"
	"strconv"

	"github.com/gin-gonic/gin"
)

type TipoHabitacionHandler struct {
	q *dto.Queries
}

func NewTipoHabitacionHandler(q *dto.Queries) *TipoHabitacionHandler {
	return &TipoHabitacionHandler{q}
}

//REQUESTS

type registerTipoHabitacionRequest struct {
	NombreTipoHab string `json:"nombreTipoHab" binding:"required"`
	Descripcion   string `json:"descripcion" binding:"required"`
	CapacidadMax  int32  `json:"capacidadMax" binding:"required"`
}

type updateTipoHabitacionRequest struct {
	NombreTipoHab string `json:"nombreTipoHab" binding:"required"`
	Descripcion   string `json:"descripcion" binding:"required"`
	CapacidadMax  int32  `json:"capacidadMax" binding:"required"`
	Estado        int8   `json:"estado"`
}

// HELPERS
func getIDHab(c *gin.Context) (int32, bool) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return 0, false
	}
	return int32(id), true
}

// Handler
// Create
// RegisterTipoHabitacion godoc
// @Summary Crear tipo de habitación
// @Description Registra un nuevo tipo de habitación en el sistema
// @Tags tipos-habitacion
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param tipoHabitacion body registerTipoHabitacionRequest true "Datos del tipo de habitación"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-habitacion [post]
func (h *TipoHabitacionHandler) RegisterTipoHabitacion(c *gin.Context) {
	var req registerTipoHabitacionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	args := dto.CreateTipoHabitacionParams{
		Nombretipohab:   req.NombreTipoHab,
		Descripcion:     req.Descripcion,
		Capacidadmaxima: req.CapacidadMax,
	}
	result, err := h.q.CreateTipoHabitacion(c, args)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	id, _ := result.LastInsertId()
	c.JSON(http.StatusOK, gin.H{
		"message": "Tipo de habitación registrado exitosamente",
		"id":      id,
	})
}

// GET ALL
// GetTipoHabitacion godoc
// @Summary Obtener todos los tipos de habitación
// @Description Devuelve la lista completa de tipos de habitación
// @Tags tipos-habitacion
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-habitacion [get]
func (h *TipoHabitacionHandler) GetTipoHabitacion(c *gin.Context) {
	tipoHabitacion, err := h.q.GetTipoHabitaciones(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"tipoHabitacion": tipoHabitacion})
}

// GET BY ID
// GetTipoHabitacionByID godoc
// @Summary Obtener tipo de habitación por ID
// @Description Busca un tipo de habitación por su ID
// @Tags tipos-habitacion
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del tipo de habitación"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-habitacion/{id} [get]
func (h *TipoHabitacionHandler) GetTipoHabitacionByID(c *gin.Context) {
	id, ok := getIDHab(c)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	tipoHabitacion, err := h.q.GetTipoHabitacionById(c, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tipo de habitación no encontrado"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"tipoHabitacion": tipoHabitacion})
}

// UPDATE
// UpdateTipoHabitacion godoc
// @Summary Actualizar tipo de habitación
// @Description Actualiza los datos de un tipo de habitación existente
// @Tags tipos-habitacion
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del tipo de habitación"
// @Param tipoHabitacion body updateTipoHabitacionRequest true "Datos a actualizar"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-habitacion/{id} [put]
func (h *TipoHabitacionHandler) UpdateTipoHabitacion(c *gin.Context) {
	id, ok := getIDHab(c)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	var req updateTipoHabitacionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	args := dto.UpdateTipoHabitacionParams{
		Nombretipohab:    req.NombreTipoHab,
		Descripcion:      req.Descripcion,
		Capacidadmaxima:  req.CapacidadMax,
		Estado:           req.Estado,
		Idtipohabitacion: id,
	}
	result, err := h.q.UpdateTipoHabitacion(c, args)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tipo de habitación no encontrado",
			"id":      id,
			"details": "verifique si el ID existe o si fue eliminada",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Tipo de habitación actualizado exitosamente"})
}

// DELETE LOGICO
// DeleteTipoHabitacion godoc
// @Summary Eliminar tipo de habitación (soft delete)
// @Description Cambia el estado del tipo de habitación en vez de borrarlo físicamente
// @Tags tipos-habitacion
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del tipo de habitación"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-habitacion/{id} [delete]
func (h *TipoHabitacionHandler) DeleteTipoHabitacion(c *gin.Context) {
	id, ok := getIDHab(c)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	result, err := h.q.DeleteTipoHabitacion(c, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tipo de habitación no encontrado",
			"id":      id,
			"details": "verifique si el ID existe",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Tipo de habitación eliminado exitosamente"})
}
