package handlers

import (
	"net/http"
	"strconv"

	"reserva-backend/repository"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
)

type TipoClienteHandler struct {
	repository *repository.TipoClienteRepository
}

func NewTipoClienteHandler(
	repository *repository.TipoClienteRepository,
) *TipoClienteHandler {
	return &TipoClienteHandler{
		repository: repository,
	}
}

/* =========================
   REQUESTS
========================= */

type createTipoClienteRequest struct {
	NombreTipoC   string          `json:"nombreTipoC" binding:"required"`
	Descripcion   string          `json:"descripcion"`
	DescuentoBase decimal.Decimal `json:"descuentoBase"`
}

type updateTipoClienteRequest struct {
	IdTipoCliente int32           `json:"idTipoCliente" binding:"required"`
	NombreTipoC   string          `json:"nombreTipoC" binding:"required"`
	Descripcion   string          `json:"descripcion"`
	DescuentoBase decimal.Decimal `json:"descuentoBase"`
	Estado        int8            `json:"estado"`
}

type deleteTipoClienteRequest struct {
	IdTipoCliente int32 `json:"idTipoCliente" binding:"required"`
}

type tipoClienteIdRequest struct {
	IdTipoCliente int32 `json:"idTipoCliente" binding:"required"`
}

/* =========================
   HANDLERS
========================= */

// CREATE
// CreateTipoCliente godoc
// @Summary Crear tipo de cliente
// @Description Registra un nuevo tipo de cliente en el sistema
// @Tags tipos-cliente
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param tipoCliente body createTipoClienteRequest true "Datos del tipo de cliente"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-cliente [post]
func (h *TipoClienteHandler) CreateTipoCliente(c *gin.Context) {
	var req createTipoClienteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "datos inválidos",
		})
		return
	}

	resultado, err := h.repository.Crear(
		c.Request.Context(),
		req.NombreTipoC,
		req.Descripcion,
		req.DescuentoBase.InexactFloat64(),
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": resultado.Mensaje,
	})
}

// GET ALL
// GetTipoClientes godoc
// @Summary Obtener todos los tipos de cliente
// @Description Devuelve la lista completa de tipos de cliente
// @Tags tipos-cliente
// @Produce json
// @Security BearerAuth
// @Success 200 {array} object
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-cliente [get]
func (h *TipoClienteHandler) GetTipoClientes(c *gin.Context) {

	tipos, err := h.repository.Listar(
		c.Request.Context(),
		nil,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	response := make([]gin.H, 0)

	for _, t := range tipos {
		response = append(response, gin.H{
			"idTipoCliente": t.IDTipoCliente,
			"nombreTipoC":   t.NombreTipoC,
			"descripcion":   t.Descripcion,
			"descuentoBase": t.DescuentoBase,
			"estado":        t.Estado,
		})
	}

	c.JSON(http.StatusOK, response)
}

// GET BY ID
// GetTipoClienteById godoc
// @Summary Obtener tipo de cliente por ID
// @Description Busca un tipo de cliente por su ID
// @Tags tipos-cliente
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del tipo de cliente"
// @Success 200 {object} object
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-cliente/{id} [get]
func (h *TipoClienteHandler) GetTipoClienteById(c *gin.Context) {

	idParam := c.Param("id")

	id, err := strconv.Atoi(idParam)

	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "id inválido",
		})
		return
	}

	tipo, err := h.repository.ObtenerPorID(
		c.Request.Context(),
		int32(id),
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"idTipoCliente": tipo.IDTipoCliente,
		"nombreTipoC":   tipo.NombreTipoC,
		"descripcion":   tipo.Descripcion,
		"descuentoBase": tipo.DescuentoBase,
		"estado":        tipo.Estado,
	})
}

// SearchTipoClientes godoc
// @Summary Buscar tipos de cliente
// @Description Busca tipos de cliente por nombre, descripción o descuento
// @Tags tipos-cliente
// @Produce json
// @Security BearerAuth
// @Param q query string true "Término de búsqueda"
// @Success 200 {array} object
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-cliente/buscar [get]
func (h *TipoClienteHandler) SearchTipoClientes(c *gin.Context) {

	query := c.Query("q")

	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "parámetro q requerido",
		})
		return
	}

	tipos, err := h.repository.Buscar(
		c.Request.Context(),
		query,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	response := make([]gin.H, 0)

	for _, t := range tipos {
		response = append(response, gin.H{
			"idtipocliente": t.IDTipoCliente,
			"nombretipoc":   t.NombreTipoC,
			"descripcion":   t.Descripcion,
			"descuentobase": t.DescuentoBase,
			"estado":        t.Estado,
		})
	}

	c.JSON(http.StatusOK, response)
}

// UPDATE
// UpdateTipoCliente godoc
// @Summary Actualizar tipo de cliente
// @Description Actualiza los datos de un tipo de cliente existente
// @Tags tipos-cliente
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param tipoCliente body updateTipoClienteRequest true "Datos a actualizar"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-cliente [put]
func (h *TipoClienteHandler) UpdateTipoCliente(c *gin.Context) {

	var req updateTipoClienteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "datos inválidos",
		})
		return
	}

	if req.Estado != 0 && req.Estado != 1 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "el estado debe ser 0 o 1",
		})
		return
	}

	resultado, err := h.repository.Actualizar(
		c.Request.Context(),
		req.IdTipoCliente,
		req.NombreTipoC,
		req.Descripcion,
		req.DescuentoBase.InexactFloat64(),
		req.Estado,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": resultado.Mensaje,
	})
}

/* =========================
   DELETE / TOGGLE
========================= */

// DELETE
// DeleteTipoCliente godoc
// @Summary Eliminar tipo de cliente
// @Description Elimina un tipo de cliente del sistema (soft delete)
// @Tags tipos-cliente
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param tipoCliente body deleteTipoClienteRequest true "ID del tipo de cliente"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-cliente [delete]
func (h *TipoClienteHandler) DeleteTipoCliente(c *gin.Context) {

	var req deleteTipoClienteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "datos inválidos",
		})
		return
	}

	resultado, err := h.repository.Eliminar(
		c.Request.Context(),
		req.IdTipoCliente,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": resultado.Mensaje,
	})
}

// ToggleTipoClienteEstado godoc
// @Summary Activar/Desactivar tipo de cliente
// @Description Cambia el estado de un tipo de cliente (activo/inactivo)
// @Tags tipos-cliente
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param tipoCliente body tipoClienteIdRequest true "ID del tipo de cliente"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tipos-cliente/toggle [put]
func (h *TipoClienteHandler) ToggleTipoClienteEstado(c *gin.Context) {

	var req tipoClienteIdRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "datos inválidos",
		})
		return
	}

	_, err := h.repository.ToggleEstado(
		c.Request.Context(),
		req.IdTipoCliente,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Estado actualizado",
	})
}
