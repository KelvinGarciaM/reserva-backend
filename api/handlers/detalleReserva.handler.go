package handlers

import (
	"database/sql"
	"errors"
	"net/http"
	"reserva-backend/dto"
	"reserva-backend/utils"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type DetalleReservaHandler struct {
	q *dto.Queries
}

func NewDetalleReservaHandler(q *dto.Queries) *DetalleReservaHandler {
	return &DetalleReservaHandler{q}
}

type createDetalleReservaRequest struct {
	IdHabitacion     int32  `json:"idHabitacion" binding:"required"`
	IdReserva        int32  `json:"idReserva" binding:"required"`
	CantidadPersonas int32  `json:"cantidadPersonas"`
	FechaEntrada     string `json:"fechaEntrada" binding:"required"`
	FechaSalida      string `json:"fechaSalida" binding:"required"`
}
type updateDetalleReservaRequest struct {
	IdHabitacion     int32   `json:"idHabitacion" binding:"required"`
	CantidadPersonas int32   `json:"cantidadPersonas" binding:"required"`
	FechaEntrada     *string `json:"fechaEntrada"`
	FechaSalida      *string `json:"fechaSalida"`
}

type deleteDetalleReservaRequest struct {
	IdDetalleReserva int32 `json:"idDetalleReserva" binding:"required"`
}

const cantidaMaximaNoches = 30

// CreateDetalleReserva godoc
// @Summary Crear detalle de reserva
// @Description Registra un nuevo detalle de reserva con cálculos de precios, impuestos y descuentos
// @Tags detalles-reserva
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param detalle body createDetalleReservaRequest true "Datos del detalle de reserva"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /detalles-reserva [post]
func (d *DetalleReservaHandler) CreateDetalleReserva(ctx *gin.Context) {

	var req createDetalleReservaRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechaEntrada, err := utils.ParseStringToDate(req.FechaEntrada)
	if err != nil {
		ctx.JSON(400, errorResponse(err))
		return
	}
	fechaSalida, err := utils.ParseStringToDate(req.FechaSalida)
	if err != nil {
		ctx.JSON(400, errorResponse(err))
		return
	}

	hoy, err := fechaActual()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	if fechaEntrada.Before(hoy) {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "La fecha de entrada no puede ser una fecha pasada",
		})
		return
	}
	// en calcularNoches se valida que la fechaSalida sea posterior a la fecha de entrada
	// y que no sean más de 30 noches
	cantidadNoches, err := calcularNoches(fechaEntrada, fechaSalida)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechaEntrada = time.Date(
		fechaEntrada.Year(),
		fechaEntrada.Month(),
		fechaEntrada.Day(),
		14, 0, 0, 0,
		fechaEntrada.Location(),
	)

	fechaSalida = time.Date(
		fechaSalida.Year(),
		fechaSalida.Month(),
		fechaSalida.Day(),
		12, 0, 0, 0,
		fechaSalida.Location(),
	)

	traslapes, err := d.q.CountTraslapesDetalleReserva(ctx, dto.CountTraslapesDetalleReservaParams{
		Idhabitacion: req.IdHabitacion,
		Fechaentrada: fechaEntrada,
		Fechasalida:  fechaSalida,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	if traslapes > 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "La habitación ya está reservada en ese rango de fechas",
		})
		return
	}
	idTipoHabitacion, err := d.q.GetTipoHabitacionByHabitacion(ctx, req.IdHabitacion)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Habitación no valida",
		})
		return
	}

	parametros := dto.GetTarifaActivaByTipoHabitacionAndFechaParams{
		Idtipohabitacion: idTipoHabitacion,
		Fecha:            fechaEntrada,
	}
	tarifa, err := d.q.GetTarifaActivaByTipoHabitacionAndFecha(ctx, parametros)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "No existe una tarifa activa para esa habitación y fecha",
		})
		return
	}
	porcentageDescuentoSTR, err := d.q.GetClienteByReserva(ctx, req.IdReserva)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Reserva no valida",
		})
		return
	}
	porcentageDescuento, err := strconv.ParseFloat(porcentageDescuentoSTR, 64)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno al procesar el descuentoBase"})
		return
	}

	precioAplicado, err := strconv.ParseFloat(tarifa.Preciobase, 64)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno al procesar la tarifa"})
		return
	}
	montoDescuento := precioAplicado * (porcentageDescuento / 100)
	precioAplicado = precioAplicado - montoDescuento //90

	subTotal := precioAplicado * float64(cantidadNoches) //180
	iva := subTotal * 0.13                               // 23.4
	total := subTotal + iva                              // 203.4
	precioAplicadoStr := strconv.FormatFloat(precioAplicado, 'f', 2, 64)
	ivaStr := strconv.FormatFloat(iva, 'f', 2, 64)
	subTotalStr := strconv.FormatFloat(subTotal, 'f', 2, 64)
	totalStr := strconv.FormatFloat(total, 'f', 2, 64)
	args := dto.CreateDetalleReservaParams{
		Idhabitacion:     req.IdHabitacion,
		Idreserva:        req.IdReserva,
		Idtarifa:         tarifa.Idtarifa,
		Cantidadpersonas: req.CantidadPersonas,
		Precioaplicado:   precioAplicadoStr,
		Fechaentrada:     fechaEntrada,
		Fechasalida:      fechaSalida,
		Iva:              ivaStr,
		Subtotal:         subTotalStr,
		Total:            totalStr,
	}
	detalleReserva, err := d.q.CreateDetalleReserva(ctx, args)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	var lastId, _ = detalleReserva.LastInsertId()
	ctx.JSON(http.StatusOK, gin.H{
		"message":      "detalleReserva creada",
		"generated_id": lastId})
}

