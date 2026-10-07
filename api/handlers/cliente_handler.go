package handlers

import (
	"database/sql"
	"errors"
	"net/http"
	"strconv"

	"reserva-backend/repository"

	"github.com/gin-gonic/gin"
)

type ClienteHandler struct {
	repository *repository.ClienteRepository
}

func NewClienteHandler(
	repository *repository.ClienteRepository,
) *ClienteHandler {
	return &ClienteHandler{
		repository: repository,
	}
}

/*
	=========================
	  REQUESTS

=========================
*/
type registerClienteRequest struct {
	Cedula        string `json:"cedula" binding:"required"`
	IdTipoCliente int32  `json:"idTipoCliente" binding:"required"`
	Nombre        string `json:"nombre" binding:"required"`
	Apellidos     string `json:"apellidos" binding:"required"`
	Telefono      string `json:"telefono" binding:"required"`
	Direccion     string `json:"direccion" binding:"required"`
}

type updateClienteRequest struct {
	Cedula        string `json:"cedula" binding:"required"`
	IdTipoCliente int32  `json:"idTipoCliente" binding:"required"`
	Nombre        string `json:"nombre" binding:"required"`
	Apellidos     string `json:"apellidos" binding:"required"`
	Telefono      string `json:"telefono" binding:"required"`
	Direccion     string `json:"direccion" binding:"required"`
	Estado        int8   `json:"estado"`
}

type clienteCedulaRequest struct {
	Cedula string `json:"cedula" binding:"required"`
}

/* =========================
   HANDLERS
========================= */

// CREATE
// RegisterCliente godoc
// @Summary Crear cliente
// @Description Registra un nuevo cliente en el sistema
// @Tags clientes
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param cliente body registerClienteRequest true "Datos del cliente"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /clientes [post]
func (h *ClienteHandler) RegisterCliente(c *gin.Context) {
	var req registerClienteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"Error": " Datos invalidos!",
		})
		return
	}

	resultado, err := h.repository.Crear(
		c.Request.Context(),
		req.Cedula,
		req.IdTipoCliente,
		req.Nombre,
		req.Apellidos,
		req.Telefono,
		req.Direccion,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"Message": "Cliente creado!",
	})

	_ = resultado
}

/* =========================
   GET
========================= */

// LISTAR TODOS (activos e inactivos)
// GetClientes godoc
// @Summary Obtener todos los clientes
// @Description Devuelve la lista completa de clientes (activos e inactivos)
// @Tags clientes
// @Produce json
// @Security BearerAuth
// @Success 200 {array} object
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /clientes [get]
func (h *ClienteHandler) GetClientes(c *gin.Context) {

	clientes, err := h.repository.Listar(
		c.Request.Context(),
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "error obteniendo clientes",
		})
		return
	}

	response := make([]gin.H, 0)

	for _, cli := range clientes {
		response = append(response, gin.H{
			"cedula":        cli.Cedula,
			"idTipoCliente": cli.IDTipoCliente,
			"nombreTipoC":   cli.NombreTipoC,
			"nombre":        cli.Nombre,
			"apellidos":     cli.Apellidos,
			"telefono":      cli.Telefono,
			"direccion":     cli.Direccion,
			"estado":        cli.Estado,
		})
	}

	c.JSON(http.StatusOK, response)
}

// BUSCAR POR CÉDULA
// GetClienteByCedula godoc
// @Summary Obtener cliente por cédula
// @Description Busca un cliente por su número de cédula
// @Tags clientes
// @Produce json
// @Security BearerAuth
// @Param cedula path string true "Cédula del cliente"
// @Success 200 {object} object
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /clientes/{cedula} [get]
func (h *ClienteHandler) GetClienteByCedula(c *gin.Context) {

	cedula := c.Param("cedula")

	cliente, err := h.repository.ObtenerPorCedula(
		c.Request.Context(),
		cedula,
	)

	if err != nil {

		if errors.Is(err, sql.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "cliente no existe",
			})
			return
		}

		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "error buscando cliente",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"cedula":        cliente.Cedula,
		"idTipoCliente": cliente.IDTipoCliente,
		"nombreTipoC":   cliente.NombreTipoC,
		"nombre":        cliente.Nombre,
		"apellidos":     cliente.Apellidos,
		"telefono":      cliente.Telefono,
		"direccion":     cliente.Direccion,
		"estado":        cliente.Estado,
	})
}

