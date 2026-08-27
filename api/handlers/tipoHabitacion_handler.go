package handlers

import (
	"errors"
	"net/http"
	"strconv"

	"reserva-backend/repository"

	"github.com/gin-gonic/gin"
	mssql "github.com/microsoft/go-mssqldb"
)

type TipoHabitacionHandler struct {
	repository *repository.TipoHabitacionRepository
}

func NewTipoHabitacionHandler(
	repository *repository.TipoHabitacionRepository,
) *TipoHabitacionHandler {
	return &TipoHabitacionHandler{
		repository: repository,
	}
}

type registerTipoHabitacionRequest struct {
	NombreTipoHab string `json:"nombreTipoHab" binding:"required"`
	Descripcion   string `json:"descripcion" binding:"required"`
	CapacidadMax  int32  `json:"capacidadMax" binding:"required"`
}

type updateTipoHabitacionRequest struct {
	NombreTipoHab string `json:"nombreTipoHab" binding:"required"`
	Descripcion   string `json:"descripcion" binding:"required"`
	CapacidadMax  int32  `json:"capacidadMax" binding:"required"`
	Estado        int8   `json:"estado"`
}

func getIDHab(c *gin.Context) (int32, bool) {
	idParam := c.Param("id")

	id, err := strconv.Atoi(idParam)
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "El ID debe ser un número mayor que cero",
		})
		return 0, false
	}

	return int32(id), true
}

func responderErrorSQLServer(c *gin.Context, err error) {
	var sqlServerError mssql.Error

	if errors.As(err, &sqlServerError) {
		status := http.StatusBadRequest

		switch sqlServerError.Number {
		case 50003, 50013, 50016:
			status = http.StatusNotFound
		}

		c.JSON(status, gin.H{
			"error":  sqlServerError.Message,
			"codigo": sqlServerError.Number,
		})
		return
	}

	c.JSON(http.StatusInternalServerError, gin.H{
		"error": "Ocurrió un error interno al acceder a la base de datos",
	})
}

// RegisterTipoHabitacion crea un tipo de habitación.
func (h *TipoHabitacionHandler) RegisterTipoHabitacion(c *gin.Context) {
	var req registerTipoHabitacionRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Los datos enviados no son válidos",
		})
		return
	}

	resultado, err := h.repository.Crear(
		c.Request.Context(),
		req.NombreTipoHab,
		req.Descripcion,
		req.CapacidadMax,
	)
	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": resultado.Mensaje,
		"id":      resultado.IDTipoHabitacion,
	})
}

// GetTipoHabitacion obtiene los tipos de habitación.
// Puede recibir ?estado=1 o ?estado=0.
// Si no recibe estado, devuelve todos.
func (h *TipoHabitacionHandler) GetTipoHabitacion(c *gin.Context) {
	var filtroEstado *int8

	estadoParam := c.Query("estado")

	if estadoParam != "" {
		estado, err := strconv.Atoi(estadoParam)

		if err != nil || (estado != 0 && estado != 1) {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "El filtro estado debe ser 0 o 1",
			})
			return
		}

		estadoConvertido := int8(estado)
		filtroEstado = &estadoConvertido
	}

	tiposHabitacion, err := h.repository.Listar(
		c.Request.Context(),
		filtroEstado,
	)
	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"tipoHabitacion": tiposHabitacion,
	})
}

// GetTipoHabitacionByID obtiene un tipo de habitación por ID.
func (h *TipoHabitacionHandler) GetTipoHabitacionByID(
	c *gin.Context,
) {
	id, ok := getIDHab(c)
	if !ok {
		return
	}

	tipoHabitacion, err := h.repository.ObtenerPorID(
		c.Request.Context(),
		id,
	)
	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"tipoHabitacion": tipoHabitacion,
	})
}

// UpdateTipoHabitacion actualiza un tipo de habitación.
func (h *TipoHabitacionHandler) UpdateTipoHabitacion(
	c *gin.Context,
) {
	id, ok := getIDHab(c)
	if !ok {
		return
	}

	var req updateTipoHabitacionRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Los datos enviados no son válidos",
		})
		return
	}

	if req.Estado != 0 && req.Estado != 1 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "El estado debe ser 0 o 1",
		})
		return
	}

	resultado, err := h.repository.Actualizar(
		c.Request.Context(),
		id,
		req.NombreTipoHab,
		req.Descripcion,
		req.CapacidadMax,
		req.Estado,
	)
	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":        resultado.Mensaje,
		"id":             resultado.IDTipoHabitacion,
		"filasAfectadas": resultado.FilasAfectadas,
	})
}

// DeleteTipoHabitacion realiza la eliminación lógica.
func (h *TipoHabitacionHandler) DeleteTipoHabitacion(
	c *gin.Context,
) {
	id, ok := getIDHab(c)
	if !ok {
		return
	}

	resultado, err := h.repository.Eliminar(
		c.Request.Context(),
		id,
	)
	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":        resultado.Mensaje,
		"id":             resultado.IDTipoHabitacion,
		"filasAfectadas": resultado.FilasAfectadas,
	})
}
