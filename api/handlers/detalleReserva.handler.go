package handlers

import (
	"database/sql"
	"errors"
	"net/http"
	"time"

	"reserva-backend/models"
	"reserva-backend/repository"
	"reserva-backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
)

type DetalleReservaHandler struct {
	repository *repository.DetalleReservaRepository
}

func NewDetalleReservaHandler(
	repository *repository.DetalleReservaRepository,
) *DetalleReservaHandler {
	return &DetalleReservaHandler{
		repository: repository,
	}
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

// CreateDetalleReserva godoc
// @Summary Crear detalle de reserva
// @Description Agrega una habitación a una reserva y calcula tarifa, descuento, subtotal, IVA y total
// @Tags detalles-reserva
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param datos body createDetalleReservaRequest true "Datos del detalle"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /detalles-reserva [post]
func (d *DetalleReservaHandler) CreateDetalleReserva(ctx *gin.Context) {
	var req createDetalleReservaRequest

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechaEntrada, err := utils.ParseStringToDate(req.FechaEntrada)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechaSalida, err := utils.ParseStringToDate(req.FechaSalida)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
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

	cantidadNoches, err := calcularNoches(fechaEntrada, fechaSalida)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	// Check-in 2:00 PM
	fechaEntrada = time.Date(
		fechaEntrada.Year(),
		fechaEntrada.Month(),
		fechaEntrada.Day(),
		14, 0, 0, 0,
		fechaEntrada.Location(),
	)

	// Check-out 12:00 PM
	fechaSalida = time.Date(
		fechaSalida.Year(),
		fechaSalida.Month(),
		fechaSalida.Day(),
		12, 0, 0, 0,
		fechaSalida.Location(),
	)

	traslapes, err := d.repository.ContarTraslapes(
		ctx.Request.Context(),
		req.IdHabitacion,
		fechaEntrada,
		fechaSalida,
	)

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

	idTipoHabitacion, err := d.repository.ObtenerTipoHabitacion(
		ctx.Request.Context(),
		req.IdHabitacion,
	)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Habitación no valida",
		})
		return
	}

	tarifa, err := d.repository.ObtenerTarifaActiva(
		ctx.Request.Context(),
		idTipoHabitacion,
		fechaEntrada,
	)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "No existe una tarifa activa para esa habitación y fecha",
		})
		return
	}

	porcentageDescuento, err :=
		d.repository.ObtenerDescuentoCliente(
			ctx.Request.Context(),
			req.IdReserva,
		)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Reserva no valida",
		})
		return
	}

	cien := decimal.NewFromFloat(100)
	noches := decimal.NewFromInt(int64(cantidadNoches))
	ivaRate := decimal.NewFromFloat(0.13)

	precioAplicado := tarifa.PrecioBase.Sub(
		tarifa.PrecioBase.Mul(
			porcentageDescuento.Div(cien),
		),
	)

	subTotal := precioAplicado.Mul(noches)
	iva := subTotal.Mul(ivaRate)
	total := subTotal.Add(iva)

	resultado, err := d.repository.Crear(
		ctx.Request.Context(),
		req.IdHabitacion,
		req.IdReserva,
		tarifa.IDTarifa,
		req.CantidadPersonas,
		precioAplicado,
		fechaEntrada,
		fechaSalida,
		iva,
		subTotal,
		total,
	)

	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"message":      "detalleReserva creada",
		"generated_id": resultado.IDDetalleReserva,
	})
}

func calcularNoches(
	fechaEntrada,
	fechaSalida time.Time,
) (int, error) {

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

	noches := int(
		salida.Sub(entrada).Hours() / 24,
	)

	if noches <= 0 {
		return 0, errors.New(
			"la fecha de salida debe ser posterior a la fecha de entrada",
		)
	}

	if noches > cantidaMaximaNoches {
		return 0, errors.New(
			"no se permite reservar más de 30 noches",
		)
	}

	return noches, nil
}

func fechaActual() (time.Time, error) {
	loc, err := time.LoadLocation("America/Costa_Rica")
	if err != nil {
		return time.Time{}, err
	}

	hoy := time.Now().In(loc)

	return time.Date(
		hoy.Year(),
		hoy.Month(),
		hoy.Day(),
		0, 0, 0, 0,
		hoy.Location(),
	), nil
}