func calcularNoches(fechaEntrada, fechaSalida time.Time) (int, error) {

	entrada := time.Date(
		fechaEntrada.Year(),
		fechaEntrada.Month(),
		fechaEntrada.Day(),
		0, 0, 0, 0,
		fechaEntrada.Location(),
	)

	salida := time.Date(
		fechaSalida.Year(),
		fechaSalida.Month(),
		fechaSalida.Day(),
		0, 0, 0, 0,
		fechaSalida.Location(),
	)

	noches := int(salida.Sub(entrada).Hours() / 24)

	if noches <= 0 {
		return 0, errors.New("la fecha de salida debe ser posterior a la fecha de entrada")
	}

	if noches > cantidaMaximaNoches {
		return 0, errors.New("no se permite reservar más de 30 noches")
	}

	return noches, nil
}

func fechaActual() (time.Time, error) {
	loc, err := time.LoadLocation("America/Costa_Rica")
	if err != nil {
		return time.Time{}, err
	}
	hoy := time.Now().In(loc)
	return time.Date(hoy.Year(),
		hoy.Month(),
		hoy.Day(),
		0, 0, 0, 0, hoy.Location()), nil
}

// GetDetalleReservaById godoc
// @Summary Obtener detalle de reserva por ID
// @Description Busca un detalle de reserva por su ID
// @Tags detalles-reserva
// @Produce json
// @Security BearerAuth
// @Param idDetalleReserva path int true "ID del detalle de reserva"
// @Success 200 {object} detalleReservaResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /detalles-reserva/{idDetalleReserva} [get]
func (d *DetalleReservaHandler) GetDetalleReservaById(ctx *gin.Context) {

	idStr := ctx.Param("idDetalleReserva")
	id, err := utils.ParseInt(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
	}

	detalleReserva, err := d.q.GetDetalleReservaByID(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, errorResponse(err))
		return
	}
	response := newDetalleReservaByIdResponse(detalleReserva)

	ctx.JSON(http.StatusOK, response)
}

// formato de respuesta que quiero que tenga el JSON
type detalleReservaResponse struct {
	Iddetallereserva     int32  `json:"idDetalleReserva"`
	Nombretipohabitacion string `json:"nombreTipoHabitacion"`
	Numerohabitacion     string `json:"numeroHabitacion"`
	Nombrerecepcionista  string `json:"nombreRecepcionista"`
	Nombrecliente        string `json:"nombreCliente"`
	Nombretipocliente    string `json:"nombreTipoCliente"`
	Fechareserva         string `json:"fechaReserva"`
	Estadoreserva        string `json:"estadoReserva"`
	Nombretarifa         string `json:"nombreTarifa"`
	Cantidadpersonas     int32  `json:"cantidadPersonas"`
	Precioaplicado       string `json:"precioAplicado"`
	Fechaentrada         string `json:"fechaEntrada"`
	Fechasalida          string `json:"fechaSalida"`
	Iva                  string `json:"Iva"`
	Subtotal             string `json:"subTotal"`
	Total                string `json:"Total"`
	Estado               string `json:"Estado"`
}

