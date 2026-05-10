package handlers

//import package apifunc
import (
	"net/http"
	"reserva-backend/dto"
	"reserva-backend/utils"

	"github.com/gin-gonic/gin"
)

type TarifaHandler struct {
	q *dto.Queries
}

func NewTarifaHandler(q *dto.Queries) *TarifaHandler {
	return &TarifaHandler{q}
}

type createTarifaRequest struct {
	IdTipoHabitacion int32   `json:"idTipoHabitacion" binding:"required"`
	PrecioBase       string  `json:"precioBase" binding:"required"`
	NombreTarifa     string  `json:"nombreTarifa" binding:"required"`
	FechaInicio      *string `json:"fechaInicio"`
	FechaFin         *string `json:"fechaFin"`
}

type UpdateTarifaRequest struct {
	IdTipoHabitacion *int32  `json:"idTipoHabitacion"`
	PrecioBase       *string `json:"precioBase"`
	NombreTarifa     *string `json:"nombreTarifa"`
	FechaInicio      *string `json:"fechaInicio"`
	FechaFin         *string `json:"fechaFin"`
}

type deleteTarifaRequest struct {
	idTarifa int32 `json:"idTarifa" binding:"required"`
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
		ctx.JSON(400, errorResponse(err))
		return
	}
	fechaFin, err := utils.ParseNullDate(req.FechaFin)
	if err != nil {
		ctx.JSON(400, errorResponse(err))
		return
	}
	args := dto.CreateTarifaParams{
		Idtipohabitacion: req.IdTipoHabitacion,
		Preciobase:       req.PrecioBase,
		Nombretarifa:     req.NombreTarifa,
		Fechainicio:      fechaInicio,
		Fechafin:         fechaFin,
	}
	tarifa, err := t.q.CreateTarifa(ctx, args)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	var lastId, _ = tarifa.LastInsertId()
	ctx.JSON(http.StatusOK, gin.H{"generated_id": lastId})
}

// formato de respuesta que quiero que tenga el JSON
type tarifaResponse struct {
	Idtarifa       int32   `json:"idtarifa"`
	Nombretarifa   string  `json:"nombretarifa"`
	Tipohabitacion string  `json:"tipohabitacion"`
	Preciobase     string  `json:"preciobase"`
	Fechainicio    *string `json:"fechainicio"`
	Fechafin       *string `json:"fechafin"`
	Estado         string  `json:"estado"`
}

// convertir la estructura que me devuelve la db a el nuevo formato
func newTarifaResponse(t dto.GetTarifasRow) tarifaResponse {
	return tarifaResponse{
		Idtarifa:       t.Idtarifa,
		Nombretarifa:   t.Nombretarifa,
		Tipohabitacion: t.Tipohabitacion,
		Preciobase:     t.Preciobase,
		Fechainicio:    utils.FormatNullDate(t.Fechainicio),
		Fechafin:       utils.FormatNullDate(t.Fechafin),
		Estado:         utils.FormatEstado(t.Estado),
	}
}
func newTarifaByNombreResponse(t dto.GetTarifaByNombreRow) tarifaResponse {
	return tarifaResponse{
		Idtarifa:       t.Idtarifa,
		Nombretarifa:   t.Nombretarifa,
		Tipohabitacion: t.Tipohabitacion,
		Preciobase:     t.Preciobase,
		Fechainicio:    utils.FormatNullDate(t.Fechainicio),
		Fechafin:       utils.FormatNullDate(t.Fechafin),
		Estado:         utils.FormatEstado(t.Estado),
	}
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

	tarifas, err := t.q.GetTarifas(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	var response []tarifaResponse
	for _, tarifa := range tarifas {
		response = append(response, newTarifaResponse(tarifa))
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
// @Router /tarifas/{nombreTarifa} [get]
func (t *TarifaHandler) GetTarifaByNombre(ctx *gin.Context) {

	nombre := ctx.Param("nombreTarifa")

	tarifa, err := t.q.GetTarifaByNombre(ctx, nombre)
	if err != nil {
		ctx.JSON(http.StatusNotFound, errorResponse(err))
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

	var id = ctx.Param("idTarifa")
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	print("PrecioBase: ", req.PrecioBase)
	if req.NombreTarifa == nil &&
		req.PrecioBase == nil &&
		req.FechaInicio == nil &&
		req.FechaFin == nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Debe enviar al menos un campo para actualizar",
		})
		return
	}

	fechaInicio, err := utils.ParseNullDate(req.FechaInicio)
	if err != nil {
		ctx.JSON(400, errorResponse(err))
		return
	}
	fechaFin, err := utils.ParseNullDate(req.FechaFin)
	if err != nil {
		ctx.JSON(400, errorResponse(err))
		return
	}
	idTarifa, err := utils.ParseInt(id)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	idTipoHabitacion := utils.ParseNullIdTipoHabitacion(req.IdTipoHabitacion)
	precioBase := utils.ParseNullString(req.PrecioBase)
	nombreTarifa := utils.ParseNullString(req.NombreTarifa)
	args := dto.UpdateTarifaParams{
		Idtipohabitacion: idTipoHabitacion,
		Preciobase:       precioBase,
		Nombretarifa:     nombreTarifa,
		Fechainicio:      fechaInicio,
		Fechafin:         fechaFin,
		Idtarifa:         idTarifa,
	}

	result, err := t.q.UpdateTarifa(ctx, args)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	var fila, _ = result.RowsAffected()
	ctx.JSON(http.StatusOK, gin.H{"filas afectadas": fila})
}

// DeleteTarifa godoc
// @Summary Eliminar tarifa
// @Description Elimina una tarifa del sistema (soft delete)
// @Tags tarifas
// @Produce json
// @Security BearerAuth
// @Param idTarifa path int true "ID de la tarifa"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /tarifas/{idTarifa} [delete]
func (t *TarifaHandler) DeleteTarifa(ctx *gin.Context) {

	var idTarifaS = ctx.Param("idTarifa")
	var id, err = utils.ParseInt(idTarifaS)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	result, err := t.q.DeleteTarifa(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	var fila, _ = result.RowsAffected()
	ctx.JSON(http.StatusOK, gin.H{"filas afectadas": fila})
}
