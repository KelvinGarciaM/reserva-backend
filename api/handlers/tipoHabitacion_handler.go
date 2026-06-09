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
func (h *TipoHabitacionHandler) RegisterTipoHabitacion(c *gin.Context) {

	var req registerTipoHabitacionRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := h.q.GetTipoHabitacionByNombre(
		c,
		req.NombreTipoHab,
	)

	if err == nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Ya existe un tipo de habitación con ese nombre",
		})
		return
	}

	args := dto.CreateTipoHabitacionParams{
		Nombretipohab:   req.NombreTipoHab,
		Descripcion:     req.Descripcion,
		Capacidadmaxima: req.CapacidadMax,
	}

	result, err := h.q.CreateTipoHabitacion(c, args)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	id, _ := result.LastInsertId()

	c.JSON(http.StatusOK, gin.H{
		"message": "Tipo de habitación registrado exitosamente",
		"id":      id,
	})
}

// GET ALL
func (h *TipoHabitacionHandler) GetTipoHabitacion(c *gin.Context) {
	tipoHabitacion, err := h.q.GetTipoHabitaciones(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"tipoHabitacion": tipoHabitacion})
}

// GET BY ID
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
