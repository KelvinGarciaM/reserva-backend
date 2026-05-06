package handlers

import (
	"database/sql"
	"net/http"
	"reserva-backend/dto"
	"strconv"

	"errors"

	"github.com/gin-gonic/gin"
	"github.com/go-sql-driver/mysql"
)

type ClienteHandler struct {
	q *dto.Queries
}

func NewClienteHandler(q *dto.Queries) *ClienteHandler {
	return &ClienteHandler{q}
}

/*
	=========================
	  REQUESTS

=========================
*/
type registerClienteRequest struct {
	Cedula        int32  `json:"cedula" binding:"required"`
	IdTipoCliente int32  `json:"idTipoCliente" binding:"required"`
	Nombre        string `json:"nombre" binding:"required"`
	Apellidos     string `json:"apellidos" binding:"required"`
	Telefono      string `json:"telefono" binding:"required"`
	Direccion     string `json:"direccion" binding:"required"`
}

type updateClienteRequest struct {
	Cedula        int32  `json:"cedula" binding:"required"`
	IdTipoCliente int32  `json:"idTipoCliente" binding:"required"`
	Nombre        string `json:"nombre" binding:"required"`
	Apellidos     string `json:"apellidos" binding:"required"`
	Telefono      string `json:"telefono" binding:"required"`
	Direccion     string `json:"direccion" binding:"required"`
	Estado        int8   `json:"estado" binding:"required"`
}

type clienteCedulaRequest struct {
	Cedula int32 `json:"cedula" binding:"required"`
}

type deleteClienteRequest struct {
	Cedula int32 `json:"cedula" binding:"required"`
}

/* =========================
   HANDLERS
========================= */

// CREATE
func (h *ClienteHandler) RegisterCliente(c *gin.Context) {
	var req registerClienteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"Error": " Datos invalidos!"})
		return
	}
	result, err := h.q.CreateCliente(c.Request.Context(), dto.CreateClienteParams{
		Cedula:        req.Cedula,
		Idtipocliente: req.IdTipoCliente,
		Nombre:        req.Nombre,
		Apellidos:     req.Apellidos,
		Telefono:      req.Telefono,
		Direccion:     req.Direccion,
	})
	/* =========================
	   CREATE
	========================= */
	if err != nil {
		var mysqlErr *mysql.MySQLError

		if errors.As(err, &mysqlErr) && mysqlErr.Number == 1062 {
			c.JSON(http.StatusBadRequest, gin.H{"Error": " La cedula ya esta registrada"})
			return
		}

		if errors.As(err, &mysqlErr) && mysqlErr.Number == 1452 {
			c.JSON(http.StatusBadRequest, gin.H{"Error": " El tipo de cliente no existe"})
			return
		}

		c.JSON(http.StatusInternalServerError, gin.H{"Error": " Error creando cliente"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusInternalServerError, gin.H{"Error": " No se pudo crear el cliente"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"Message": "Cliente creado!"})

}

/* =========================
   GET
========================= */

// LISTAR TODOS (activos e inactivos)
func (h *ClienteHandler) GetClientes(c *gin.Context) {
	clientes, err := h.q.GetClientes(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo clientes"})
		return
	}

	c.JSON(http.StatusOK, clientes)
}

// BUSCAR POR CÉDULA
func (h *ClienteHandler) GetClienteByCedula(c *gin.Context) {
	cedulaParam := c.Param("cedula")

	cedula, err := strconv.Atoi(cedulaParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "cédula inválida"})
		return
	}

	cliente, err := h.q.GetClienteByCedula(c.Request.Context(), int32(cedula))
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "cliente no existe"})
			return
		}

		c.JSON(http.StatusInternalServerError, gin.H{"error": "error buscando cliente"})
		return
	}

	c.JSON(http.StatusOK, cliente)
}

// BUSCAR POR TIPO CLIENTE
func (h *ClienteHandler) GetClientesByTipoCliente(c *gin.Context) {
	idParam := c.Param("idtipocliente")

	idTipoCliente, err := strconv.Atoi(idParam)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "idTipoCliente inválido"})
		return
	}

	clientes, err := h.q.GetClientesByTipoCliente(c.Request.Context(), int32(idTipoCliente))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error obteniendo clientes"})
		return
	}

	c.JSON(http.StatusOK, clientes)
}

// BUSCAR POR (nombre, apellidos, etc)
func (h *ClienteHandler) SearchClientes(c *gin.Context) {
	query := c.Query("q")

	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "parámetro q requerido"})
		return
	}

	clientes, err := h.q.SearchClientes(
		c.Request.Context(),
		dto.SearchClientesParams{
			CONCAT:   query,
			CONCAT_2: query,
			CONCAT_3: query,
			CONCAT_4: query,
			CONCAT_5: query,
		},
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error buscando clientes"})
		return
	}

	c.JSON(http.StatusOK, clientes)
}

/* =========================
   UPDATE
========================= */

func (h *ClienteHandler) UpdateCliente(c *gin.Context) {
	var req updateClienteRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.UpdateCliente(c.Request.Context(), dto.UpdateClienteParams{
		Idtipocliente: req.IdTipoCliente,
		Nombre:        req.Nombre,
		Apellidos:     req.Apellidos,
		Telefono:      req.Telefono,
		Direccion:     req.Direccion,
		Estado:        req.Estado,
		Cedula:        req.Cedula,
	})

	if err != nil {
		var mysqlErr *mysql.MySQLError

		if errors.As(err, &mysqlErr) && mysqlErr.Number == 1452 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "el tipo de cliente no existe"})
			return
		}

		c.JSON(http.StatusInternalServerError, gin.H{"error": "error actualizando cliente"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "cliente no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "cliente actualizado"})
}

/* =========================
   DELETE / TOGGLE
========================= */

// DESACTIVAR
func (h *ClienteHandler) DeleteCliente(c *gin.Context) {
	var req clienteCedulaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.DeleteCliente(c.Request.Context(), req.Cedula)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error desactivando cliente"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "cliente no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "cliente desactivado"})
}

// ACTIVAR / DESACTIVAR
func (h *ClienteHandler) ToggleClienteEstado(c *gin.Context) {
	var req clienteCedulaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "datos inválidos"})
		return
	}

	result, err := h.q.ToggleClienteEstado(c.Request.Context(), req.Cedula)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error cambiando estado"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "cliente no existe"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "estado actualizado"})
}
