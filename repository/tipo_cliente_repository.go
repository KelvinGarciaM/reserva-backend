package repository

import (
	"context"
	"database/sql"

	"reserva-backend/models"
)

type TipoClienteRepository struct {
	db *sql.DB
}

func NewTipoClienteRepository(
	db *sql.DB,
) *TipoClienteRepository {
	return &TipoClienteRepository{
		db: db,
	}
}

type CrearTipoClienteResultado struct {
	IDTipoCliente int32
	Mensaje       string
}

type ActualizarTipoClienteResultado struct {
	IDTipoCliente  int32
	FilasAfectadas int32
	Mensaje        string
}

type EliminarTipoClienteResultado struct {
	IDTipoCliente  int32
	FilasAfectadas int32
	Mensaje        string
}

type ToggleTipoClienteResultado struct {
	IDTipoCliente int32
	Estado        int8
	Mensaje       string
}

func (r *TipoClienteRepository) Listar(
	ctx context.Context,
	soloActivos *int8,
) ([]models.TipoCliente, error) {

	var filtro any

	if soloActivos != nil {
		filtro = *soloActivos
	}

	const procedimiento = `
		EXEC dbo.pa_TipoCliente_Listar
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

	tipos := make([]models.TipoCliente, 0)

	for rows.Next() {
		var tipo models.TipoCliente

		if err := rows.Scan(
			&tipo.IDTipoCliente,
			&tipo.NombreTipoC,
			&tipo.Descripcion,
			&tipo.DescuentoBase,
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

func (r *TipoClienteRepository) ObtenerPorID(
	ctx context.Context,
	id int32,
) (models.TipoCliente, error) {

	const procedimiento = `
		EXEC dbo.pa_TipoCliente_ObtenerPorId
			@idTipoCliente = @IDTipoCliente
	`

	var tipo models.TipoCliente

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTipoCliente", id),
	).Scan(
		&tipo.IDTipoCliente,
		&tipo.NombreTipoC,
		&tipo.Descripcion,
		&tipo.DescuentoBase,
		&tipo.Estado,
	)

	return tipo, err
}

func (r *TipoClienteRepository) Crear(
	ctx context.Context,
	nombre string,
	descripcion string,
	descuentoBase float64,
) (CrearTipoClienteResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_TipoCliente_Crear
			@nombreTipoC = @NombreTipoC,
			@descripcion = @Descripcion,
			@descuentoBase = @DescuentoBase
	`

	var resultado CrearTipoClienteResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("NombreTipoC", nombre),
		sql.Named("Descripcion", descripcion),
		sql.Named("DescuentoBase", descuentoBase),
	).Scan(
		&resultado.IDTipoCliente,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *TipoClienteRepository) Actualizar(
	ctx context.Context,
	id int32,
	nombre string,
	descripcion string,
	descuentoBase float64,
	estado int8,
) (ActualizarTipoClienteResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_TipoCliente_Actualizar
			@idTipoCliente = @IDTipoCliente,
			@nombreTipoC = @NombreTipoC,
			@descripcion = @Descripcion,
			@descuentoBase = @DescuentoBase,
			@estado = @Estado
	`

	var resultado ActualizarTipoClienteResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTipoCliente", id),
		sql.Named("NombreTipoC", nombre),
		sql.Named("Descripcion", descripcion),
		sql.Named("DescuentoBase", descuentoBase),
		sql.Named("Estado", estado),
	).Scan(
		&resultado.IDTipoCliente,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *TipoClienteRepository) Eliminar(
	ctx context.Context,
	id int32,
) (EliminarTipoClienteResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_TipoCliente_Eliminar
			@idTipoCliente = @IDTipoCliente
	`

	var resultado EliminarTipoClienteResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTipoCliente", id),
	).Scan(
		&resultado.IDTipoCliente,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *TipoClienteRepository) Buscar(
	ctx context.Context,
	busqueda string,
) ([]models.TipoCliente, error) {

	const procedimiento = `
		EXEC dbo.pa_TipoCliente_Buscar
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

	tipos := make([]models.TipoCliente, 0)

	for rows.Next() {
		var tipo models.TipoCliente

		if err := rows.Scan(
			&tipo.IDTipoCliente,
			&tipo.NombreTipoC,
			&tipo.Descripcion,
			&tipo.DescuentoBase,
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

func (r *TipoClienteRepository) ToggleEstado(
	ctx context.Context,
	id int32,
) (ToggleTipoClienteResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_TipoCliente_ToggleEstado
			@idTipoCliente = @IDTipoCliente
	`

	var resultado ToggleTipoClienteResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTipoCliente", id),
	).Scan(
		&resultado.IDTipoCliente,
		&resultado.Estado,
		&resultado.Mensaje,
	)

	return resultado, err
}
