package handlers

import (
	"database/sql"
	"net/http"
	"time"

	"reserva-backend/models"
	"reserva-backend/repository"
	"reserva-backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
)

type TarifaHandler struct {
	repository *repository.TarifaRepository
}

func NewTarifaHandler(
	repository *repository.TarifaRepository,
) *TarifaHandler {
	return &TarifaHandler{
		repository: repository,
	}
}

type createTarifaRequest struct {
	IdTipoHabitacion int32           `json:"idTipoHabitacion" binding:"required"`
	PrecioBase       decimal.Decimal `json:"precioBase" binding:"required"`
	NombreTarifa     string          `json:"nombreTarifa" binding:"required"`
	FechaInicio      *string         `json:"fechaInicio"`
	FechaFin         *string         `json:"fechaFin"`
	Descripcion      *string         `json:"descripcion"`
	Estado           int8            `json:"estado"`
}

type UpdateTarifaRequest struct {
	IdTipoHabitacion *int32           `json:"idTipoHabitacion"`
	PrecioBase       *decimal.Decimal `json:"precioBase"`
	NombreTarifa     *string          `json:"nombreTarifa"`
	FechaInicio      *string          `json:"fechaInicio"`
	FechaFin         *string          `json:"fechaFin"`
	Descripcion      *string          `json:"descripcion"`
}

// formato de respuesta que quiero que tenga el JSON
type tarifaResponse struct {
	Idtarifa          int32           `json:"idtarifa"`
	Nombretarifa      string          `json:"nombretarifa"`
	Tipohabitacion    string          `json:"tipohabitacion"`
	Preciobase        decimal.Decimal `json:"preciobase"`
	Fechainicio       *string         `json:"fechainicio"`
	Fechafin          *string         `json:"fechafin"`
	Descripcion       *string         `json:"descripcion"`
	Estado            string          `json:"estado"`
	Desactivadamanual int8            `json:"desactivadaManual"`
}

// convertir la estructura que me devuelve la db a el nuevo formato
func newTarifaResponse(t models.Tarifa) tarifaResponse {
	return tarifaResponse{
		Idtarifa:          t.IDTarifa,
		Nombretarifa:      t.NombreTarifa,
		Tipohabitacion:    t.TipoHabitacion,
		Preciobase:        t.PrecioBase,
		Fechainicio:       utils.FormatNullDate(t.FechaInicio),
		Fechafin:          utils.FormatNullDate(t.FechaFin),
		Descripcion:       utils.ParseNullPtrString(t.Descripcion),
		Estado:            utils.FormatEstado(t.Estado),
		Desactivadamanual: t.DesactivadaManual,
	}
}

func newTarifaByNombreResponse(t models.Tarifa) tarifaResponse {
	return tarifaResponse{
		Idtarifa:       t.IDTarifa,
		Nombretarifa:   t.NombreTarifa,
		Tipohabitacion: t.TipoHabitacion,
		Preciobase:     t.PrecioBase,
		Fechainicio:    utils.FormatNullDate(t.FechaInicio),
		Fechafin:       utils.FormatNullDate(t.FechaFin),
		Estado:         utils.FormatEstado(t.Estado),
	}
}

func nullTimeToPtr(value sql.NullTime) *time.Time {
	if !value.Valid {
		return nil
	}

	return &value.Time
}

// CreateTarifa godoc
// @Summary Crear tarifa
// @Description Registra una nueva tarifa para un tipo de habitación
// @Tags tarifas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param tarifa body createTarifaRequest true "Datos de la tarifa"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tarifas [post]
func (t *TarifaHandler) CreateTarifa(ctx *gin.Context) {

	var req createTarifaRequest

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechaInicio, err := utils.ParseNullDate(req.FechaInicio)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechaFin, err := utils.ParseNullDate(req.FechaFin)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	resultado, err := t.repository.Crear(
		ctx.Request.Context(),
		req.IdTipoHabitacion,
		req.PrecioBase,
		req.NombreTarifa,
		nullTimeToPtr(fechaInicio),
		nullTimeToPtr(fechaFin),
		req.Descripcion,
		req.Estado,
	)

	if err != nil {
		responderErrorSQLServer(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"message":      "Tarifa creada correctamente",
		"generated_id": resultado.IDTarifa,
	})
}

