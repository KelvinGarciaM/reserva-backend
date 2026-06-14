package handlers

import (
	"net/http"
	"reserva-backend/dto"
	"strconv"

	"github.com/gin-gonic/gin"
)

type HabitacionHandler struct {
	q *dto.Queries
}

func NewHabitacionHandler(q *dto.Queries) *HabitacionHandler {
	return &HabitacionHandler{q: q}
}

//REQUESTS

type registerHabitacionRequest struct {
	IdTipoHab        int32  `json:"idTipoHab" binding:"required"`
	NumeroHabitacion string `json:"numeroHabitacion" binding:"required"`
}

type updateHabitacionRequest struct {
	IdTipoHab        int32  `json:"idTipoHab" binding:"required"`
	NumeroHabitacion string `json:"numeroHabitacion" binding:"required"`
	Estado           int8   `json:"estado"`
}

// HELPERS
func getIDHabitacion(c *gin.Context) (int32, bool) {
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
// RegisterHabitacion godoc
// @Summary Crear habitación
// @Description Registra una nueva habitación en el sistema
// @Tags habitaciones
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param habitacion body registerHabitacionRequest true "Datos de la habitación"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /habitaciones [post]
func (h *HabitacionHandler) RegisterHabitacion(c *gin.Context) {
	var req registerHabitacionRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := h.q.GetHabitacionByNumero(c, req.NumeroHabitacion)

	if err == nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Ya existe una habitación con ese número",
		})
		return
	}

	args := dto.CreateHabitacionParams{
		Idtipohab:        req.IdTipoHab,
		Numerohabitacion: req.NumeroHabitacion,
	}

	result, err := h.q.CreateHabitacion(c, args)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	id, _ := result.LastInsertId()

	c.JSON(http.StatusOK, gin.H{
		"message": "Habitación creada exitosamente",
		"id":      id,
	})
}

// Get All
// GetHabitaciones godoc
// @Summary Obtener todas las habitaciones
// @Description Devuelve la lista completa de habitaciones
// @Tags habitaciones
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /habitaciones [get]
func (h *HabitacionHandler) GetHabitaciones(c *gin.Context) {
	habitaciones, err := h.q.GetHabitaciones(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"habitaciones": habitaciones})
}

// Get By ID
// GetHabitacionByID godoc
// @Summary Obtener habitación por ID
// @Description Busca una habitación por su ID
// @Tags habitaciones
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID de la habitación"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /habitaciones/{id} [get]
func (h *HabitacionHandler) GetHabitacionByID(c *gin.Context) {
	id, ok := getIDHabitacion(c)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	habitacion, err := h.q.GetHabitacionById(c, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Habitacion no encontrada"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"habitacion": habitacion})
}

// Get By Tipo Hab
// GetHabitacionesByTipoHab godoc
// @Summary Obtener habitaciones por tipo
// @Description Busca habitaciones por ID de tipo de habitación
// @Tags habitaciones
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del tipo de habitación"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /habitaciones/tipo/{id} [get]
func (h *HabitacionHandler) GetHabitacionesByTipoHab(c *gin.Context) {
	idP, ok := getIDHabitacion(c)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	habitaciones, err := h.q.GetHabitacionesByTipo(c, idP)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Habitaciones no encontradas"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"habitaciones": habitaciones})
}

// Update
// UpdateHabitacion godoc
// @Summary Actualizar habitación
// @Description Actualiza los datos de una habitación existente
// @Tags habitaciones
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID de la habitación"
// @Param habitacion body updateHabitacionRequest true "Datos a actualizar"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /habitaciones/{id} [put]
func (h *HabitacionHandler) UpdateHabitacion(c *gin.Context) {
	id, ok := getIDHabitacion(c)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	var req updateHabitacionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	args := dto.UpdateHabitacionParams{
		Idtipohab:        req.IdTipoHab,
		Numerohabitacion: req.NumeroHabitacion,
		Estado:           req.Estado,
		Idhabitacion:     id,
	}
	result, err := h.q.UpdateHabitacion(c, args)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "Habitación no encontrada",
			"id":      id,
			"details": "verifique si el ID existe o si fue eliminada",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Habitación actualizada exitosamente"})
}

// DELETE LOGICO
// DeleteHabitacion godoc
// @Summary Eliminar habitación (soft delete)
// @Description Cambia el estado de la habitación en vez de borrarla físicamente
// @Tags habitaciones
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID de la habitación"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /habitaciones/{id} [delete]
func (h *HabitacionHandler) DeleteHabitacion(c *gin.Context) {
	id, ok := getIDHabitacion(c)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}
	result, err := h.q.DeleteHabitacion(c, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "Habitación no encontrada",
			"id":      id,
			"details": "verifique si el ID existe o si fue eliminada",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Habitación eliminada exitosamente"})
}

func (h *HabitacionHandler) GetHabitacionesDisponibles(c *gin.Context) {
	habitaciones, err := h.q.GetHabitacionesDisponibles(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"habitaciones": habitaciones})
}