// convertir la estructura que me devuelve la db a el nuevo formato
func newDetalleReservaByIdResponse(d dto.GetDetalleReservaByIDRow) detalleReservaResponse {
	return detalleReservaResponse{
		Iddetallereserva:     d.Iddetallereserva,
		Nombretipohabitacion: d.Nombretipohabitacion,
		Numerohabitacion:     d.Numerohabitacion,
		Nombrerecepcionista:  d.Nombrerecepcionista,
		Nombrecliente:        d.Nombrecliente,
		Nombretipocliente:    d.Nombretipocliente,
		Fechareserva:         d.Fechareserva.Format("2006-01-02"),
		Estadoreserva:        d.Estadoreserva,
		Nombretarifa:         d.Nombretarifa,
		Cantidadpersonas:     d.Cantidadpersonas,
		Precioaplicado:       d.Precioaplicado,
		Fechaentrada:         d.Fechaentrada.Format("2006-01-02"),
		Fechasalida:          d.Fechasalida.Format("2006-01-02"),
		Iva:                  d.Iva,
		Subtotal:             d.Subtotal,
		Total:                d.Total,
		Estado:               utils.FormatEstado(d.Estado),
	}
}
func newDetalleReservaResponse(d dto.GetAllDetalleReservaRow) detalleReservaResponse {
	return detalleReservaResponse{
		Iddetallereserva:     d.Iddetallereserva,
		Nombretipohabitacion: d.Nombretipohabitacion,
		Numerohabitacion:     d.Numerohabitacion,
		Nombrerecepcionista:  d.Nombrerecepcionista,
		Nombrecliente:        d.Nombrecliente,
		Nombretipocliente:    d.Nombretipocliente,
		Fechareserva:         d.Fechareserva.Format("2006-01-02"),
		Estadoreserva:        d.Estadoreserva,
		Nombretarifa:         d.Nombretarifa,
		Cantidadpersonas:     d.Cantidadpersonas,
		Precioaplicado:       d.Precioaplicado,
		Fechaentrada:         d.Fechaentrada.Format("2006-01-02"),
		Fechasalida:          d.Fechasalida.Format("2006-01-02"),
		Iva:                  d.Iva,
		Subtotal:             d.Subtotal,
		Total:                d.Total,
		Estado:               utils.FormatEstado(d.Estado),
	}
}

