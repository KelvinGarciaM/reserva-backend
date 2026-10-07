package handlers

import (
	"database/sql"
	"errors"
	"net/http"
	"strconv"
	"time"

	"reserva-backend/repository"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
)

type ReservaHandler struct {
	repository *repository.ReservaRepository
}

func NewReservaHandler(
	repository *repository.ReservaRepository,
) *ReservaHandler {
	return &ReservaHandler{
		repository: repository,
	}
}

/* =========================
   REQUESTS
========================= */

type registerReservaRequest struct {
	IdRecepcionista string          `json:"idRecepcionista" binding:"required"`
	IdCliente       string          `json:"idCliente" binding:"required"`
	FechaReserva    string          `json:"fechaReserva" binding:"required"`
	EstadoReserva   string          `json:"estadoReserva" binding:"required"`
	Iva             decimal.Decimal `json:"iva"`
	SubTotal        decimal.Decimal `json:"subTotal"`
	Total           decimal.Decimal `json:"total"`
}

type updateReservaRequest struct {
	IdRecepcionista string          `json:"idRecepcionista" binding:"required"`
	IdCliente       string          `json:"idCliente" binding:"required"`
	FechaReserva    string          `json:"fechaReserva" binding:"required"`
	EstadoReserva   string          `json:"estadoReserva" binding:"required"`
	Estado          int8            `json:"estado"`
	Iva             decimal.Decimal `json:"iva"`
	SubTotal        decimal.Decimal `json:"subTotal"`
	Total           decimal.Decimal `json:"total"`
}

type updateEstadoReservaRequest struct {
	EstadoReserva string `json:"estadoReserva" binding:"required"`
}

/* =========================
   HELPERS
========================= */

func getID(c *gin.Context) (int32, bool) {
	idParam := c.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return 0, false
	}
	return int32(id), true
}

/* =========================
   HANDLERS
========================= */

// Register godoc
// @Summary Crear reserva
// @Description Registra una nueva reserva
// @Tags reservas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param datos body registerReservaRequest true "Datos de la reserva"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /reservas [post]
func (h *ReservaHandler) Register(c *gin.Context) {
	var req registerReservaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	fechaReserva, err := time.Parse(
		time.RFC3339,
		req.FechaReserva,
	)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "formato de fecha inválido (usa ISO 8601)",
		})
		return
	}

	resultado, err := h.repository.Crear(
		c.Request.Context(),
		req.IdRecepcionista,
		req.IdCliente,
		fechaReserva,
		req.EstadoReserva,
		req.Iva,
		req.SubTotal,
		req.Total,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "reserva creada",
		"id":      resultado.IDReserva,
	})
}

// GetReservas godoc
// @Summary Obtener reservas
// @Description Obtiene todas las reservas activas
// @Tags reservas
// @Produce json
// @Security BearerAuth
// @Success 200 {array} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /reservas [get]
func (h *ReservaHandler) GetReservas(c *gin.Context) {

	reservas, err := h.repository.Listar(
		c.Request.Context(),
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, reservas)
}

// GetReservaById godoc
// @Summary Obtener reserva por ID
// @Description Obtiene una reserva activa utilizando su ID
// @Tags reservas
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID de la reserva"
// @Success 200 {array} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /reservas/{id} [get]
func (h *ReservaHandler) GetReservaById(c *gin.Context) {

	id, ok := getID(c)
	if !ok {
		return
	}

	reserva, err := h.repository.ObtenerPorID(
		c.Request.Context(),
		id,
	)

	if err != nil {

		if errors.Is(err, sql.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "no encontrada",
			})
			return
		}

		c.JSON(http.StatusNotFound, gin.H{
			"error": "no encontrada",
		})
		return
	}

	c.JSON(http.StatusOK, reserva)
}

// GetReservasByCliente godoc
// @Summary Obtener reservas por cliente
// @Description Obtiene las reservas activas asociadas a un cliente
// @Tags reservas
// @Produce json
// @Security BearerAuth
// @Param id path string true "Cédula del cliente"
// @Success 200 {array} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /reservas/cliente/{id} [get]
func (h *ReservaHandler) GetReservasByCliente(c *gin.Context) {

	idCliente := c.Param("id")

	reservas, err := h.repository.ListarPorCliente(
		c.Request.Context(),
		idCliente,
	)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "sin reservas",
		})
		return
	}

	c.JSON(http.StatusOK, reservas)
}

// GetReservasByRecepcionista godoc
// @Summary Obtener reservas por recepcionista
// @Description Obtiene las reservas activas asociadas a un recepcionista
// @Tags reservas
// @Produce json
// @Security BearerAuth
// @Param id path string true "Cédula del recepcionista"
// @Success 200 {array} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /reservas/recepcionista/{id} [get]
func (h *ReservaHandler) GetReservasByRecepcionista(c *gin.Context) {

	idRecepcionista := c.Param("id")

	reservas, err := h.repository.ListarPorRecepcionista(
		c.Request.Context(),
		idRecepcionista,
	)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "sin reservas",
		})
		return
	}

	c.JSON(http.StatusOK, reservas)
}

// UpdateReserva godoc
// @Summary Actualizar reserva
// @Description Actualiza la información de una reserva existente
// @Tags reservas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID de la reserva"
// @Param datos body updateReservaRequest true "Datos actualizados de la reserva"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /reservas/{id} [put]
func (h *ReservaHandler) UpdateReserva(c *gin.Context) {

	id, ok := getID(c)
	if !ok {
		return
	}

	var req updateReservaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	fechaReserva, err := time.Parse(
		time.RFC3339,
		req.FechaReserva,
	)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "formato inválido",
		})
		return
	}

	_, err = h.repository.Actualizar(
		c.Request.Context(),
		id,
		req.IdRecepcionista,
		req.IdCliente,
		fechaReserva,
		req.EstadoReserva,
		req.Estado,
		req.Iva,
		req.SubTotal,
		req.Total,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "actualizada",
	})
}

// ToggleReserva godoc
// @Summary Activar o desactivar reserva
// @Description Alterna el estado lógico de una reserva entre activo e inactivo
// @Tags reservas
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID de la reserva"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /reservas/{id} [delete]
func (h *ReservaHandler) ToggleReserva(c *gin.Context) {

	id, ok := getID(c)
	if !ok {
		return
	}

	_, err := h.repository.ToggleEstado(
		c.Request.Context(),
		id,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "estado actualizado",
	})
}

// UpdateEstadoReserva godoc
// @Summary Actualizar estado de reserva
// @Description Modifica el estado descriptivo de una reserva
// @Tags reservas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID de la reserva"
// @Param datos body updateEstadoReservaRequest true "Nuevo estado de la reserva"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /reservas/{id}/estado [patch]
func (h *ReservaHandler) UpdateEstadoReserva(c *gin.Context) {

	id, ok := getID(c)
	if !ok {
		return
	}

	var req updateEstadoReservaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	_, err := h.repository.ActualizarEstadoReserva(
		c.Request.Context(),
		id,
		req.EstadoReserva,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "estado actualizado",
	})
}
