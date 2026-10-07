package repository

import (
	"context"
	"database/sql"
	"time"

	"reserva-backend/models"

	"github.com/shopspring/decimal"
)

type ReservaRepository struct {
	db *sql.DB
}

func NewReservaRepository(
	db *sql.DB,
) *ReservaRepository {
	return &ReservaRepository{
		db: db,
	}
}

type CrearReservaResultado struct {
	IDReserva int32
	Mensaje   string
}

type ActualizarReservaResultado struct {
	IDReserva      int32
	FilasAfectadas int32
	Mensaje        string
}

type ToggleReservaResultado struct {
	IDReserva int32
	Estado    int8
	Mensaje   string
}

type ActualizarEstadoReservaResultado struct {
	IDReserva      int32
	FilasAfectadas int32
	Mensaje        string
}

func (r *ReservaRepository) Listar(
	ctx context.Context,
) ([]models.Reserva, error) {

	const consulta = `
		SELECT
			idReserva,
			idRecepcionista,
			idCliente,
			nombreCliente,
			nombreRecepcionista,
			fechaReserva,
			estadoReserva,
			estado,
			iva,
			subTotal,
			total
		FROM dbo.vw_Reserva_Detalle
		WHERE estado = 1
		ORDER BY idReserva
	`

	rows, err := r.db.QueryContext(ctx, consulta)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	reservas := make([]models.Reserva, 0)

	for rows.Next() {
		var reserva models.Reserva

		if err := rows.Scan(
			&reserva.IDReserva,
			&reserva.IDRecepcionista,
			&reserva.IDCliente,
			&reserva.NombreCliente,
			&reserva.NombreRecepcionista,
			&reserva.FechaReserva,
			&reserva.EstadoReserva,
			&reserva.Estado,
			&reserva.Iva,
			&reserva.SubTotal,
			&reserva.Total,
		); err != nil {
			return nil, err
		}

		reservas = append(reservas, reserva)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return reservas, nil
}

func (r *ReservaRepository) ObtenerPorID(
	ctx context.Context,
	idReserva int32,
) (models.Reserva, error) {

	const consulta = `
		SELECT
			idReserva,
			idRecepcionista,
			idCliente,
			nombreCliente,
			nombreRecepcionista,
			fechaReserva,
			estadoReserva,
			estado,
			iva,
			subTotal,
			total
		FROM dbo.vw_Reserva_Detalle
		WHERE idReserva = @IDReserva
		  AND estado = 1
	`

	var reserva models.Reserva

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDReserva", idReserva),
	).Scan(
		&reserva.IDReserva,
		&reserva.IDRecepcionista,
		&reserva.IDCliente,
		&reserva.NombreCliente,
		&reserva.NombreRecepcionista,
		&reserva.FechaReserva,
		&reserva.EstadoReserva,
		&reserva.Estado,
		&reserva.Iva,
		&reserva.SubTotal,
		&reserva.Total,
	)

	return reserva, err
}