// GetDetalleReservaById godoc
// @Summary Obtener detalle de reserva por ID
// @Description Obtiene un detalle de reserva específico
// @Tags detalles-reserva
// @Produce json
// @Security BearerAuth
// @Param idDetalleReserva path int true "ID del detalle"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /detalles-reserva/{idDetalleReserva} [get]
func (d *DetalleReservaHandler) GetDetalleReservaById(
	ctx *gin.Context,
) {

	id, err := utils.ParseInt(
		ctx.Param("idDetalleReserva"),
	)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	detalle, err := d.repository.ObtenerPorID(
		ctx.Request.Context(),
		id,
	)

	if err != nil {
		ctx.JSON(http.StatusNotFound, errorResponse(err))
		return
	}

	ctx.JSON(
		http.StatusOK,
		newDetalleReservaResponse(detalle),
	)
}

func newDetalleReservaResponse(
	d models.DetalleReserva,
) detalleReservaResponse {

	return detalleReservaResponse{
		Iddetallereserva:     d.IDDetalleReserva,
		Nombretipohabitacion: d.NombreTipoHabitacion,
		Numerohabitacion:     d.NumeroHabitacion,
		Nombrerecepcionista:  d.NombreRecepcionista,
		Nombrecliente:        d.NombreCliente,
		Nombretipocliente:    d.NombreTipoCliente,
		Fechareserva:         d.FechaReserva.Format("2006-01-02"),
		Estadoreserva:        d.EstadoReserva,
		Nombretarifa:         d.NombreTarifa,
		Cantidadpersonas:     d.CantidadPersonas,
		Precioaplicado:       d.PrecioAplicado,
		Fechaentrada:         d.FechaEntrada.Format("2006-01-02"),
		Fechasalida:          d.FechaSalida.Format("2006-01-02"),
		Iva:                  d.Iva,
		Subtotal:             d.SubTotal,
		Total:                d.Total,
		Estado:               utils.FormatEstado(d.Estado),
	}
}