// GetAllDetalleReserva godoc
// @Summary Obtener todos los detalles de reserva
// @Description Devuelve la lista completa de detalles de reserva
// @Tags detalles-reserva
// @Produce json
// @Security BearerAuth
// @Success 200 {array} detalleReservaResponse
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /detalles-reserva [get]
func (t *DetalleReservaHandler) GetAllDetalleReserva(ctx *gin.Context) {

	detallesReserva, err := t.q.GetAllDetalleReserva(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	var response []detalleReservaResponse
	for _, detalleReserva := range detallesReserva {
		response = append(response, newDetalleReservaResponse(detalleReserva))
	}

	ctx.JSON(http.StatusOK, response)
}

// UpdateDetalleReserva godoc
// @Summary Actualizar detalle de reserva
// @Description Actualiza los datos de un detalle de reserva existente
// @Tags detalles-reserva
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param idDetalleReserva path int true "ID del detalle de reserva"
// @Param detalle body updateDetalleReservaRequest true "Datos a actualizar"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /detalles-reserva/{idDetalleReserva} [put]
func (d *DetalleReservaHandler) UpdateDetalleReserva(ctx *gin.Context) {

	var req updateDetalleReservaRequest

	var idStr = ctx.Param("idDetalleReserva")
	id, err := utils.ParseInt(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	var fechaEntrada time.Time
	var fechaSalida time.Time
	var fechaEntradaParam sql.NullTime
	var fechaSalidaParam sql.NullTime
	dates, err := d.q.GetFechasByIdDetalleReserva(ctx, id)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{
				"error": "No se encontró el detalle reserva"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	if req.FechaEntrada != nil {
		fechaEntrada, err = utils.ParseStringPtrToTime(req.FechaEntrada)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{
				"error":   "Formato inválido para fechaEntrada",
				"Formato": "YYYY-MM-DD",
			})
			return
		}

		fechaEntrada = time.Date(
			fechaEntrada.Year(),
			fechaEntrada.Month(),
			fechaEntrada.Day(),
			14, 0, 0, 0,
			fechaEntrada.Location(),
		)

		fechaEntradaParam = sql.NullTime{
			Time:  fechaEntrada,
			Valid: true,
		}
	} else {
		fechaEntrada = dates.Fechaentrada
		fechaEntradaParam = sql.NullTime{
			Valid: false,
		}
	}
	if req.FechaSalida != nil {
		fechaSalida, err = utils.ParseStringPtrToTime(req.FechaSalida)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{
				"error":   "Formato inválido para fechaSalida",
				"Formato": "YYYY-MM-DD",
			})
			return
		}
		fechaSalida = time.Date(
			fechaSalida.Year(),
			fechaSalida.Month(),
			fechaSalida.Day(),
			12, 0, 0, 0,
			fechaSalida.Location(),
		)
		fechaSalidaParam = sql.NullTime{
			Time:  fechaSalida,
			Valid: true,
		}
	} else {
		fechaSalida = dates.Fechasalida
		fechaSalidaParam = sql.NullTime{
			Valid: false,
		}
	}

	hoy, err := fechaActual()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	if fechaEntrada.Before(hoy) {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "La fecha de entrada no puede ser una fecha pasada",
		})
		return
	}
	// en calcularNoches se valida que la fechaSalida sea posterior a la fecha de entrada
	// y que no sean más de 30 noches
	cantidadNoches, err := calcularNoches(fechaEntrada, fechaSalida)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	traslapes, err := d.q.CountTraslapesDetalleReservaUpdate(ctx, dto.CountTraslapesDetalleReservaUpdateParams{
		Idhabitacion:     req.IdHabitacion,
		Iddetallereserva: id,
		Fechaentrada:     fechaEntrada,
		Fechasalida:      fechaSalida,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	if traslapes > 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "La habitación ya está reservada en ese rango de fechas",
		})
		return
	}

	idTipoHabitacion, err := d.q.GetTipoHabitacionByHabitacion(ctx, req.IdHabitacion)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{
				"error": "No se encontró el tipo de habitación",
			})
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	parametros := dto.GetTarifaActivaByTipoHabitacionAndFechaParams{
		Idtipohabitacion: idTipoHabitacion,
		Fecha:            fechaEntrada,
	}
	tarifa, err := d.q.GetTarifaActivaByTipoHabitacionAndFecha(ctx, parametros)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{
				"error": "No existe una tarifa activa para esa habitación y fecha",
			})
			return
		}

		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	idReserva, err := d.q.GetReservanByIdDetalleReserva(ctx, id)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{
				"error": "No se encontró la reserva",
			})
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	porcentageDescuentoSTR, err := d.q.GetClienteByReserva(ctx, idReserva)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{
				"error": "No se encontró el cliente asociado a la reserva",
			})
			return
		}

		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	porcentageDescuento, err := strconv.ParseFloat(porcentageDescuentoSTR, 64)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno al procesar el descuentoBase"})
		return
	}

	precioAplicado, err := strconv.ParseFloat(tarifa.Preciobase, 64)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error interno al procesar la tarifa"})
		return
	}
	montoDescuento := precioAplicado * (porcentageDescuento / 100)
	precioAplicado = precioAplicado - montoDescuento //90

	subTotal := precioAplicado * float64(cantidadNoches) //180
	iva := subTotal * 0.13                               // 23.4
	total := subTotal + iva                              // 203.4
	precioAplicadoStr := strconv.FormatFloat(precioAplicado, 'f', 2, 64)
	ivaStr := strconv.FormatFloat(iva, 'f', 2, 64)
	subTotalStr := strconv.FormatFloat(subTotal, 'f', 2, 64)
	totalStr := strconv.FormatFloat(total, 'f', 2, 64)
	args := dto.UpdateDetalleReservaParams{
		Idhabitacion:     req.IdHabitacion,
		Idtarifa:         tarifa.Idtarifa,
		Cantidadpersonas: req.CantidadPersonas,
		Precioaplicado:   precioAplicadoStr,
		Fechaentrada:     fechaEntradaParam,
		Fechasalida:      fechaSalidaParam,
		Iva:              ivaStr,
		Subtotal:         subTotalStr,
		Total:            totalStr,
		Iddetallereserva: id,
	}

	result, err := d.q.UpdateDetalleReserva(ctx, args)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	rows, err := result.RowsAffected()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"message":       "detalleReserva actualizada",
		"rows affected": rows})
}

// DeleteDetalleReserva godoc
// @Summary Eliminar/Activar detalle de reserva (soft delete)
// @Description Cambia el estado del detalle de reserva (activo/inactivo)
// @Tags detalles-reserva
// @Produce json
// @Security BearerAuth
// @Param idDetalleReserva path int true "ID del detalle de reserva"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /detalles-reserva/{idDetalleReserva} [delete]
func (d *DetalleReservaHandler) DeleteDetalleReserva(ctx *gin.Context) {

	var idDetalleReservaStr = ctx.Param("idDetalleReserva")
	var id, err = utils.ParseInt(idDetalleReservaStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	result, err := d.q.DeleteDetalleReserva(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	value, err := d.q.GetEstadoDetalleReserva(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	detalleEstado := "detalleReserva desactivada correctamente"
	if value == 1 {
		detalleEstado = "detalleReserva activada correctamente"
	}
	var fila, _ = result.RowsAffected()
	ctx.JSON(http.StatusOK, gin.H{
		"messge":          detalleEstado,
		"filas afectadas": fila})
}
