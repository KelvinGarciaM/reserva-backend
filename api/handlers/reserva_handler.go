package handlers

import (
	"net/http"
	"reserva-backend/dto"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
)

type ReservaHandler struct {
	q *dto.Queries
}

func NewReservaHandler(q *dto.Queries) *ReservaHandler {
	return &ReservaHandler{q}
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

func (h *ReservaHandler) Register(c *gin.Context) {
	var req registerReservaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fr, err := time.Parse(time.RFC3339, req.FechaReserva)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "formato de fecha inválido (usa ISO 8601)"})
		return
	}

	args := dto.CreateReservaParams{
		Idrecepcionista: req.IdRecepcionista,
		Idcliente:       req.IdCliente,
		Fechareserva:    fr,
		Estadoreserva:   req.EstadoReserva,
		Iva:             req.Iva,
		Subtotal:        req.SubTotal,
		Total:           req.Total,
	}

	result, err := h.q.CreateReserva(c, args)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	id, _ := result.LastInsertId()
	c.JSON(http.StatusOK, gin.H{"message": "reserva creada", "id": id})
}

func (h *ReservaHandler) GetReservas(c *gin.Context) {
	reservas, err := h.q.GetReservas(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, reservas)
}

func (h *ReservaHandler) GetReservaById(c *gin.Context) {
	id, ok := getID(c)
	if !ok {
		return
	}

	reserva, err := h.q.GetReservaById(c, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "no encontrada"})
		return
	}

	c.JSON(http.StatusOK, reserva)
}

func (h *ReservaHandler) GetReservasByCliente(c *gin.Context) {
	idCliente := c.Param("id")

	reservas, err := h.q.GetReservasByCliente(c, idCliente)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "sin reservas"})
		return
	}

	c.JSON(http.StatusOK, reservas)
}

func (h *ReservaHandler) GetReservasByRecepcionista(c *gin.Context) {
	idRecepcionista := c.Param("id")

	reservas, err := h.q.GetReservasByRecepcionista(c, idRecepcionista)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "sin reservas"})
		return
	}

	c.JSON(http.StatusOK, reservas)
}

func (h *ReservaHandler) UpdateReserva(c *gin.Context) {
	id, ok := getID(c)
	if !ok {
		return
	}

	var req updateReservaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fr, err := time.Parse(time.RFC3339, req.FechaReserva)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "formato inválido"})
		return
	}

	args := dto.UpdateReservaParams{
		Idrecepcionista: req.IdRecepcionista,
		Idcliente:       req.IdCliente,
		Fechareserva:    fr,
		Estadoreserva:   req.EstadoReserva,
		Estado:          req.Estado,
		Iva:             req.Iva,
		Subtotal:        req.SubTotal,
		Total:           req.Total,
		Idreserva:       id,
	}

	result, err := h.q.UpdateReserva(c, args)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "reserva no encontrada"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "actualizada"})
}

func (h *ReservaHandler) ToggleReserva(c *gin.Context) {
	id, ok := getID(c)
	if !ok {
		return
	}

	result, err := h.q.ToggleReserva(c, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "estado actualizado"})
}

func (h *ReservaHandler) UpdateEstadoReserva(c *gin.Context) {
	id, ok := getID(c)
	if !ok {
		return
	}

	var req struct {
		EstadoReserva string `json:"estadoReserva" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.q.UpdateEstadoReserva(c, dto.UpdateEstadoReservaParams{
		Estadoreserva: req.EstadoReserva,
		Idreserva:     id,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	_ = result
	c.JSON(http.StatusOK, gin.H{"message": "estado actualizado"})
}
