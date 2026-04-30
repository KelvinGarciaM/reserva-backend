package handlers

import (
	"net/http"
	"reserva-backend/dto"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
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
	IdRecepcionista int32  `json:"idRecepcionista" binding:"required"`
	IdCliente       int32  `json:"idCliente" binding:"required"`
	FechaReserva    string `json:"fechaReserva" binding:"required"`
	FechaEntrada    string `json:"fechaEntrada" binding:"required"`
	FechaSalida     string `json:"fechaSalida" binding:"required"`
	CantidadNoches  int32  `json:"cantidadNoches" binding:"required"`
	EstadoReserva   string `json:"estadoReserva" binding:"required"`
}

type updateReservaRequest struct {
	IdRecepcionista int32  `json:"idRecepcionista" binding:"required"`
	IdCliente       int32  `json:"idCliente" binding:"required"`
	FechaReserva    string `json:"fechaReserva" binding:"required"`
	FechaEntrada    string `json:"fechaEntrada" binding:"required"`
	FechaSalida     string `json:"fechaSalida" binding:"required"`
	CantidadNoches  int32  `json:"cantidadNoches" binding:"required"`
	EstadoReserva   string `json:"estadoReserva" binding:"required"`
	Estado          int8   `json:"estado"`
}

/* =========================
   HELPERS
========================= */

func parseFechas(req registerReservaRequest) (time.Time, time.Time, time.Time, error) {
	layout := time.RFC3339

	fechaReserva, err := time.Parse(layout, req.FechaReserva)
	if err != nil {
		return time.Time{}, time.Time{}, time.Time{}, err
	}

	fechaEntrada, err := time.Parse(layout, req.FechaEntrada)
	if err != nil {
		return time.Time{}, time.Time{}, time.Time{}, err
	}

	fechaSalida, err := time.Parse(layout, req.FechaSalida)
	if err != nil {
		return time.Time{}, time.Time{}, time.Time{}, err
	}

	return fechaReserva, fechaEntrada, fechaSalida, nil
}

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

// CREATE
func (h *ReservaHandler) Register(c *gin.Context) {
	var req registerReservaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fr, fe, fs, err := parseFechas(req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "formato de fecha inválido (usa ISO 8601)"})
		return
	}

	if !fs.After(fe) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "fechaSalida debe ser mayor a fechaEntrada"})
		return
	}

	args := dto.CreateReservaParams{
		Idrecepcionista: req.IdRecepcionista,
		Idcliente:       req.IdCliente,
		Fechareserva:    fr,
		Fechaentrada:    fe,
		Fechasalida:     fs,
		Cantidadnoches:  req.CantidadNoches,
		Estadoreserva:   req.EstadoReserva,
	}

	result, err := h.q.CreateReserva(c, args)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	id, _ := result.LastInsertId()

	c.JSON(http.StatusOK, gin.H{
		"message": "reserva creada",
		"id":      id,
	})
}

// GET ALL
func (h *ReservaHandler) GetReservas(c *gin.Context) {
	reservas, err := h.q.GetReservas(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, reservas)
}

// GET BY ID
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

// GET BY CLIENTE
func (h *ReservaHandler) GetReservasByCliente(c *gin.Context) {
	id, ok := getID(c)
	if !ok {
		return
	}

	reservas, err := h.q.GetReservasByCliente(c, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "sin reservas"})
		return
	}

	c.JSON(http.StatusOK, reservas)
}

// GET BY RECEPCIONISTA
func (h *ReservaHandler) GetReservasByRecepcionista(c *gin.Context) {
	id, ok := getID(c)
	if !ok {
		return
	}

	reservas, err := h.q.GetReservasByRecepcionista(c, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "sin reservas"})
		return
	}

	c.JSON(http.StatusOK, reservas)
}

// UPDATE
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

	fr, fe, fs, err := parseFechas(registerReservaRequest{
		IdRecepcionista: req.IdRecepcionista,
		IdCliente:       req.IdCliente,
		FechaReserva:    req.FechaReserva,
		FechaEntrada:    req.FechaEntrada,
		FechaSalida:     req.FechaSalida,
		CantidadNoches:  req.CantidadNoches,
		EstadoReserva:   req.EstadoReserva,
	})
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "formato inválido"})
		return
	}

	if !fs.After(fe) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "fechaSalida debe ser mayor a fechaEntrada"})
		return
	}

	args := dto.UpdateReservaParams{
		Idrecepcionista: req.IdRecepcionista,
		Idcliente:       req.IdCliente,
		Fechareserva:    fr,
		Fechaentrada:    fe,
		Fechasalida:     fs,
		Cantidadnoches:  req.CantidadNoches,
		Estadoreserva:   req.EstadoReserva,
		Estado:          req.Estado,
		Idreserva:       id,
	}

	result, err := h.q.UpdateReserva(c, args)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "reserva no encontrada",
			"id":      id,
			"details": "verifica si el ID existe o si fue eliminada",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "actualizada"})
}

// DELETE LOGICO
func (h *ReservaHandler) DeleteReserva(c *gin.Context) {
	id, ok := getID(c)
	if !ok {
		return
	}

	result, err := h.q.DeleteReserva(c, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "eliminada (lógico)"})
}
