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
	IdRecepcionista string `json:"idRecepcionista" binding:"required"`
	IdCliente       string `json:"idCliente" binding:"required"`
	FechaReserva    string `json:"fechaReserva" binding:"required"`
	CantidadNoches  int32  `json:"cantidadNoches" binding:"required"`
	EstadoReserva   string `json:"estadoReserva" binding:"required"`
}

type updateReservaRequest struct {
	IdRecepcionista string `json:"idRecepcionista" binding:"required"`
	IdCliente       string `json:"idCliente" binding:"required"`
	FechaReserva    string `json:"fechaReserva" binding:"required"`
	CantidadNoches  int32  `json:"cantidadNoches" binding:"required"`
	EstadoReserva   string `json:"estadoReserva" binding:"required"`
	Estado          int8   `json:"estado"`
}

/* =========================
   HELPERS
========================= */

func parseFechas(req registerReservaRequest) (time.Time, error) {
	layout := time.RFC3339

	fechaReserva, err := time.Parse(layout, req.FechaReserva)
	if err != nil {
		return time.Time{}, err
	}

	return fechaReserva, nil
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
// Register godoc
// @Summary Crear reserva
// @Description Registra una nueva reserva en el sistema
// @Tags reservas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param reserva body registerReservaRequest true "Datos de la reserva"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /reservas [post]
func (h *ReservaHandler) Register(c *gin.Context) {
	var req registerReservaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	fr, err := parseFechas(req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "formato de fecha inválido (usa ISO 8601)"})
		return
	}

	args := dto.CreateReservaParams{
		Idrecepcionista: req.IdRecepcionista,
		Idcliente:       req.IdCliente,
		Fechareserva:    fr,

		Estadoreserva: req.EstadoReserva,
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
// GetReservas godoc
// @Summary Obtener todas las reservas
// @Description Devuelve la lista completa de reservas
// @Tags reservas
// @Produce json
// @Security BearerAuth
// @Success 200 {array} object
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /reservas [get]
func (h *ReservaHandler) GetReservas(c *gin.Context) {
	reservas, err := h.q.GetReservas(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, reservas)
}

// GET BY ID
// GetReservaById godoc
// @Summary Obtener reserva por ID
// @Description Busca una reserva por su ID
// @Tags reservas
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID de la reserva"
// @Success 200 {object} object
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /reservas/{id} [get]
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
// GetReservasByCliente godoc
// @Summary Obtener reservas por cliente
// @Description Busca reservas por ID de cliente
// @Tags reservas
// @Produce json
// @Security BearerAuth
// @Param id path string true "ID del cliente"
// @Success 200 {array} object
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /reservas/cliente/{id} [get]
func (h *ReservaHandler) GetReservasByCliente(c *gin.Context) {

	idCliente := c.Param("id")

	reservas, err := h.q.GetReservasByCliente(c, idCliente)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "sin reservas",
		})
		return
	}

	c.JSON(http.StatusOK, reservas)
}

// GET BY RECEPCIONISTA
// GetReservasByRecepcionista godoc
// @Summary Obtener reservas por recepcionista
// @Description Busca reservas por ID de recepcionista
// @Tags reservas
// @Produce json
// @Security BearerAuth
// @Param id path string true "ID del recepcionista"
// @Success 200 {array} object
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /reservas/recepcionista/{id} [get]
func (h *ReservaHandler) GetReservasByRecepcionista(c *gin.Context) {
	idRecepcionista := c.Param("id")

	reservas, err := h.q.GetReservasByRecepcionista(c, idRecepcionista)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "sin reservas"})
		return
	}

	c.JSON(http.StatusOK, reservas)
}

// UPDATE
// UpdateReserva godoc
// @Summary Actualizar reserva
// @Description Actualiza los datos de una reserva existente
// @Tags reservas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID de la reserva"
// @Param reserva body updateReservaRequest true "Datos a actualizar"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /reservas/{id} [put]
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

	fr, err := parseFechas(registerReservaRequest{
		IdRecepcionista: req.IdRecepcionista,
		IdCliente:       req.IdCliente,
		FechaReserva:    req.FechaReserva,
		CantidadNoches:  req.CantidadNoches,
		EstadoReserva:   req.EstadoReserva,
	})
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
// DeleteReserva godoc
// @Summary Eliminar reserva (soft delete)
// @Description Cambia el estado de la reserva en vez de borrarla físicamente
// @Tags reservas
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID de la reserva"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /reservas/{id} [delete]
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
