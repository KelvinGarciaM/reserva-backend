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
		case 50003, 50013, 50016,
			50103, 50111, 50114, 50116,
			50203, 50211, 50212, 50214,
			50309, 50312, 50410, 50415,
			50507, 50510, 50608, 50611,
			50703, 50706:
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

// RegisterTipoHabitacion godoc
// @Summary Crear tipo de habitación
// @Description Registra un nuevo tipo de habitación
// @Tags tipos-habitacion
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param datos body registerTipoHabitacionRequest true "Datos del tipo de habitación"
// @Success 201 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Router /tipos-habitacion [post]
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

// GetTipoHabitacion godoc
// @Summary Obtener tipos de habitación
// @Description Obtiene todos los tipos de habitación y permite filtrar por estado
// @Tags tipos-habitacion
// @Produce json
// @Security BearerAuth
// @Param estado query int false "Estado: 0 inactivo, 1 activo"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Router /tipos-habitacion [get]
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

// GetTipoHabitacionByID godoc
// @Summary Obtener tipo de habitación por ID
// @Description Obtiene la información de un tipo de habitación específico
// @Tags tipos-habitacion
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del tipo de habitación"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /tipos-habitacion/{id} [get]
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

// UpdateTipoHabitacion godoc
// @Summary Actualizar tipo de habitación
// @Description Actualiza los datos de un tipo de habitación existente
// @Tags tipos-habitacion
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del tipo de habitación"
// @Param datos body updateTipoHabitacionRequest true "Datos actualizados del tipo de habitación"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /tipos-habitacion/{id} [put]
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

// DeleteTipoHabitacion godoc
// @Summary Desactivar tipo de habitación
// @Description Realiza la eliminación lógica de un tipo de habitación cambiando su estado
// @Tags tipos-habitacion
// @Produce json
// @Security BearerAuth
// @Param id path int true "ID del tipo de habitación"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /tipos-habitacion/{id} [delete]
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
