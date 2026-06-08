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
	tipos, err := h.q.GetTipoClientes(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo tipos"})
		return
	}
	response := make([]gin.H, 0)

	for _, t := range tipos {
		response = append(response, gin.H{
			"idTipoCliente": t.Idtipocliente,
			"nombreTipoC":   t.Nombretipoc,
			"descripcion":   t.Descripcion,
			"descuentoBase": t.Descuentobase,
			"estado":        t.Estado,
		})
	}

	c.JSON(http.StatusOK, response)

	//c.JSON(http.StatusOK, tipos)
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
	c.JSON(http.StatusOK, gin.H{
		"idTipoCliente": tipo.Idtipocliente,
		"nombreTipoC":   tipo.Nombretipoc,
		"descripcion":   tipo.Descripcion,
		"descuentoBase": tipo.Descuentobase,
		"estado":        tipo.Estado,
	})

	//c.JSON(http.StatusOK, tipo)
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
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.ToggleTipoClienteEstado(c.Request.Context(), req.IdTipoCliente)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error cambiando estado"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "El tipo de cliente no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Estado actualizado"})
}
