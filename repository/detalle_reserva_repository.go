package repository

import (
	"context"
	"database/sql"
	"time"

	"reserva-backend/models"

	"github.com/shopspring/decimal"
)

type DetalleReservaRepository struct {
	db *sql.DB
}

func NewDetalleReservaRepository(
	db *sql.DB,
) *DetalleReservaRepository {
	return &DetalleReservaRepository{
		db: db,
	}
}

type CrearDetalleReservaResultado struct {
	IDDetalleReserva int32
	Mensaje          string
}

type ActualizarDetalleReservaResultado struct {
	IDDetalleReserva int32
	FilasAfectadas   int32
	Mensaje          string
}

type ToggleDetalleReservaResultado struct {
	IDDetalleReserva int32
	Estado           int8
	FilasAfectadas   int32
}

func (r *DetalleReservaRepository) Crear(
	ctx context.Context,
	idHabitacion int32,
	idReserva int32,
	idTarifa int32,
	cantidadPersonas int32,
	precioAplicado decimal.Decimal,
	fechaEntrada time.Time,
	fechaSalida time.Time,
	iva decimal.Decimal,
	subTotal decimal.Decimal,
	total decimal.Decimal,
) (CrearDetalleReservaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_DetalleReserva_Crear
			@idHabitacion = @IDHabitacion,
			@idReserva = @IDReserva,
			@idTarifa = @IDTarifa,
			@cantidadPersonas = @CantidadPersonas,
			@precioAplicado = @PrecioAplicado,
			@fechaEntrada = @FechaEntrada,
			@fechaSalida = @FechaSalida,
			@iva = @Iva,
			@subTotal = @SubTotal,
			@total = @Total
	`

	var resultado CrearDetalleReservaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDHabitacion", idHabitacion),
		sql.Named("IDReserva", idReserva),
		sql.Named("IDTarifa", idTarifa),
		sql.Named("CantidadPersonas", cantidadPersonas),
		sql.Named("PrecioAplicado", precioAplicado),
		sql.Named("FechaEntrada", fechaEntrada),
		sql.Named("FechaSalida", fechaSalida),
		sql.Named("Iva", iva),
		sql.Named("SubTotal", subTotal),
		sql.Named("Total", total),
	).Scan(
		&resultado.IDDetalleReserva,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *DetalleReservaRepository) Listar(
	ctx context.Context,
) ([]models.DetalleReserva, error) {

	const consulta = `
		SELECT
			idDetalleReserva,
			nombreTipoHabitacion,
			numeroHabitacion,
			nombreRecepcionista,
			nombreCliente,
			nombreTipoCliente,
			fechaReserva,
			estadoReserva,
			nombreTarifa,
			cantidadPersonas,
			precioAplicado,
			fechaEntrada,
			fechaSalida,
			iva,
			subTotal,
			total,
			estado
		FROM dbo.vw_DetalleReserva_Detalle
		ORDER BY idDetalleReserva
	`

	rows, err := r.db.QueryContext(ctx, consulta)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	detalles := make([]models.DetalleReserva, 0)

	for rows.Next() {
		var detalle models.DetalleReserva

		if err := rows.Scan(
			&detalle.IDDetalleReserva,
			&detalle.NombreTipoHabitacion,
			&detalle.NumeroHabitacion,
			&detalle.NombreRecepcionista,
			&detalle.NombreCliente,
			&detalle.NombreTipoCliente,
			&detalle.FechaReserva,
			&detalle.EstadoReserva,
			&detalle.NombreTarifa,
			&detalle.CantidadPersonas,
			&detalle.PrecioAplicado,
			&detalle.FechaEntrada,
			&detalle.FechaSalida,
			&detalle.Iva,
			&detalle.SubTotal,
			&detalle.Total,
			&detalle.Estado,
		); err != nil {
			return nil, err
		}

		detalles = append(detalles, detalle)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return detalles, nil
}

func (r *DetalleReservaRepository) ObtenerPorID(
	ctx context.Context,
	idDetalleReserva int32,
) (models.DetalleReserva, error) {

	const consulta = `
		SELECT
			idDetalleReserva,
			nombreTipoHabitacion,
			numeroHabitacion,
			nombreRecepcionista,
			nombreCliente,
			nombreTipoCliente,
			fechaReserva,
			estadoReserva,
			nombreTarifa,
			cantidadPersonas,
			precioAplicado,
			fechaEntrada,
			fechaSalida,
			iva,
			subTotal,
			total,
			estado
		FROM dbo.vw_DetalleReserva_Detalle
		WHERE idDetalleReserva = @IDDetalleReserva
	`

	var detalle models.DetalleReserva

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDDetalleReserva", idDetalleReserva),
	).Scan(
		&detalle.IDDetalleReserva,
		&detalle.NombreTipoHabitacion,
		&detalle.NumeroHabitacion,
		&detalle.NombreRecepcionista,
		&detalle.NombreCliente,
		&detalle.NombreTipoCliente,
		&detalle.FechaReserva,
		&detalle.EstadoReserva,
		&detalle.NombreTarifa,
		&detalle.CantidadPersonas,
		&detalle.PrecioAplicado,
		&detalle.FechaEntrada,
		&detalle.FechaSalida,
		&detalle.Iva,
		&detalle.SubTotal,
		&detalle.Total,
		&detalle.Estado,
	)

	return detalle, err
}

func (r *DetalleReservaRepository) ListarPorReserva(
	ctx context.Context,
	idReserva int32,
) ([]models.DetalleReservaPorReserva, error) {

	const consulta = `
		SELECT
			idDetalleReserva,
			nombreTipoHabitacion,
			numeroHabitacion,
			nombreTarifa,
			descuentoBase,
			cantidadPersonas,
			precioAplicado,
			fechaEntrada,
			fechaSalida,
			iva,
			subTotal,
			total,
			estado
		FROM dbo.vw_DetalleReserva_Detalle
		WHERE idReserva = @IDReserva
		  AND estado = 1
		ORDER BY idDetalleReserva
	`

	rows, err := r.db.QueryContext(
		ctx,
		consulta,
		sql.Named("IDReserva", idReserva),
	)

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	detalles := make([]models.DetalleReservaPorReserva, 0)

	for rows.Next() {
		var detalle models.DetalleReservaPorReserva

		if err := rows.Scan(
			&detalle.IDDetalleReserva,
			&detalle.NombreTipoHabitacion,
			&detalle.NumeroHabitacion,
			&detalle.NombreTarifa,
			&detalle.DescuentoBase,
			&detalle.CantidadPersonas,
			&detalle.PrecioAplicado,
			&detalle.FechaEntrada,
			&detalle.FechaSalida,
			&detalle.Iva,
			&detalle.SubTotal,
			&detalle.Total,
			&detalle.Estado,
		); err != nil {
			return nil, err
		}

		detalles = append(detalles, detalle)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return detalles, nil
}

func (r *DetalleReservaRepository) ObtenerTipoHabitacion(
	ctx context.Context,
	idHabitacion int32,
) (int32, error) {

	const consulta = `
		SELECT idTipoHab
		FROM dbo.habitacion
		WHERE idHabitacion = @IDHabitacion
		  AND estado = 1
	`

	var idTipoHabitacion int32

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDHabitacion", idHabitacion),
	).Scan(
		&idTipoHabitacion,
	)

	return idTipoHabitacion, err
}

func (r *DetalleReservaRepository) ObtenerTarifaActiva(
	ctx context.Context,
	idTipoHabitacion int32,
	fecha time.Time,
) (models.TarifaActivaDetalle, error) {

	const consulta = `
		SELECT TOP 1
			idTarifa,
			precioBase,
			nombreTarifa
		FROM dbo.tarifa
		WHERE idTipoHabitacion = @IDTipoHabitacion
		  AND estado = 1
		  AND (
				(fechaInicio IS NULL AND fechaFin IS NULL)
				OR
				(CAST(@Fecha AS DATE) BETWEEN fechaInicio AND fechaFin)
		  )
		ORDER BY
			CASE
				WHEN fechaInicio IS NOT NULL
				 AND fechaFin IS NOT NULL THEN 1
				ELSE 2
			END
	`

	var tarifa models.TarifaActivaDetalle

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDTipoHabitacion", idTipoHabitacion),
		sql.Named("Fecha", fecha),
	).Scan(
		&tarifa.IDTarifa,
		&tarifa.PrecioBase,
		&tarifa.NombreTarifa,
	)

	return tarifa, err
}

func (r *DetalleReservaRepository) ObtenerDescuentoCliente(
	ctx context.Context,
	idReserva int32,
) (decimal.Decimal, error) {

	const consulta = `
		SELECT
			tc.descuentoBase
		FROM dbo.reserva AS r
		INNER JOIN dbo.cliente AS c
			ON r.idCliente = c.cedula
		INNER JOIN dbo.tipocliente AS tc
			ON c.idTipoCliente = tc.idTipoCliente
		WHERE r.idReserva = @IDReserva
	`

	var descuento decimal.Decimal

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDReserva", idReserva),
	).Scan(
		&descuento,
	)

	return descuento, err
}

func (r *DetalleReservaRepository) ContarTraslapes(
	ctx context.Context,
	idHabitacion int32,
	fechaEntrada time.Time,
	fechaSalida time.Time,
) (int64, error) {

	const consulta = `
		SELECT COUNT(*)
		FROM dbo.detallereserva
		WHERE idHabitacion = @IDHabitacion
		  AND fechaEntrada < @FechaSalida
		  AND fechaSalida > @FechaEntrada
	`

	var cantidad int64

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDHabitacion", idHabitacion),
		sql.Named("FechaEntrada", fechaEntrada),
		sql.Named("FechaSalida", fechaSalida),
	).Scan(
		&cantidad,
	)

	return cantidad, err
}

func (r *DetalleReservaRepository) ContarTraslapesActualizacion(
	ctx context.Context,
	idHabitacion int32,
	idDetalleReserva int32,
	fechaEntrada time.Time,
	fechaSalida time.Time,
) (int64, error) {

	const consulta = `
		SELECT COUNT(*)
		FROM dbo.detallereserva
		WHERE idHabitacion = @IDHabitacion
		  AND idDetalleReserva <> @IDDetalleReserva
		  AND fechaEntrada < @FechaSalida
		  AND fechaSalida > @FechaEntrada
	`

	var cantidad int64

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDHabitacion", idHabitacion),
		sql.Named("IDDetalleReserva", idDetalleReserva),
		sql.Named("FechaEntrada", fechaEntrada),
		sql.Named("FechaSalida", fechaSalida),
	).Scan(
		&cantidad,
	)

	return cantidad, err
}

func (r *DetalleReservaRepository) ObtenerFechas(
	ctx context.Context,
	idDetalleReserva int32,
) (models.FechasDetalleReserva, error) {

	const consulta = `
		SELECT
			fechaEntrada,
			fechaSalida
		FROM dbo.detallereserva
		WHERE idDetalleReserva = @IDDetalleReserva
		  AND estado = 1
	`

	var fechas models.FechasDetalleReserva

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDDetalleReserva", idDetalleReserva),
	).Scan(
		&fechas.FechaEntrada,
		&fechas.FechaSalida,
	)

	return fechas, err
}

func (r *DetalleReservaRepository) ObtenerIDReserva(
	ctx context.Context,
	idDetalleReserva int32,
) (int32, error) {

	const consulta = `
		SELECT idReserva
		FROM dbo.detallereserva
		WHERE idDetalleReserva = @IDDetalleReserva
		  AND estado = 1
	`

	var idReserva int32

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDDetalleReserva", idDetalleReserva),
	).Scan(
		&idReserva,
	)

	return idReserva, err
}

func (r *DetalleReservaRepository) Actualizar(
	ctx context.Context,
	idDetalleReserva int32,
	idHabitacion int32,
	idTarifa int32,
	cantidadPersonas int32,
	precioAplicado decimal.Decimal,
	fechaEntrada *time.Time,
	fechaSalida *time.Time,
	iva decimal.Decimal,
	subTotal decimal.Decimal,
	total decimal.Decimal,
) (ActualizarDetalleReservaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_DetalleReserva_Actualizar
			@idDetalleReserva = @IDDetalleReserva,
			@idHabitacion = @IDHabitacion,
			@idTarifa = @IDTarifa,
			@cantidadPersonas = @CantidadPersonas,
			@precioAplicado = @PrecioAplicado,
			@fechaEntrada = @FechaEntrada,
			@fechaSalida = @FechaSalida,
			@iva = @Iva,
			@subTotal = @SubTotal,
			@total = @Total
	`

	var fechaEntradaParam any
	var fechaSalidaParam any

	if fechaEntrada != nil {
		fechaEntradaParam = *fechaEntrada
	}

	if fechaSalida != nil {
		fechaSalidaParam = *fechaSalida
	}

	var resultado ActualizarDetalleReservaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDDetalleReserva", idDetalleReserva),
		sql.Named("IDHabitacion", idHabitacion),
		sql.Named("IDTarifa", idTarifa),
		sql.Named("CantidadPersonas", cantidadPersonas),
		sql.Named("PrecioAplicado", precioAplicado),
		sql.Named("FechaEntrada", fechaEntradaParam),
		sql.Named("FechaSalida", fechaSalidaParam),
		sql.Named("Iva", iva),
		sql.Named("SubTotal", subTotal),
		sql.Named("Total", total),
	).Scan(
		&resultado.IDDetalleReserva,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *DetalleReservaRepository) ToggleEstado(
	ctx context.Context,
	idDetalleReserva int32,
) (ToggleDetalleReservaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_DetalleReserva_ToggleEstado
			@idDetalleReserva = @IDDetalleReserva
	`

	var resultado ToggleDetalleReservaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDDetalleReserva", idDetalleReserva),
	).Scan(
		&resultado.IDDetalleReserva,
		&resultado.Estado,
		&resultado.FilasAfectadas,
	)

	return resultado, err
}

func (r *DetalleReservaRepository) ObtenerFechasOcupadas(
	ctx context.Context,
	idHabitacion int32,
) ([]models.FechasDetalleReserva, error) {

	const consulta = `
		SELECT
			fechaEntrada,
			fechaSalida
		FROM dbo.detallereserva
		WHERE idHabitacion = @IDHabitacion
		  AND estado = 1
		ORDER BY fechaEntrada
	`

	rows, err := r.db.QueryContext(
		ctx,
		consulta,
		sql.Named("IDHabitacion", idHabitacion),
	)

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	fechas := make([]models.FechasDetalleReserva, 0)

	for rows.Next() {
		var fecha models.FechasDetalleReserva

		if err := rows.Scan(
			&fecha.FechaEntrada,
			&fecha.FechaSalida,
		); err != nil {
			return nil, err
		}

		fechas = append(fechas, fecha)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return fechas, nil
}
