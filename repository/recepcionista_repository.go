package repository

import (
	"context"
	"database/sql"

	"reserva-backend/models"
)

type RecepcionistaRepository struct {
	db *sql.DB
}

func NewRecepcionistaRepository(
	db *sql.DB,
) *RecepcionistaRepository {
	return &RecepcionistaRepository{
		db: db,
	}
}

type CrearRecepcionistaResultado struct {
	Cedula  string
	Mensaje string
}

type ActualizarRecepcionistaResultado struct {
	Cedula         string
	FilasAfectadas int32
	Mensaje        string
}

type EliminarRecepcionistaResultado struct {
	Cedula         string
	FilasAfectadas int32
	Mensaje        string
}

type ToggleRecepcionistaResultado struct {
	Cedula  string
	Estado  int8
	Mensaje string
}

func (r *RecepcionistaRepository) Listar(
	ctx context.Context,
	soloActivos *int8,
) ([]models.Recepcionista, error) {

	var filtro any

	if soloActivos != nil {
		filtro = *soloActivos
	}

	const procedimiento = `
		EXEC dbo.pa_Recepcionista_Listar
			@soloActivos = @SoloActivos
	`

	rows, err := r.db.QueryContext(
		ctx,
		procedimiento,
		sql.Named("SoloActivos", filtro),
	)

	if err != nil {
		return nil, err
	}

	defer rows.Close()

	recepcionistas := make([]models.Recepcionista, 0)

	for rows.Next() {

		var recepcionista models.Recepcionista

		err := rows.Scan(
			&recepcionista.Cedula,
			&recepcionista.Nombre,
			&recepcionista.Apellidos,
			&recepcionista.Telefono,
			&recepcionista.Correo,
			&recepcionista.Estado,
		)

		if err != nil {
			return nil, err
		}

		recepcionistas = append(
			recepcionistas,
			recepcionista,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return recepcionistas, nil
}

func (r *RecepcionistaRepository) ObtenerPorCedula(
	ctx context.Context,
	cedula string,
) (models.Recepcionista, error) {

	const procedimiento = `
		EXEC dbo.pa_Recepcionista_ObtenerPorCedula
			@cedula = @Cedula
	`

	var recepcionista models.Recepcionista

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("Cedula", cedula),
	).Scan(
		&recepcionista.Cedula,
		&recepcionista.Nombre,
		&recepcionista.Apellidos,
		&recepcionista.Telefono,
		&recepcionista.Correo,
		&recepcionista.Estado,
	)

	return recepcionista, err
}

func (r *RecepcionistaRepository) Crear(
	ctx context.Context,
	cedula string,
	nombre string,
	apellidos string,
	telefono string,
	correo string,
) (CrearRecepcionistaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Recepcionista_Crear
			@cedula = @Cedula,
			@nombre = @Nombre,
			@apellidos = @Apellidos,
			@telefono = @Telefono,
			@correo = @Correo
	`

	var resultado CrearRecepcionistaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("Cedula", cedula),
		sql.Named("Nombre", nombre),
		sql.Named("Apellidos", apellidos),
		sql.Named("Telefono", telefono),
		sql.Named("Correo", correo),
	).Scan(
		&resultado.Cedula,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *RecepcionistaRepository) Buscar(
	ctx context.Context,
	busqueda string,
) ([]models.Recepcionista, error) {

	const procedimiento = `
		EXEC dbo.pa_Recepcionista_Buscar
			@busqueda = @Busqueda
	`

	rows, err := r.db.QueryContext(
		ctx,
		procedimiento,
		sql.Named("Busqueda", busqueda),
	)

	if err != nil {
		return nil, err
	}

	defer rows.Close()

	recepcionistas := make([]models.Recepcionista, 0)

	for rows.Next() {

		var recepcionista models.Recepcionista

		err := rows.Scan(
			&recepcionista.Cedula,
			&recepcionista.Nombre,
			&recepcionista.Apellidos,
			&recepcionista.Telefono,
			&recepcionista.Correo,
			&recepcionista.Estado,
		)

		if err != nil {
			return nil, err
		}

		recepcionistas = append(
			recepcionistas,
			recepcionista,
		)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return recepcionistas, nil
}

func (r *RecepcionistaRepository) Actualizar(
	ctx context.Context,
	cedula string,
	nombre string,
	apellidos string,
	telefono string,
	correo string,
	estado int8,
) (ActualizarRecepcionistaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Recepcionista_Actualizar
			@cedula = @Cedula,
			@nombre = @Nombre,
			@apellidos = @Apellidos,
			@telefono = @Telefono,
			@correo = @Correo,
			@estado = @Estado
	`

	var resultado ActualizarRecepcionistaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("Cedula", cedula),
		sql.Named("Nombre", nombre),
		sql.Named("Apellidos", apellidos),
		sql.Named("Telefono", telefono),
		sql.Named("Correo", correo),
		sql.Named("Estado", estado),
	).Scan(
		&resultado.Cedula,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *RecepcionistaRepository) Eliminar(
	ctx context.Context,
	cedula string,
) (EliminarRecepcionistaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Recepcionista_Eliminar
			@cedula = @Cedula
	`

	var resultado EliminarRecepcionistaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("Cedula", cedula),
	).Scan(
		&resultado.Cedula,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *RecepcionistaRepository) ToggleEstado(
	ctx context.Context,
	cedula string,
) (ToggleRecepcionistaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Recepcionista_ToggleEstado
			@cedula = @Cedula
	`

	var resultado ToggleRecepcionistaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("Cedula", cedula),
	).Scan(
		&resultado.Cedula,
		&resultado.Estado,
		&resultado.Mensaje,
	)

	return resultado, err
}
