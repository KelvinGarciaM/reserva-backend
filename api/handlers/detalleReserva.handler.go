package handlers

import (
	"database/sql"
	"errors"
	"net/http"
	"reserva-backend/dto"
	"reserva-backend/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
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

type detalleReservaResponse struct {
	Iddetallereserva     int32           `json:"idDetalleReserva"`
	Nombretipohabitacion string          `json:"nombreTipoHabitacion"`
	Numerohabitacion     string          `json:"numeroHabitacion"`
	Nombrerecepcionista  string          `json:"nombreRecepcionista"`
	Nombrecliente        string          `json:"nombreCliente"`
	Nombretipocliente    string          `json:"nombreTipoCliente"`
	Fechareserva         string          `json:"fechaReserva"`
	Estadoreserva        string          `json:"estadoReserva"`
	Nombretarifa         string          `json:"nombreTarifa"`
	Cantidadpersonas     int32           `json:"cantidadPersonas"`
	Precioaplicado       decimal.Decimal `json:"precioAplicado"`
	Fechaentrada         string          `json:"fechaEntrada"`
	Fechasalida          string          `json:"fechaSalida"`
	Iva                  decimal.Decimal `json:"Iva"`
	Subtotal             decimal.Decimal `json:"subTotal"`
	Total                decimal.Decimal `json:"Total"`
	Estado               string          `json:"Estado"`
}

type detalleByReservaResponse struct {
	Iddetallereserva     int32           `json:"idDetalleReserva"`
	Nombretipohabitacion string          `json:"nombreTipoHabitacion"`
	Numerohabitacion     string          `json:"numeroHabitacion"`
	Nombretarifa         string          `json:"nombreTarifa"`
	Descuentobase        decimal.Decimal `json:"descuentoBase"`
	Cantidadpersonas     int32           `json:"cantidadPersonas"`
	Precioaplicado       decimal.Decimal `json:"precioAplicado"`
	Fechaentrada         string          `json:"fechaEntrada"`
	Fechasalida          string          `json:"fechaSalida"`
	Iva                  decimal.Decimal `json:"iva"`
	Subtotal             decimal.Decimal `json:"subTotal"`
	Total                decimal.Decimal `json:"total"`
}

const cantidaMaximaNoches = 30

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
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "La fecha de entrada no puede ser una fecha pasada"})
		return
	}

	cantidadNoches, err := calcularNoches(fechaEntrada, fechaSalida)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechaEntrada = time.Date(fechaEntrada.Year(), fechaEntrada.Month(), fechaEntrada.Day(), 14, 0, 0, 0, fechaEntrada.Location())
	fechaSalida = time.Date(fechaSalida.Year(), fechaSalida.Month(), fechaSalida.Day(), 12, 0, 0, 0, fechaSalida.Location())

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
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "La habitación ya está reservada en ese rango de fechas"})
		return
	}

	idTipoHabitacion, err := d.q.GetTipoHabitacionByHabitacion(ctx, req.IdHabitacion)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Habitación no valida"})
		return
	}

	tarifa, err := d.q.GetTarifaActivaByTipoHabitacionAndFecha(ctx, dto.GetTarifaActivaByTipoHabitacionAndFechaParams{
		Idtipohabitacion: idTipoHabitacion,
		Fecha:            fechaEntrada,
	})
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "No existe una tarifa activa para esa habitación y fecha"})
		return
	}

	porcentageDescuento, err := d.q.GetClienteByReserva(ctx, req.IdReserva)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Reserva no valida"})
		return
	}

	cien := decimal.NewFromFloat(100)
	noches := decimal.NewFromInt(int64(cantidadNoches))
	ivaRate := decimal.NewFromFloat(0.13)

	precioAplicado := tarifa.Preciobase.Sub(tarifa.Preciobase.Mul(porcentageDescuento.Div(cien)))
	subTotal := precioAplicado.Mul(noches)
	iva := subTotal.Mul(ivaRate)
	total := subTotal.Add(iva)

	args := dto.CreateDetalleReservaParams{
		Idhabitacion:     req.IdHabitacion,
		Idreserva:        req.IdReserva,
		Idtarifa:         tarifa.Idtarifa,
		Cantidadpersonas: req.CantidadPersonas,
		Precioaplicado:   precioAplicado,
		Fechaentrada:     fechaEntrada,
		Fechasalida:      fechaSalida,
		Iva:              iva,
		Subtotal:         subTotal,
		Total:            total,
	}

	detalleReserva, err := d.q.CreateDetalleReserva(ctx, args)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	lastId, _ := detalleReserva.LastInsertId()
	ctx.JSON(http.StatusOK, gin.H{"message": "detalleReserva creada", "generated_id": lastId})
}

