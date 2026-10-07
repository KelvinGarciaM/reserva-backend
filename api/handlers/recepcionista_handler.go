package handlers

import (
	"net/http"

	"reserva-backend/repository"

	"github.com/gin-gonic/gin"
)

type RecepcionistaHandler struct {
	repository *repository.RecepcionistaRepository
}

func NewRecepcionistaHandler(
	repository *repository.RecepcionistaRepository,
) *RecepcionistaHandler {
	return &RecepcionistaHandler{
		repository: repository,
	}
}

/* =========================
   REQUESTS
========================= */

type createRecepcionistaRequest struct {
	Cedula    string `json:"cedula" binding:"required"`
	Nombre    string `json:"nombre" binding:"required"`
	Apellidos string `json:"apellidos" binding:"required"`
	Telefono  string `json:"telefono" binding:"required"`
	Correo    string `json:"correo" binding:"required"`
}

type updateRecepcionistaRequest struct {
	Cedula    string `json:"cedula" binding:"required"`
	Nombre    string `json:"nombre" binding:"required"`
	Apellidos string `json:"apellidos" binding:"required"`
	Telefono  string `json:"telefono" binding:"required"`
	Correo    string `json:"correo" binding:"required"`
	Estado    int8   `json:"estado"`
}

type recepcionistaCedulaRequest struct {
	Cedula string `json:"cedula" binding:"required"`
}

/* =========================
   CREATE
========================= */
// CreateRecepcionista godoc
// @Summary Crear recepcionista
// @Description Registra un nuevo recepcionista en el sistema
// @Tags recepcionistas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recepcionista body createRecepcionistaRequest true "Datos del recepcionista"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas [post]
func (h *RecepcionistaHandler) CreateRecepcionista(c *gin.Context) {
	var req createRecepcionistaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "datos inválidos",
		})
		return
	}

	resultado, err := h.repository.Crear(
		c.Request.Context(),
		req.Cedula,
		req.Nombre,
		req.Apellidos,
		req.Telefono,
		req.Correo,
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
   GET
========================= */
// GetRecepcionistas godoc
// @Summary Obtener todos los recepcionistas
// @Description Devuelve la lista completa de recepcionistas
// @Tags recepcionistas
// @Produce json
// @Security BearerAuth
// @Success 200 {array} object
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas [get]
func (h *RecepcionistaHandler) GetRecepcionistas(c *gin.Context) {

	recepcionistas, err := h.repository.Listar(
		c.Request.Context(),
		nil,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, recepcionistas)
}

// GetRecepcionistaByCedula godoc
// @Summary Obtener recepcionista por cédula
// @Description Busca un recepcionista por su número de cédula
// @Tags recepcionistas
// @Produce json
// @Security BearerAuth
// @Param cedula path string true "Cédula del recepcionista"
// @Success 200 {object} object
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas/{cedula} [get]
func (h *RecepcionistaHandler) GetRecepcionistaByCedula(c *gin.Context) {

	cedula := c.Param("cedula")

	if cedula == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "cédula requerida",
		})
		return
	}

	recepcionista, err := h.repository.ObtenerPorCedula(
		c.Request.Context(),
		cedula,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, recepcionista)
}

// SearchRecepcionistas godoc
// @Summary Buscar recepcionistas
// @Description Busca recepcionistas por nombre, apellidos, cédula o correo
// @Tags recepcionistas
// @Produce json
// @Security BearerAuth
// @Param q query string true "Término de búsqueda"
// @Success 200 {array} object
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas/buscar [get]
func (h *RecepcionistaHandler) SearchRecepcionistas(c *gin.Context) {

	busqueda := c.Query("q")

	if busqueda == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "parámetro q requerido",
		})
		return
	}

	recepcionistas, err := h.repository.Buscar(
		c.Request.Context(),
		busqueda,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, recepcionistas)
}

/* =========================
   UPDATE
========================= */
// UpdateRecepcionista godoc
// @Summary Actualizar recepcionista
// @Description Actualiza los datos de un recepcionista existente
// @Tags recepcionistas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recepcionista body updateRecepcionistaRequest true "Datos a actualizar"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas [put]
func (h *RecepcionistaHandler) UpdateRecepcionista(c *gin.Context) {
	var req updateRecepcionistaRequest

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
		req.Cedula,
		req.Nombre,
		req.Apellidos,
		req.Telefono,
		req.Correo,
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
// DeleteRecepcionista godoc
// @Summary Eliminar recepcionista (soft delete)
// @Description Desactiva un recepcionista en el sistema
// @Tags recepcionistas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recepcionista body recepcionistaCedulaRequest true "Cédula del recepcionista"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas [delete]
func (h *RecepcionistaHandler) DeleteRecepcionista(c *gin.Context) {
	var req recepcionistaCedulaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "datos inválidos",
		})
		return
	}

	resultado, err := h.repository.Eliminar(
		c.Request.Context(),
		req.Cedula,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": resultado.Mensaje,
	})
}

// ToggleRecepcionistaEstado godoc
// @Summary Activar/Desactivar recepcionista
// @Description Cambia el estado de un recepcionista (activo/inactivo)
// @Tags recepcionistas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param recepcionista body recepcionistaCedulaRequest true "Cédula del recepcionista"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /recepcionistas/toggle [put]
func (h *RecepcionistaHandler) ToggleRecepcionistaEstado(c *gin.Context) {
	var req recepcionistaCedulaRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "datos inválidos",
		})
		return
	}

	resultado, err := h.repository.ToggleEstado(
		c.Request.Context(),
		req.Cedula,
	)

	if err != nil {
		responderErrorSQLServer(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": resultado.Mensaje,
		"estado":  resultado.Estado,
	})
}