// GetTarifas godoc
// @Summary Obtener todas las tarifas
// @Description Devuelve la lista completa de tarifas
// @Tags tarifas
// @Produce json
// @Security BearerAuth
// @Success 200 {array} tarifaResponse
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tarifas [get]
func (t *TarifaHandler) GetTarifas(ctx *gin.Context) {

	tarifas, err := t.repository.Listar(
		ctx.Request.Context(),
	)

	if err != nil {
		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	response := make([]tarifaResponse, 0)

	for _, tarifa := range tarifas {
		response = append(
			response,
			newTarifaResponse(tarifa),
		)
	}

	ctx.JSON(http.StatusOK, response)
}

// GetTarifaByNombre godoc
// @Summary Obtener tarifa por nombre
// @Description Busca una tarifa por su nombre
// @Tags tarifas
// @Produce json
// @Security BearerAuth
// @Param nombreTarifa path string true "Nombre de la tarifa"
// @Success 200 {object} tarifaResponse
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tarifas/nombre/{nombreTarifa} [get]
func (t *TarifaHandler) GetTarifaByNombre(ctx *gin.Context) {

	nombre := ctx.Param("nombreTarifa")

	tarifa, err := t.repository.ObtenerPorNombre(
		ctx.Request.Context(),
		nombre,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(
				http.StatusNotFound,
				errorResponse(err),
			)
			return
		}

		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	response := newTarifaByNombreResponse(tarifa)

	ctx.JSON(http.StatusOK, response)
}

// UpdateTarifa godoc
// @Summary Actualizar tarifa
// @Description Actualiza los datos de una tarifa existente
// @Tags tarifas
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param idTarifa path int true "ID de la tarifa"
// @Param tarifa body UpdateTarifaRequest true "Datos a actualizar"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tarifas/{idTarifa} [patch]
func (t *TarifaHandler) UpdateTarifa(ctx *gin.Context) {

	var req UpdateTarifaRequest

	id := ctx.Param("idTarifa")

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	if req.NombreTarifa == nil &&
		req.PrecioBase == nil &&
		req.FechaInicio == nil &&
		req.Descripcion == nil &&
		req.FechaFin == nil {

		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Debe enviar al menos un campo para actualizar",
		})
		return
	}

	fechaInicio, err := utils.ParseNullDate(req.FechaInicio)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechaFin, err := utils.ParseNullDate(req.FechaFin)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	idTarifa, err := utils.ParseInt(id)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	resultado, err := t.repository.Actualizar(
		ctx.Request.Context(),
		idTarifa,
		req.IdTipoHabitacion,
		req.PrecioBase,
		req.NombreTarifa,
		nullTimeToPtr(fechaInicio),
		nullTimeToPtr(fechaFin),
		req.Descripcion,
	)

	if err != nil {
		responderErrorSQLServer(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"filas afectadas": resultado.FilasAfectadas,
	})
}

// ActivarTarifa godoc
// @Summary Activar tarifa
// @Description Activa una tarifa si se encuentra dentro de su periodo de vigencia
// @Tags tarifas
// @Produce json
// @Security BearerAuth
// @Param idTarifa path int true "ID de la tarifa"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /tarifas/{idTarifa}/activar [patch]
func (t *TarifaHandler) ActivarTarifa(ctx *gin.Context) {

	id := ctx.Param("idTarifa")

	idTarifa, err := utils.ParseInt(id)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	_, err = t.repository.Activar(
		ctx.Request.Context(),
		idTarifa,
	)

	if err != nil {
		responderErrorSQLServer(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"message": "Tarifa activada correctamente",
	})
}

// DesactivarTarifa godoc
// @Summary Desactivar tarifa
// @Description Desactiva manualmente una tarifa
// @Tags tarifas
// @Produce json
// @Security BearerAuth
// @Param idTarifa path int true "ID de la tarifa"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /tarifas/{idTarifa}/desactivar [patch]
func (t *TarifaHandler) DesactivarTarifa(ctx *gin.Context) {

	id := ctx.Param("idTarifa")

	idTarifa, err := utils.ParseInt(id)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	_, err = t.repository.Desactivar(
		ctx.Request.Context(),
		idTarifa,
	)

	if err != nil {
		responderErrorSQLServer(ctx, err)
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"message":         "Tarifa desactivada correctamente",
		"filas afectadas": 1,
	})
}

// GetEstadisticasTarifa godoc
// @Summary Obtener estadísticas de una tarifa
// @Description Obtiene la cantidad de reservas que utilizaron la tarifa y la última vez que fue utilizada
// @Tags tarifas
// @Produce json
// @Security BearerAuth
// @Param idTarifa path int true "ID de la tarifa"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tarifas/{idTarifa}/estadisticas [get]
func (t *TarifaHandler) GetEstadisticasTarifa(ctx *gin.Context) {

	id := ctx.Param("idTarifa")

	idTarifa, err := utils.ParseInt(id)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	stats, err := t.repository.ObtenerEstadisticas(
		ctx.Request.Context(),
		idTarifa,
	)

	if err != nil {
		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	var ultimaVezUtilizada interface{} = nil

	if stats.UltimaVezUtilizada.Valid {
		ultimaVezUtilizada =
			utils.FormatDateTime(
				stats.UltimaVezUtilizada.Time,
			)
	}

	ctx.JSON(http.StatusOK, gin.H{
		"totalReservas":      stats.TotalReservas,
		"ultimaVezUtilizada": ultimaVezUtilizada,
	})
}