func calcularNoches(fechaEntrada, fechaSalida time.Time) (int, error) {
	entrada := time.Date(fechaEntrada.Year(), fechaEntrada.Month(), fechaEntrada.Day(), 0, 0, 0, 0, fechaEntrada.Location())
	salida := time.Date(fechaSalida.Year(), fechaSalida.Month(), fechaSalida.Day(), 0, 0, 0, 0, fechaSalida.Location())
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
	return time.Date(hoy.Year(), hoy.Month(), hoy.Day(), 0, 0, 0, 0, hoy.Location()), nil
}

func (d *DetalleReservaHandler) GetDetalleReservaById(ctx *gin.Context) {
	idStr := ctx.Param("idDetalleReserva")
	id, err := utils.ParseInt(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	detalleReserva, err := d.q.GetDetalleReservaByID(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, errorResponse(err))
		return
	}

	ctx.JSON(http.StatusOK, newDetalleReservaByIdResponse(detalleReserva))
}

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

func (t *DetalleReservaHandler) GetAllDetalleReserva(ctx *gin.Context) {
	detallesReserva, err := t.q.GetAllDetalleReserva(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	var response []detalleReservaResponse
	for _, d := range detallesReserva {
		response = append(response, newDetalleReservaResponse(d))
	}
	ctx.JSON(http.StatusOK, response)
}

func (d *DetalleReservaHandler) UpdateDetalleReserva(ctx *gin.Context) {
	var req updateDetalleReservaRequest

	id, err := utils.ParseInt(ctx.Param("idDetalleReserva"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	var fechaEntrada, fechaSalida time.Time
	var fechaEntradaParam, fechaSalidaParam sql.NullTime

	dates, err := d.q.GetFechasByIdDetalleReserva(ctx, id)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "No se encontró el detalle reserva"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	if req.FechaEntrada != nil {
		fechaEntrada, err = utils.ParseStringPtrToTime(req.FechaEntrada)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Formato inválido para fechaEntrada", "Formato": "YYYY-MM-DD"})
			return
		}
		fechaEntrada = time.Date(fechaEntrada.Year(), fechaEntrada.Month(), fechaEntrada.Day(), 14, 0, 0, 0, fechaEntrada.Location())
		fechaEntradaParam = sql.NullTime{Time: fechaEntrada, Valid: true}
	} else {
		fechaEntrada = dates.Fechaentrada
		fechaEntradaParam = sql.NullTime{Valid: false}
	}

	if req.FechaSalida != nil {
		fechaSalida, err = utils.ParseStringPtrToTime(req.FechaSalida)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Formato inválido para fechaSalida", "Formato": "YYYY-MM-DD"})
			return
		}
		fechaSalida = time.Date(fechaSalida.Year(), fechaSalida.Month(), fechaSalida.Day(), 12, 0, 0, 0, fechaSalida.Location())
		fechaSalidaParam = sql.NullTime{Time: fechaSalida, Valid: true}
	} else {
		fechaSalida = dates.Fechasalida
		fechaSalidaParam = sql.NullTime{Valid: false}
	}

	hoy, err := fechaActual()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	if fechaEntrada.Before(hoy) {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "La fecha de entrada no puede ser una fecha pasada"})
		return
	}

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
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "La habitación ya está reservada en ese rango de fechas"})
		return
	}

	idTipoHabitacion, err := d.q.GetTipoHabitacionByHabitacion(ctx, req.IdHabitacion)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "No se encontró el tipo de habitación"})
		return
	}

	tarifa, err := d.q.GetTarifaActivaByTipoHabitacionAndFecha(ctx, dto.GetTarifaActivaByTipoHabitacionAndFechaParams{
		Idtipohabitacion: idTipoHabitacion,
		Fecha:            fechaEntrada,
	})
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "No existe una tarifa activa para esa habitación y fecha"})
		return
	}

	idReserva, err := d.q.GetReservanByIdDetalleReserva(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "No se encontró la reserva"})
		return
	}

	porcentageDescuento, err := d.q.GetClienteByReserva(ctx, idReserva)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "No se encontró el cliente asociado a la reserva"})
		return
	}

	cien := decimal.NewFromFloat(100)
	noches := decimal.NewFromInt(int64(cantidadNoches))
	ivaRate := decimal.NewFromFloat(0.13)

	precioAplicado := tarifa.Preciobase.Sub(tarifa.Preciobase.Mul(porcentageDescuento.Div(cien)))
	subTotal := precioAplicado.Mul(noches)
	iva := subTotal.Mul(ivaRate)
	total := subTotal.Add(iva)

	result, err := d.q.UpdateDetalleReserva(ctx, dto.UpdateDetalleReservaParams{
		Idhabitacion:     req.IdHabitacion,
		Idtarifa:         tarifa.Idtarifa,
		Cantidadpersonas: req.CantidadPersonas,
		Precioaplicado:   precioAplicado,
		Fechaentrada:     fechaEntradaParam,
		Fechasalida:      fechaSalidaParam,
		Iva:              iva,
		Subtotal:         subTotal,
		Total:            total,
		Iddetallereserva: id,
	})
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	rows, _ := result.RowsAffected()
	ctx.JSON(http.StatusOK, gin.H{"message": "detalleReserva actualizada", "rows affected": rows})
}