func (r *ReservaRepository) ListarPorCliente(
	ctx context.Context,
	idCliente string,
) ([]models.Reserva, error) {

	const consulta = `
		SELECT
			idReserva,
			idRecepcionista,
			idCliente,
			nombreCliente,
			nombreRecepcionista,
			fechaReserva,
			estadoReserva,
			estado,
			iva,
			subTotal,
			total
		FROM dbo.vw_Reserva_Detalle
		WHERE idCliente = @IDCliente
		  AND estado = 1
		ORDER BY idReserva
	`

	rows, err := r.db.QueryContext(
		ctx,
		consulta,
		sql.Named("IDCliente", idCliente),
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	reservas := make([]models.Reserva, 0)

	for rows.Next() {
		var reserva models.Reserva

		if err := rows.Scan(
			&reserva.IDReserva,
			&reserva.IDRecepcionista,
			&reserva.IDCliente,
			&reserva.NombreCliente,
			&reserva.NombreRecepcionista,
			&reserva.FechaReserva,
			&reserva.EstadoReserva,
			&reserva.Estado,
			&reserva.Iva,
			&reserva.SubTotal,
			&reserva.Total,
		); err != nil {
			return nil, err
		}

		reservas = append(reservas, reserva)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return reservas, nil
}

func (r *ReservaRepository) ListarPorRecepcionista(
	ctx context.Context,
	idRecepcionista string,
) ([]models.Reserva, error) {

	const consulta = `
		SELECT
			idReserva,
			idRecepcionista,
			idCliente,
			nombreCliente,
			nombreRecepcionista,
			fechaReserva,
			estadoReserva,
			estado,
			iva,
			subTotal,
			total
		FROM dbo.vw_Reserva_Detalle
		WHERE idRecepcionista = @IDRecepcionista
		  AND estado = 1
		ORDER BY idReserva
	`

	rows, err := r.db.QueryContext(
		ctx,
		consulta,
		sql.Named("IDRecepcionista", idRecepcionista),
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	reservas := make([]models.Reserva, 0)

	for rows.Next() {
		var reserva models.Reserva

		if err := rows.Scan(
			&reserva.IDReserva,
			&reserva.IDRecepcionista,
			&reserva.IDCliente,
			&reserva.NombreCliente,
			&reserva.NombreRecepcionista,
			&reserva.FechaReserva,
			&reserva.EstadoReserva,
			&reserva.Estado,
			&reserva.Iva,
			&reserva.SubTotal,
			&reserva.Total,
		); err != nil {
			return nil, err
		}

		reservas = append(reservas, reserva)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return reservas, nil
}

func (r *ReservaRepository) Crear(
	ctx context.Context,
	idRecepcionista string,
	idCliente string,
	fechaReserva time.Time,
	estadoReserva string,
	iva decimal.Decimal,
	subTotal decimal.Decimal,
	total decimal.Decimal,
) (CrearReservaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Reserva_Crear
			@idRecepcionista = @IDRecepcionista,
			@idCliente = @IDCliente,
			@fechaReserva = @FechaReserva,
			@estadoReserva = @EstadoReserva,
			@iva = @Iva,
			@subTotal = @SubTotal,
			@total = @Total
	`

	var resultado CrearReservaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDRecepcionista", idRecepcionista),
		sql.Named("IDCliente", idCliente),
		sql.Named("FechaReserva", fechaReserva),
		sql.Named("EstadoReserva", estadoReserva),
		sql.Named("Iva", iva),
		sql.Named("SubTotal", subTotal),
		sql.Named("Total", total),
	).Scan(
		&resultado.IDReserva,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *ReservaRepository) Actualizar(
	ctx context.Context,
	idReserva int32,
	idRecepcionista string,
	idCliente string,
	fechaReserva time.Time,
	estadoReserva string,
	estado int8,
	iva decimal.Decimal,
	subTotal decimal.Decimal,
	total decimal.Decimal,
) (ActualizarReservaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Reserva_Actualizar
			@idReserva = @IDReserva,
			@idRecepcionista = @IDRecepcionista,
			@idCliente = @IDCliente,
			@fechaReserva = @FechaReserva,
			@estadoReserva = @EstadoReserva,
			@estado = @Estado,
			@iva = @Iva,
			@subTotal = @SubTotal,
			@total = @Total
	`

	var resultado ActualizarReservaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDReserva", idReserva),
		sql.Named("IDRecepcionista", idRecepcionista),
		sql.Named("IDCliente", idCliente),
		sql.Named("FechaReserva", fechaReserva),
		sql.Named("EstadoReserva", estadoReserva),
		sql.Named("Estado", estado),
		sql.Named("Iva", iva),
		sql.Named("SubTotal", subTotal),
		sql.Named("Total", total),
	).Scan(
		&resultado.IDReserva,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *ReservaRepository) ToggleEstado(
	ctx context.Context,
	idReserva int32,
) (ToggleReservaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Reserva_ToggleEstado
			@idReserva = @IDReserva
	`

	var resultado ToggleReservaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDReserva", idReserva),
	).Scan(
		&resultado.IDReserva,
		&resultado.Estado,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *ReservaRepository) ActualizarEstadoReserva(
	ctx context.Context,
	idReserva int32,
	estadoReserva string,
) (ActualizarEstadoReservaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Reserva_ActualizarEstadoReserva
			@idReserva = @IDReserva,
			@estadoReserva = @EstadoReserva
	`

	var resultado ActualizarEstadoReservaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDReserva", idReserva),
		sql.Named("EstadoReserva", estadoReserva),
	).Scan(
		&resultado.IDReserva,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}
