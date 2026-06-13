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
func (h *HabitacionHandler) GetHabitaciones(c *gin.Context) {
	habitaciones, err := h.q.GetHabitaciones(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"habitaciones": habitaciones})
}

// Get By ID
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
func (h *HabitacionHandler) UpdateHabitacion(c *gin.Context) {
	id, ok := getIDHabitacion(c)
	if !ok {
		return
	}

	var req updateHabitacionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := h.q.GetHabitacionById(c, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Habitación no encontrada",
			"id":    id,
		})
		return
	}

	args := dto.UpdateHabitacionParams{
		Idtipohab:        req.IdTipoHab,
		Numerohabitacion: req.NumeroHabitacion,
		Estado:           req.Estado,
		Idhabitacion:     id,
	}

	_, err = h.q.UpdateHabitacion(c, args)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Habitación actualizada exitosamente",
	})
}

// DELETE LOGICO
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
