package repository

import (
	"context"
	"database/sql"

	"reserva-backend/models"
)

type ClienteRepository struct {
	db *sql.DB
}

func NewClienteRepository(
	db *sql.DB,
) *ClienteRepository {
	return &ClienteRepository{
		db: db,
	}
}

type CrearClienteResultado struct {
	Cedula  string
	Mensaje string
}

type ActualizarClienteResultado struct {
	Cedula         string
	FilasAfectadas int32
	Mensaje        string
}

type CambiarEstadoClienteResultado struct {
	Cedula  string
	Estado  int8
	Mensaje string
}

func (r *ClienteRepository) Listar(
	ctx context.Context,
) ([]models.Cliente, error) {

	const consulta = `
		SELECT
			cedula,
			idTipoCliente,
			nombreTipoC,
			nombre,
			apellidos,
			telefono,
			direccion,
			estado
		FROM dbo.vw_Cliente_Detalle
		ORDER BY nombre, apellidos
	`

	rows, err := r.db.QueryContext(
		ctx,
		consulta,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	clientes := make([]models.Cliente, 0)

	for rows.Next() {
		var cliente models.Cliente

		if err := rows.Scan(
			&cliente.Cedula,
			&cliente.IDTipoCliente,
			&cliente.NombreTipoC,
			&cliente.Nombre,
			&cliente.Apellidos,
			&cliente.Telefono,
			&cliente.Direccion,
			&cliente.Estado,
		); err != nil {
			return nil, err
		}

		clientes = append(clientes, cliente)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return clientes, nil
}

func (r *ClienteRepository) ObtenerPorCedula(
	ctx context.Context,
	cedula string,
) (models.Cliente, error) {

	const consulta = `
		SELECT
			cedula,
			idTipoCliente,
			nombreTipoC,
			nombre,
			apellidos,
			telefono,
			direccion,
			estado
		FROM dbo.vw_Cliente_Detalle
		WHERE cedula = @Cedula
	`

	var cliente models.Cliente

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("Cedula", cedula),
	).Scan(
		&cliente.Cedula,
		&cliente.IDTipoCliente,
		&cliente.NombreTipoC,
		&cliente.Nombre,
		&cliente.Apellidos,
		&cliente.Telefono,
		&cliente.Direccion,
		&cliente.Estado,
	)

	return cliente, err
}

func (r *ClienteRepository) ListarPorTipo(
	ctx context.Context,
	idTipoCliente int32,
) ([]models.Cliente, error) {

	const consulta = `
		SELECT
			cedula,
			idTipoCliente,
			nombreTipoC,
			nombre,
			apellidos,
			telefono,
			direccion,
			estado
		FROM dbo.vw_Cliente_Detalle
		WHERE idTipoCliente = @IDTipoCliente
		ORDER BY nombre, apellidos
	`

	rows, err := r.db.QueryContext(
		ctx,
		consulta,
		sql.Named("IDTipoCliente", idTipoCliente),
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	clientes := make([]models.Cliente, 0)

	for rows.Next() {
		var cliente models.Cliente

		if err := rows.Scan(
			&cliente.Cedula,
			&cliente.IDTipoCliente,
			&cliente.NombreTipoC,
			&cliente.Nombre,
			&cliente.Apellidos,
			&cliente.Telefono,
			&cliente.Direccion,
			&cliente.Estado,
		); err != nil {
			return nil, err
		}

		clientes = append(clientes, cliente)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return clientes, nil
}

func (r *ClienteRepository) Buscar(
	ctx context.Context,
	busqueda string,
) ([]models.Cliente, error) {

	const consulta = `
		SELECT
			cedula,
			idTipoCliente,
			nombreTipoC,
			nombre,
			apellidos,
			telefono,
			direccion,
			estado
		FROM dbo.vw_Cliente_Detalle
		WHERE
			cedula LIKE @Busqueda + '%'
			OR nombre LIKE @Busqueda + '%'
			OR apellidos LIKE @Busqueda + '%'
			OR telefono LIKE @Busqueda + '%'
			OR direccion LIKE @Busqueda + '%'
			OR nombreTipoC LIKE @Busqueda + '%'
		ORDER BY nombre, apellidos
	`

	rows, err := r.db.QueryContext(
		ctx,
		consulta,
		sql.Named("Busqueda", busqueda),
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	clientes := make([]models.Cliente, 0)

	for rows.Next() {
		var cliente models.Cliente

		if err := rows.Scan(
			&cliente.Cedula,
			&cliente.IDTipoCliente,
			&cliente.NombreTipoC,
			&cliente.Nombre,
			&cliente.Apellidos,
			&cliente.Telefono,
			&cliente.Direccion,
			&cliente.Estado,
		); err != nil {
			return nil, err
		}

		clientes = append(clientes, cliente)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return clientes, nil
}

func (r *ClienteRepository) Crear(
	ctx context.Context,
	cedula string,
	idTipoCliente int32,
	nombre string,
	apellidos string,
	telefono string,
	direccion string,
) (CrearClienteResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Cliente_Crear
			@cedula = @Cedula,
			@idTipoCliente = @IDTipoCliente,
			@nombre = @Nombre,
			@apellidos = @Apellidos,
			@telefono = @Telefono,
			@direccion = @Direccion
	`

	var resultado CrearClienteResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("Cedula", cedula),
		sql.Named("IDTipoCliente", idTipoCliente),
		sql.Named("Nombre", nombre),
		sql.Named("Apellidos", apellidos),
		sql.Named("Telefono", telefono),
		sql.Named("Direccion", direccion),
	).Scan(
		&resultado.Cedula,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *ClienteRepository) Actualizar(
	ctx context.Context,
	cedula string,
	idTipoCliente int32,
	nombre string,
	apellidos string,
	telefono string,
	direccion string,
	estado int8,
) (ActualizarClienteResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Cliente_Actualizar
			@cedula = @Cedula,
			@idTipoCliente = @IDTipoCliente,
			@nombre = @Nombre,
			@apellidos = @Apellidos,
			@telefono = @Telefono,
			@direccion = @Direccion,
			@estado = @Estado
	`

	var resultado ActualizarClienteResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("Cedula", cedula),
		sql.Named("IDTipoCliente", idTipoCliente),
		sql.Named("Nombre", nombre),
		sql.Named("Apellidos", apellidos),
		sql.Named("Telefono", telefono),
		sql.Named("Direccion", direccion),
		sql.Named("Estado", estado),
	).Scan(
		&resultado.Cedula,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *ClienteRepository) Eliminar(
	ctx context.Context,
	cedula string,
) (CambiarEstadoClienteResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Cliente_CambiarEstado
			@cedula = @Cedula,
			@nuevoEstado = 0
	`

	var resultado CambiarEstadoClienteResultado

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

func (r *ClienteRepository) ToggleEstado(
	ctx context.Context,
	cedula string,
) (CambiarEstadoClienteResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Cliente_CambiarEstado
			@cedula = @Cedula,
			@nuevoEstado = @NuevoEstado
	`

	var resultado CambiarEstadoClienteResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("Cedula", cedula),
		sql.Named("NuevoEstado", nil),
	).Scan(
		&resultado.Cedula,
		&resultado.Estado,
		&resultado.Mensaje,
	)

	return resultado, err
}
