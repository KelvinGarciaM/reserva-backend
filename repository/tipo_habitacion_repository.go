package repository

import (
	"context"
	"database/sql"

	"reserva-backend/models"
)

type TipoHabitacionRepository struct {
	db *sql.DB
}

func NewTipoHabitacionRepository(
	db *sql.DB,
) *TipoHabitacionRepository {
	return &TipoHabitacionRepository{
		db: db,
	}
}

type CrearTipoHabitacionResultado struct {
	IDTipoHabitacion int32
	Mensaje          string
}

type ActualizarTipoHabitacionResultado struct {
	IDTipoHabitacion int32
	FilasAfectadas   int32
	Mensaje          string
}

type EliminarTipoHabitacionResultado struct {
	IDTipoHabitacion int32
	FilasAfectadas   int32
	Mensaje          string
}

// Listar ejecuta sp_TipoHabitacion_Listar.
// El filtro puede ser:
// nil = todos
// 1   = activos
// 0   = inactivos
func (r *TipoHabitacionRepository) Listar(
	ctx context.Context,
	soloActivos *int8,
) ([]models.TipoHabitacion, error) {

	var filtro any

	if soloActivos != nil {
		filtro = *soloActivos
	}

	const procedimiento = `
		EXEC dbo.sp_TipoHabitacion_Listar
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

	tipos := make([]models.TipoHabitacion, 0)

	for rows.Next() {
		var tipo models.TipoHabitacion

		if err := rows.Scan(
			&tipo.IDTipoHabitacion,
			&tipo.NombreTipoHab,
			&tipo.Descripcion,
			&tipo.CapacidadMaxima,
			&tipo.Estado,
		); err != nil {
			return nil, err
		}

		tipos = append(tipos, tipo)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return tipos, nil
}

// ObtenerPorID ejecuta sp_TipoHabitacion_ObtenerPorId.
func (r *TipoHabitacionRepository) ObtenerPorID(
	ctx context.Context,
	id int32,
) (models.TipoHabitacion, error) {

	const procedimiento = `
		EXEC dbo.sp_TipoHabitacion_ObtenerPorId
			@idTipoHabitacion = @IDTipoHabitacion
	`

	var tipo models.TipoHabitacion

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTipoHabitacion", id),
	).Scan(
		&tipo.IDTipoHabitacion,
		&tipo.NombreTipoHab,
		&tipo.Descripcion,
		&tipo.CapacidadMaxima,
		&tipo.Estado,
	)

	return tipo, err
}

// Crear ejecuta sp_TipoHabitacion_Crear.
func (r *TipoHabitacionRepository) Crear(
	ctx context.Context,
	nombre string,
	descripcion string,
	capacidadMaxima int32,
) (CrearTipoHabitacionResultado, error) {

	const procedimiento = `
		EXEC dbo.sp_TipoHabitacion_Crear
			@nombreTipoHab = @NombreTipoHab,
			@descripcion = @Descripcion,
			@capacidadMaxima = @CapacidadMaxima
	`

	var resultado CrearTipoHabitacionResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("NombreTipoHab", nombre),
		sql.Named("Descripcion", descripcion),
		sql.Named("CapacidadMaxima", capacidadMaxima),
	).Scan(
		&resultado.IDTipoHabitacion,
		&resultado.Mensaje,
	)

	return resultado, err
}

// Actualizar ejecuta sp_TipoHabitacion_Actualizar.
func (r *TipoHabitacionRepository) Actualizar(
	ctx context.Context,
	id int32,
	nombre string,
	descripcion string,
	capacidadMaxima int32,
	estado int8,
) (ActualizarTipoHabitacionResultado, error) {

	const procedimiento = `
		EXEC dbo.sp_TipoHabitacion_Actualizar
			@idTipoHabitacion = @IDTipoHabitacion,
			@nombreTipoHab = @NombreTipoHab,
			@descripcion = @Descripcion,
			@capacidadMaxima = @CapacidadMaxima,
			@estado = @Estado
	`

	var resultado ActualizarTipoHabitacionResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTipoHabitacion", id),
		sql.Named("NombreTipoHab", nombre),
		sql.Named("Descripcion", descripcion),
		sql.Named("CapacidadMaxima", capacidadMaxima),
		sql.Named("Estado", estado),
	).Scan(
		&resultado.IDTipoHabitacion,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

// Eliminar realiza eliminación lógica.
func (r *TipoHabitacionRepository) Eliminar(
	ctx context.Context,
	id int32,
) (EliminarTipoHabitacionResultado, error) {

	const procedimiento = `
		EXEC dbo.sp_TipoHabitacion_Eliminar
			@idTipoHabitacion = @IDTipoHabitacion
	`

	var resultado EliminarTipoHabitacionResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTipoHabitacion", id),
	).Scan(
		&resultado.IDTipoHabitacion,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}
