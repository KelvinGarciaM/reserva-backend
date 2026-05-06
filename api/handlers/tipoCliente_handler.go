package handlers

import (
	"database/sql"
	"errors"
	"net/http"
	"strconv"

	"reserva-backend/dto"

	"github.com/gin-gonic/gin"
)

type TipoClienteHandler struct {
	q *dto.Queries
}

func NewTipoClienteHandler(q *dto.Queries) *TipoClienteHandler {
	return &TipoClienteHandler{q}
}

/* =========================
   REQUESTS
========================= */

type createTipoClienteRequest struct {
	NombreTipoC   string `json:"nombreTipoC" binding:"required"`
	Descripcion   string `json:"descripcion"`
	DescuentoBase string `json:"descuentoBase"`
}

type updateTipoClienteRequest struct {
	IdTipoCliente int32  `json:"idTipoCliente" binding:"required"`
	NombreTipoC   string `json:"nombreTipoC" binding:"required"`
	Descripcion   string `json:"descripcion"`
	DescuentoBase string `json:"descuentoBase"`
	Estado        int8   `json:"estado"`
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
func (h *TipoClienteHandler) CreateTipoCliente(c *gin.Context) {
	var req createTipoClienteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.CreateTipoCliente(c.Request.Context(), dto.CreateTipoClienteParams{
		Nombretipoc:   req.NombreTipoC,
		Descripcion:   req.Descripcion,
		Descuentobase: req.DescuentoBase,
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error creando tipoCliente"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se creó el tipoCliente"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Tipo Cliente creado!"})
}

// GET ALL
func (h *TipoClienteHandler) GetTipoClientes(c *gin.Context) {
	tipos, err := h.q.GetTipoClientes(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo tipos"})
		return
	}

	c.JSON(http.StatusOK, tipos)
}

// GET BY ID
func (h *TipoClienteHandler) GetTipoClienteById(c *gin.Context) {
	idParam := c.Param("id")

	id, err := strconv.Atoi(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}

	tipo, err := h.q.GetTipoClienteById(c.Request.Context(), int32(id))
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "tipoCliente no encontrado"})
			return
		}

		c.JSON(http.StatusInternalServerError, gin.H{"error": "error buscando tipoCliente"})
		return
	}

	c.JSON(http.StatusOK, tipo)
}

func (h *TipoClienteHandler) SearchTipoClientes(c *gin.Context) {
	query := c.Query("q")

	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "parámetro q requerido"})
		return
	}

	tipos, err := h.q.SearchTipoClientes(
		c.Request.Context(),
		dto.SearchTipoClientesParams{
			CONCAT:   query,
			CONCAT_2: query,
			CONCAT_3: query,
		},
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error buscando tipoCliente"})
		return
	}

	c.JSON(http.StatusOK, tipos)
}

// UPDATE
func (h *TipoClienteHandler) UpdateTipoCliente(c *gin.Context) {
	var req updateTipoClienteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.UpdateTipoCliente(c.Request.Context(), dto.UpdateTipoClienteParams{
		Nombretipoc:   req.NombreTipoC,
		Descripcion:   req.Descripcion,
		Descuentobase: req.DescuentoBase,
		Estado:        req.Estado,
		Idtipocliente: req.IdTipoCliente,
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error actualizando tipoCliente"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "tipoCliente no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Tipo Cliente actualizado!"})
}

/* =========================
   DELETE / TOGGLE
========================= */

// DELETE
func (h *TipoClienteHandler) DeleteTipoCliente(c *gin.Context) {
	var req deleteTipoClienteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.DeleteTipoCliente(c.Request.Context(), req.IdTipoCliente)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error eliminando tipoCliente"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "tipoCliente no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Tipo Cliente eliminado!"})
}

func (h *TipoClienteHandler) ToggleTipoClienteEstado(c *gin.Context) {
	var req tipoClienteIdRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.ToggleTipoClienteEstado(c.Request.Context(), req.IdTipoCliente)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error cambiando estado"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "tipoCliente no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "estado actualizado"})
}