// GetAllDetalleReserva godoc
// @Summary Obtener detalles de reserva
// @Description Obtiene todos los detalles de reserva, activos e inactivos
// @Tags detalles-reserva
// @Produce json
// @Security BearerAuth
// @Success 200 {array} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /detalles-reserva [get]
func (d *DetalleReservaHandler) GetAllDetalleReserva(
	ctx *gin.Context,
) {

	detalles, err := d.repository.Listar(
		ctx.Request.Context(),
	)

	if err != nil {
		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	var response []detalleReservaResponse

	for _, detalle := range detalles {
		response = append(
			response,
			newDetalleReservaResponse(detalle),
		)
	}

	ctx.JSON(http.StatusOK, response)
}

// UpdateDetalleReserva godoc
// @Summary Actualizar detalle de reserva
// @Description Actualiza habitación, cantidad de personas y opcionalmente las fechas del detalle
// @Tags detalles-reserva
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param idDetalleReserva path int true "ID del detalle"
// @Param datos body updateDetalleReservaRequest true "Datos actualizados"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /detalles-reserva/{idDetalleReserva} [patch]
func (d *DetalleReservaHandler) UpdateDetalleReserva(
	ctx *gin.Context,
) {

	id, err := utils.ParseInt(
		ctx.Param("idDetalleReserva"),
	)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	var req updateDetalleReservaRequest

	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	dates, err := d.repository.ObtenerFechas(
		ctx.Request.Context(),
		id,
	)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			ctx.JSON(http.StatusNotFound, gin.H{
				"error": "No se encontró el detalle reserva",
			})
			return
		}

		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	var fechaEntrada time.Time
	var fechaSalida time.Time

	var fechaEntradaParam *time.Time
	var fechaSalidaParam *time.Time

	if req.FechaEntrada != nil {

		fechaEntrada, err =
			utils.ParseStringPtrToTime(req.FechaEntrada)

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

		fechaEntradaParam = &fechaEntrada

	} else {
		fechaEntrada = dates.FechaEntrada
	}

	if req.FechaSalida != nil {

		fechaSalida, err =
			utils.ParseStringPtrToTime(req.FechaSalida)

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

		fechaSalidaParam = &fechaSalida

	} else {
		fechaSalida = dates.FechaSalida
	}

	hoy, err := fechaActual()
	if err != nil {
		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	if fechaEntrada.Before(hoy) {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "La fecha de entrada no puede ser una fecha pasada",
		})
		return
	}

	cantidadNoches, err :=
		calcularNoches(fechaEntrada, fechaSalida)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	traslapes, err :=
		d.repository.ContarTraslapesActualizacion(
			ctx.Request.Context(),
			req.IdHabitacion,
			id,
			fechaEntrada,
			fechaSalida,
		)

	if err != nil {
		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	if traslapes > 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "La habitación ya está reservada en ese rango de fechas",
		})
		return
	}

	idTipoHabitacion, err :=
		d.repository.ObtenerTipoHabitacion(
			ctx.Request.Context(),
			req.IdHabitacion,
		)

	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{
			"error": "No se encontró el tipo de habitación",
		})
		return
	}

	tarifa, err := d.repository.ObtenerTarifaActiva(
		ctx.Request.Context(),
		idTipoHabitacion,
		fechaEntrada,
	)

	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{
			"error": "No existe una tarifa activa para esa habitación y fecha",
		})
		return
	}

	idReserva, err :=
		d.repository.ObtenerIDReserva(
			ctx.Request.Context(),
			id,
		)

	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{
			"error": "No se encontró la reserva",
		})
		return
	}

	porcentageDescuento, err :=
		d.repository.ObtenerDescuentoCliente(
			ctx.Request.Context(),
			idReserva,
		)

	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{
			"error": "No se encontró el cliente asociado a la reserva",
		})
		return
	}

	cien := decimal.NewFromFloat(100)
	noches := decimal.NewFromInt(int64(cantidadNoches))
	ivaRate := decimal.NewFromFloat(0.13)

	precioAplicado := tarifa.PrecioBase.Sub(
		tarifa.PrecioBase.Mul(
			porcentageDescuento.Div(cien),
		),
	)

	subTotal := precioAplicado.Mul(noches)
	iva := subTotal.Mul(ivaRate)
	total := subTotal.Add(iva)

	resultado, err := d.repository.Actualizar(
		ctx.Request.Context(),
		id,
		req.IdHabitacion,
		tarifa.IDTarifa,
		req.CantidadPersonas,
		precioAplicado,
		fechaEntradaParam,
		fechaSalidaParam,
		iva,
		subTotal,
		total,
	)

	if err != nil {
		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"message":       "detalleReserva actualizada",
		"rows affected": resultado.FilasAfectadas,
	})
}