func (d *DetalleReservaHandler) DeleteDetalleReserva(ctx *gin.Context) {
	id, err := utils.ParseInt(ctx.Param("idDetalleReserva"))
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

	fila, _ := result.RowsAffected()
	ctx.JSON(http.StatusOK, gin.H{"message": detalleEstado, "filas afectadas": fila})
}

func (d *DetalleReservaHandler) GetDetallesByReserva(ctx *gin.Context) {
	id, err := utils.ParseInt(ctx.Param("idReserva"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	detalles, err := d.q.GetDetallesByReserva(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	var response []detalleByReservaResponse
	for _, d := range detalles {
		response = append(response, detalleByReservaResponse{
			Iddetallereserva:     d.Iddetallereserva,
			Nombretipohabitacion: d.Nombretipohabitacion,
			Numerohabitacion:     d.Numerohabitacion,
			Nombretarifa:         d.Nombretarifa,
			Descuentobase:        d.Descuentobase,
			Cantidadpersonas:     d.Cantidadpersonas,
			Precioaplicado:       d.Precioaplicado,
			Fechaentrada:         d.Fechaentrada.Format("2006-01-02"),
			Fechasalida:          d.Fechasalida.Format("2006-01-02"),
			Iva:                  d.Iva,
			Subtotal:             d.Subtotal,
			Total:                d.Total,
		})
	}

	if response == nil {
		response = []detalleByReservaResponse{}
	}
	ctx.JSON(http.StatusOK, response)
}

func (d *DetalleReservaHandler) GetFechasOcupadasByHabitacion(ctx *gin.Context) {
	id, err := utils.ParseInt(ctx.Param("idHabitacion"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechas, err := d.q.GetFechasOcupadasByHabitacion(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	var response []map[string]string
	for _, f := range fechas {
		response = append(response, map[string]string{
			"fechaEntrada": f.Fechaentrada.Format("2006-01-02"),
			"fechaSalida":  f.Fechasalida.Format("2006-01-02"),
		})
	}

	if response == nil {
		response = []map[string]string{}
	}
	ctx.JSON(http.StatusOK, response)
}

func (d *DetalleReservaHandler) GetTarifaByHabitacion(ctx *gin.Context) {
	id, err := utils.ParseInt(ctx.Param("idHabitacion"))
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechaStr := ctx.Query("fecha")
	if fechaStr == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "fecha requerida"})
		return
	}

	fecha, err := utils.ParseStringToDate(fechaStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "formato de fecha inválido"})
		return
	}

	idTipoHabitacion, err := d.q.GetTipoHabitacionByHabitacion(ctx, id)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "habitación no válida"})
		return
	}

	tarifa, err := d.q.GetTarifaActivaByTipoHabitacionAndFecha(ctx, dto.GetTarifaActivaByTipoHabitacionAndFechaParams{
		Idtipohabitacion: idTipoHabitacion,
		Fecha:            fecha,
	})
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "no hay tarifa activa para esta habitación y fecha"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"idTarifa":     tarifa.Idtarifa,
		"nombreTarifa": tarifa.Nombretarifa,
		"precioBase":   tarifa.Preciobase,
	})
}
