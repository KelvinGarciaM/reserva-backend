package repository

import (
	"context"
	"database/sql"

	"reserva-backend/models"
)

type HabitacionRepository struct {
	db *sql.DB
}

func NewHabitacionRepository(
	db *sql.DB,
) *HabitacionRepository {
	return &HabitacionRepository{
		db: db,
	}
}

type CrearHabitacionResultado struct {
	IDHabitacion int32
	Mensaje      string
}

type ActualizarHabitacionResultado struct {
	IDHabitacion   int32
	FilasAfectadas int32
	Mensaje        string
}

type CambiarEstadoHabitacionResultado struct {
	IDHabitacion   int32
	Estado         int8
	FilasAfectadas int32
	Mensaje        string
}

func (r *HabitacionRepository) Listar(
	ctx context.Context,
) ([]models.Habitacion, error) {

	const consulta = `
		SELECT
			idHabitacion,
			idTipoHab,
			nombreTipoHab,
			numeroHabitacion,
			estado
		FROM dbo.vw_Habitacion_Detalle
		ORDER BY numeroHabitacion
	`

	rows, err := r.db.QueryContext(ctx, consulta)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	habitaciones := make([]models.Habitacion, 0)

	for rows.Next() {
		var habitacion models.Habitacion

		if err := rows.Scan(
			&habitacion.IDHabitacion,
			&habitacion.IDTipoHab,
			&habitacion.NombreTipoHab,
			&habitacion.NumeroHabitacion,
			&habitacion.Estado,
		); err != nil {
			return nil, err
		}

		habitaciones = append(habitaciones, habitacion)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return habitaciones, nil
}

func (r *HabitacionRepository) ObtenerPorID(
	ctx context.Context,
	id int32,
) (models.Habitacion, error) {

	const consulta = `
		SELECT
			idHabitacion,
			idTipoHab,
			nombreTipoHab,
			numeroHabitacion,
			estado
		FROM dbo.vw_Habitacion_Detalle
		WHERE idHabitacion = @IDHabitacion
	`

	var habitacion models.Habitacion

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDHabitacion", id),
	).Scan(
		&habitacion.IDHabitacion,
		&habitacion.IDTipoHab,
		&habitacion.NombreTipoHab,
		&habitacion.NumeroHabitacion,
		&habitacion.Estado,
	)

	return habitacion, err
}

func (r *HabitacionRepository) ListarPorTipo(
	ctx context.Context,
	idTipoHab int32,
) ([]models.Habitacion, error) {

	const consulta = `
		SELECT
			idHabitacion,
			idTipoHab,
			nombreTipoHab,
			numeroHabitacion,
			estado
		FROM dbo.vw_Habitacion_Detalle
		WHERE idTipoHab = @IDTipoHab
		ORDER BY numeroHabitacion
	`

	rows, err := r.db.QueryContext(
		ctx,
		consulta,
		sql.Named("IDTipoHab", idTipoHab),
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	habitaciones := make([]models.Habitacion, 0)

	for rows.Next() {
		var habitacion models.Habitacion

		if err := rows.Scan(
			&habitacion.IDHabitacion,
			&habitacion.IDTipoHab,
			&habitacion.NombreTipoHab,
			&habitacion.NumeroHabitacion,
			&habitacion.Estado,
		); err != nil {
			return nil, err
		}

		habitaciones = append(habitaciones, habitacion)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return habitaciones, nil
}

func (r *HabitacionRepository) Crear(
	ctx context.Context,
	idTipoHab int32,
	numeroHabitacion string,
) (CrearHabitacionResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Habitacion_Crear
			@idTipoHab = @IDTipoHab,
			@numeroHabitacion = @NumeroHabitacion
	`

	var resultado CrearHabitacionResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTipoHab", idTipoHab),
		sql.Named("NumeroHabitacion", numeroHabitacion),
	).Scan(
		&resultado.IDHabitacion,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *HabitacionRepository) Actualizar(
	ctx context.Context,
	idHabitacion int32,
	idTipoHab int32,
	numeroHabitacion string,
	estado int8,
) (ActualizarHabitacionResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Habitacion_Actualizar
			@idHabitacion = @IDHabitacion,
			@idTipoHab = @IDTipoHab,
			@numeroHabitacion = @NumeroHabitacion,
			@estado = @Estado
	`

	var resultado ActualizarHabitacionResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDHabitacion", idHabitacion),
		sql.Named("IDTipoHab", idTipoHab),
		sql.Named("NumeroHabitacion", numeroHabitacion),
		sql.Named("Estado", estado),
	).Scan(
		&resultado.IDHabitacion,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *HabitacionRepository) Eliminar(
	ctx context.Context,
	idHabitacion int32,
) (CambiarEstadoHabitacionResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Habitacion_CambiarEstado
			@idHabitacion = @IDHabitacion,
			@nuevoEstado = 0
	`

	var resultado CambiarEstadoHabitacionResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDHabitacion", idHabitacion),
	).Scan(
		&resultado.IDHabitacion,
		&resultado.Estado,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *HabitacionRepository) ListarDisponibles(
	ctx context.Context,
) ([]models.HabitacionDisponible, error) {

	const consulta = `
		SELECT
			h.idHabitacion,
			h.numeroHabitacion,
			th.nombreTipoHab,
			t.idTarifa,
			t.nombreTarifa,
			t.precioBase,
			th.capacidadMaxima
		FROM dbo.habitacion AS h
		INNER JOIN dbo.tipohabitacion AS th
			ON h.idTipoHab = th.idTipoHabitacion
		INNER JOIN dbo.tarifa AS t
			ON th.idTipoHabitacion = t.idTipoHabitacion
		WHERE h.estado = 1
		  AND th.estado = 1
		  AND t.estado = 1
		  AND t.desactivadaManual = 0
		  AND CAST(GETDATE() AS DATE)
			  BETWEEN t.fechaInicio AND t.fechaFin
		ORDER BY h.numeroHabitacion
	`

	rows, err := r.db.QueryContext(ctx, consulta)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	habitaciones := make([]models.HabitacionDisponible, 0)

	for rows.Next() {
		var habitacion models.HabitacionDisponible

		if err := rows.Scan(
			&habitacion.IDHabitacion,
			&habitacion.NumeroHabitacion,
			&habitacion.NombreTipoHab,
			&habitacion.IDTarifa,
			&habitacion.NombreTarifa,
			&habitacion.PrecioBase,
			&habitacion.CapacidadMaxima,
		); err != nil {
			return nil, err
		}

		habitaciones = append(habitaciones, habitacion)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return habitaciones, nil
}