// DeleteDetalleReserva godoc
// @Summary Activar o desactivar detalle de reserva
// @Description Alterna el estado lógico del detalle entre activo e inactivo
// @Tags detalles-reserva
// @Produce json
// @Security BearerAuth
// @Param idDetalleReserva path int true "ID del detalle"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /detalles-reserva/{idDetalleReserva} [delete]
func (d *DetalleReservaHandler) DeleteDetalleReserva(
	ctx *gin.Context,
) {

	id, err := utils.ParseInt(
		ctx.Param("idDetalleReserva"),
	)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	resultado, err := d.repository.ToggleEstado(
		ctx.Request.Context(),
		id,
	)

	if err != nil {
		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	detalleEstado :=
		"detalleReserva desactivada correctamente"

	if resultado.Estado == 1 {
		detalleEstado =
			"detalleReserva activada correctamente"
	}

	ctx.JSON(http.StatusOK, gin.H{
		"message":         detalleEstado,
		"filas afectadas": resultado.FilasAfectadas,
	})
}

// GetDetallesByReserva godoc
// @Summary Obtener detalles por reserva
// @Description Obtiene los detalles activos pertenecientes a una reserva
// @Tags detalles-reserva
// @Produce json
// @Security BearerAuth
// @Param idReserva path int true "ID de la reserva"
// @Success 200 {array} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /detalles-reserva/reserva/{idReserva} [get]
func (d *DetalleReservaHandler) GetDetallesByReserva(
	ctx *gin.Context,
) {

	id, err := utils.ParseInt(
		ctx.Param("idReserva"),
	)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	detalles, err := d.repository.ListarPorReserva(
		ctx.Request.Context(),
		id,
	)

	if err != nil {
		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	var response []detalleByReservaResponse

	for _, detalle := range detalles {
		response = append(
			response,
			detalleByReservaResponse{
				Iddetallereserva:     detalle.IDDetalleReserva,
				Nombretipohabitacion: detalle.NombreTipoHabitacion,
				Numerohabitacion:     detalle.NumeroHabitacion,
				Nombretarifa:         detalle.NombreTarifa,
				Descuentobase:        detalle.DescuentoBase,
				Cantidadpersonas:     detalle.CantidadPersonas,
				Precioaplicado:       detalle.PrecioAplicado,
				Fechaentrada:         detalle.FechaEntrada.Format("2006-01-02"),
				Fechasalida:          detalle.FechaSalida.Format("2006-01-02"),
				Iva:                  detalle.Iva,
				Subtotal:             detalle.SubTotal,
				Total:                detalle.Total,
			},
		)
	}

	if response == nil {
		response = []detalleByReservaResponse{}
	}

	ctx.JSON(http.StatusOK, response)
}

// GetFechasOcupadasByHabitacion godoc
// @Summary Obtener fechas ocupadas de una habitación
// @Description Obtiene los rangos de fechas ocupados por detalles activos
// @Tags detalles-reserva
// @Produce json
// @Security BearerAuth
// @Param idHabitacion path int true "ID de la habitación"
// @Success 200 {array} map[string]string
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /detalles-reserva/habitacion/{idHabitacion}/fechas-ocupadas [get]
func (d *DetalleReservaHandler) GetFechasOcupadasByHabitacion(
	ctx *gin.Context,
) {

	id, err := utils.ParseInt(
		ctx.Param("idHabitacion"),
	)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechas, err := d.repository.ObtenerFechasOcupadas(
		ctx.Request.Context(),
		id,
	)

	if err != nil {
		ctx.JSON(
			http.StatusInternalServerError,
			errorResponse(err),
		)
		return
	}

	var response []map[string]string

	for _, fecha := range fechas {
		response = append(
			response,
			map[string]string{
				"fechaEntrada": fecha.FechaEntrada.Format("2006-01-02"),
				"fechaSalida":  fecha.FechaSalida.Format("2006-01-02"),
			},
		)
	}

	if response == nil {
		response = []map[string]string{}
	}

	ctx.JSON(http.StatusOK, response)
}

// GetTarifaByHabitacion godoc
// @Summary Obtener tarifa por habitación y fecha
// @Description Obtiene la tarifa activa correspondiente a una habitación para una fecha determinada
// @Tags detalles-reserva
// @Produce json
// @Security BearerAuth
// @Param idHabitacion path int true "ID de la habitación"
// @Param fecha query string true "Fecha en formato YYYY-MM-DD"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /detalles-reserva/habitacion/{idHabitacion}/tarifa [get]
func (d *DetalleReservaHandler) GetTarifaByHabitacion(
	ctx *gin.Context,
) {

	id, err := utils.ParseInt(
		ctx.Param("idHabitacion"),
	)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	fechaStr := ctx.Query("fecha")

	if fechaStr == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "fecha requerida",
		})
		return
	}

	fecha, err := utils.ParseStringToDate(fechaStr)

	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "formato de fecha inválido",
		})
		return
	}

	idTipoHabitacion, err :=
		d.repository.ObtenerTipoHabitacion(
			ctx.Request.Context(),
			id,
		)

	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{
			"error": "habitación no válida",
		})
		return
	}

	tarifa, err := d.repository.ObtenerTarifaActiva(
		ctx.Request.Context(),
		idTipoHabitacion,
		fecha,
	)

	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{
			"error": "no hay tarifa activa para esta habitación y fecha",
		})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"idTarifa":     tarifa.IDTarifa,
		"nombreTarifa": tarifa.NombreTarifa,
		"precioBase":   tarifa.PrecioBase,
	})
}
