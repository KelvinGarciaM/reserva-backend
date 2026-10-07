package handlers

import (
	"net/http"
	"strconv"

	"reserva-backend/repository"

	"github.com/gin-gonic/gin"
)

type HabitacionHandler struct {
	repository *repository.HabitacionRepository
}

func NewHabitacionHandler(
	repository *repository.HabitacionRepository,
) *HabitacionHandler {
	return &HabitacionHandler{
		repository: repository,
	}
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
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	resultado, err := h.repository.Crear(
		c.Request.Context(),
		req.IdTipoHab,
		req.NumeroHabitacion,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Habitación creada exitosamente",
		"id":      resultado.IDHabitacion,
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

	habitaciones, err := h.repository.Listar(
		c.Request.Context(),
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	response := make([]gin.H, 0)

	for _, hab := range habitaciones {
		response = append(response, gin.H{
			"idhabitacion":     hab.IDHabitacion,
			"idtipohab":        hab.IDTipoHab,
			"nombretipohab":    hab.NombreTipoHab,
			"numerohabitacion": hab.NumeroHabitacion,
			"estado":           hab.Estado,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"habitaciones": response,
	})
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
		return
	}

	habitacion, err := h.repository.ObtenerPorID(
		c.Request.Context(),
		id,
	)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"message": "Habitacion no encontrada",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"habitacion": gin.H{
			"idhabitacion":     habitacion.IDHabitacion,
			"idtipohab":        habitacion.IDTipoHab,
			"numerohabitacion": habitacion.NumeroHabitacion,
			"estado":           habitacion.Estado,
		},
	})
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

	id, ok := getIDHabitacion(c)
	if !ok {
		return
	}

	habitaciones, err := h.repository.ListarPorTipo(
		c.Request.Context(),
		id,
	)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"message": "Habitaciones no encontradas",
		})
		return
	}

	response := make([]gin.H, 0)

	for _, hab := range habitaciones {
		response = append(response, gin.H{
			"idhabitacion":     hab.IDHabitacion,
			"idtipohab":        hab.IDTipoHab,
			"numerohabitacion": hab.NumeroHabitacion,
			"estado":           hab.Estado,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"habitaciones": response,
	})
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
		return
	}

	var req updateHabitacionRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	if req.Estado != 0 && req.Estado != 1 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "el estado debe ser 0 o 1",
		})
		return
	}

	_, err := h.repository.Actualizar(
		c.Request.Context(),
		id,
		req.IdTipoHab,
		req.NumeroHabitacion,
		req.Estado,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Habitación actualizada exitosamente",
	})
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
		return
	}

	_, err := h.repository.Eliminar(
		c.Request.Context(),
		id,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Habitación eliminada exitosamente",
	})
}

// GetHabitacionesDisponibles godoc
// @Summary Obtener habitaciones disponibles
// @Description Obtiene habitaciones activas con tipo y tarifa activos y con tarifa vigente actualmente
// @Tags habitaciones
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /habitaciones/disponibles [get]
func (h *HabitacionHandler) GetHabitacionesDisponibles(c *gin.Context) {

	habitaciones, err := h.repository.ListarDisponibles(
		c.Request.Context(),
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	response := make([]gin.H, 0)

	for _, hab := range habitaciones {
		response = append(response, gin.H{
			"idhabitacion":     hab.IDHabitacion,
			"numerohabitacion": hab.NumeroHabitacion,
			"nombretipohab":    hab.NombreTipoHab,
			"idtarifa":         hab.IDTarifa,
			"nombretarifa":     hab.NombreTarifa,
			"preciobase":       hab.PrecioBase,
			"capacidadmaxima":  hab.CapacidadMaxima,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"habitaciones": response,
	})
}