// BUSCAR POR TIPO CLIENTE
// GetClientesByTipoCliente godoc
// @Summary Obtener clientes por tipo
// @Description Busca clientes por ID de tipo de cliente
// @Tags clientes
// @Produce json
// @Security BearerAuth
// @Param idtipocliente path int true "ID del tipo de cliente"
// @Success 200 {array} object
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /clientes/tipo/{idtipocliente} [get]
func (h *ClienteHandler) GetClientesByTipoCliente(c *gin.Context) {

	idParam := c.Param("idtipocliente")

	idTipoCliente, err := strconv.Atoi(idParam)

	if err != nil || idTipoCliente <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "idTipoCliente inválido",
		})
		return
	}

	clientes, err := h.repository.ListarPorTipo(
		c.Request.Context(),
		int32(idTipoCliente),
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "error obteniendo clientes",
		})
		return
	}

	response := make([]gin.H, 0)

	for _, cli := range clientes {
		response = append(response, gin.H{
			"cedula":        cli.Cedula,
			"idTipoCliente": cli.IDTipoCliente,
			"nombreTipoC":   cli.NombreTipoC,
			"nombre":        cli.Nombre,
			"apellidos":     cli.Apellidos,
			"telefono":      cli.Telefono,
			"direccion":     cli.Direccion,
			"estado":        cli.Estado,
		})
	}

	c.JSON(http.StatusOK, response)
}

// BUSCAR POR (nombre, apellidos, etc)
// SearchClientes godoc
// @Summary Buscar clientes
// @Description Busca clientes por nombre, apellidos, cédula o teléfono
// @Tags clientes
// @Produce json
// @Security BearerAuth
// @Param q query string true "Término de búsqueda"
// @Success 200 {array} object
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /clientes/buscar [get]
func (h *ClienteHandler) SearchClientes(c *gin.Context) {

	query := c.Query("q")

	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "parámetro q requerido",
		})
		return
	}

	clientes, err := h.repository.Buscar(
		c.Request.Context(),
		query,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "error buscando clientes",
		})
		return
	}

	response := make([]gin.H, 0)

	for _, cli := range clientes {
		response = append(response, gin.H{
			"cedula":        cli.Cedula,
			"idTipoCliente": cli.IDTipoCliente,
			"nombreTipoC":   cli.NombreTipoC,
			"nombre":        cli.Nombre,
			"apellidos":     cli.Apellidos,
			"telefono":      cli.Telefono,
			"direccion":     cli.Direccion,
			"estado":        cli.Estado,
		})
	}

	c.JSON(http.StatusOK, response)
}

/* =========================
   UPDATE
========================= */
// UpdateCliente godoc
// @Summary Actualizar cliente
// @Description Actualiza los datos de un cliente existente
// @Tags clientes
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param cliente body updateClienteRequest true "Datos a actualizar"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /clientes [put]
func (h *ClienteHandler) UpdateCliente(c *gin.Context) {
	var req updateClienteRequest

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

	_, err := h.repository.Actualizar(
		c.Request.Context(),
		req.Cedula,
		req.IdTipoCliente,
		req.Nombre,
		req.Apellidos,
		req.Telefono,
		req.Direccion,
		req.Estado,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "cliente actualizado",
	})
}

/* =========================
   DELETE / TOGGLE
========================= */

// DESACTIVAR
// DeleteCliente godoc
// @Summary Desactivar cliente (soft delete)
// @Description Desactiva un cliente en el sistema
// @Tags clientes
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param cliente body clienteCedulaRequest true "Cédula del cliente"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /clientes [delete]
func (h *ClienteHandler) DeleteCliente(c *gin.Context) {
	var req clienteCedulaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "datos inválidos",
		})
		return
	}

	_, err := h.repository.Eliminar(
		c.Request.Context(),
		req.Cedula,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "cliente desactivado",
	})
}

// ACTIVAR / DESACTIVAR
// ToggleClienteEstado godoc
// @Summary Activar/Desactivar cliente
// @Description Cambia el estado de un cliente (activo/inactivo)
// @Tags clientes
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param cliente body clienteCedulaRequest true "Cédula del cliente"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /clientes/toggle [put]
func (h *ClienteHandler) ToggleClienteEstado(c *gin.Context) {
	var req clienteCedulaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "datos inválidos",
		})
		return
	}

	_, err := h.repository.ToggleEstado(
		c.Request.Context(),
		req.Cedula,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "estado actualizado",
	})
}
