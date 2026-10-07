package repository

import (
	"context"
	"database/sql"
	"errors"
	"strings"

	"reserva-backend/models"
)

type UsuarioRepository struct {
	db *sql.DB
}

type CrearUsuarioResultado struct {
	ID      int32
	Mensaje string
}

type ActualizarUsuarioResultado struct {
	ID             int32
	FilasAfectadas int32
	Mensaje        string
}

type ToggleUsuarioResultado struct {
	ID      int32
	Estado  int8
	Mensaje string
}

func NewUsuarioRepository(
	db *sql.DB,
) *UsuarioRepository {
	return &UsuarioRepository{
		db: db,
	}
}

// ObtenerPorEmail busca un usuario activo.
// Se utiliza durante el login y al crear el administrador inicial.
func (r *UsuarioRepository) ObtenerPorEmail(
	ctx context.Context,
	email string,
) (models.UsuarioLogin, error) {

	email = strings.TrimSpace(email)

	if email == "" {
		return models.UsuarioLogin{},
			errors.New("el correo electrónico es obligatorio")
	}

	const consulta = `
		SELECT
			id,
			name,
			role,
			email,
			password,
			image,
			cedula,
			created_at,
			updated_at,
			estado
		FROM dbo.users
		WHERE LOWER(email) = LOWER(@Email)
		  AND estado = 1
	`

	var usuario models.UsuarioLogin

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("Email", email),
	).Scan(
		&usuario.ID,
		&usuario.Name,
		&usuario.Role,
		&usuario.Email,
		&usuario.Password,
		&usuario.Image,
		&usuario.Cedula,
		&usuario.CreatedAt,
		&usuario.UpdatedAt,
		&usuario.Estado,
	)

	return usuario, err
}

// CrearAdmin registra el administrador inicial.
// La contraseña recibida ya debe venir cifrada con bcrypt.
func (r *UsuarioRepository) CrearAdmin(
	ctx context.Context,
	nombre string,
	email string,
	passwordHash string,
	role string,
) error {

	nombre = strings.TrimSpace(nombre)
	email = strings.TrimSpace(email)
	role = strings.TrimSpace(role)

	if nombre == "" {
		return errors.New("el nombre del administrador es obligatorio")
	}

	if email == "" {
		return errors.New("el correo del administrador es obligatorio")
	}

	if passwordHash == "" {
		return errors.New("la contraseña cifrada es obligatoria")
	}

	if role == "" {
		return errors.New("el rol del administrador es obligatorio")
	}

	const consulta = `
		INSERT INTO dbo.users
		(
			name,
			email,
			password,
			role,
			estado,
			image,
			cedula
		)
		VALUES
		(
			@Name,
			@Email,
			@Password,
			@Role,
			1,
			NULL,
			NULL
		)
	`

	_, err := r.db.ExecContext(
		ctx,
		consulta,
		sql.Named("Name", nombre),
		sql.Named("Email", email),
		sql.Named("Password", passwordHash),
		sql.Named("Role", role),
	)

	return err
}

func (r *UsuarioRepository) Listar(
	ctx context.Context,
) ([]models.Usuario, error) {

	const consulta = `
		SELECT
			id,
			name,
			role,
			email,
			image,
			cedula,
			created_at,
			updated_at,
			estado
		FROM dbo.vw_Usuario_Detalle
		ORDER BY id
	`

	rows, err := r.db.QueryContext(ctx, consulta)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	usuarios := make([]models.Usuario, 0)

	for rows.Next() {
		var usuario models.Usuario

		if err := rows.Scan(
			&usuario.ID,
			&usuario.Name,
			&usuario.Role,
			&usuario.Email,
			&usuario.Image,
			&usuario.Cedula,
			&usuario.CreatedAt,
			&usuario.UpdatedAt,
			&usuario.Estado,
		); err != nil {
			return nil, err
		}

		usuarios = append(usuarios, usuario)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return usuarios, nil
}

func (r *UsuarioRepository) Crear(
	ctx context.Context,
	nombre string,
	email string,
	passwordHash string,
	role string,
	image string,
	cedula string,
) (CrearUsuarioResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Usuario_Crear
			@name = @Name,
			@email = @Email,
			@password = @Password,
			@role = @Role,
			@image = @Image,
			@cedula = @Cedula
	`

	var roleParam any
	var imageParam any
	var cedulaParam any

	if strings.TrimSpace(role) != "" {
		roleParam = role
	}

	if strings.TrimSpace(image) != "" {
		imageParam = image
	}

	if strings.TrimSpace(cedula) != "" {
		cedulaParam = cedula
	}

	var resultado CrearUsuarioResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("Name", nombre),
		sql.Named("Email", email),
		sql.Named("Password", passwordHash),
		sql.Named("Role", roleParam),
		sql.Named("Image", imageParam),
		sql.Named("Cedula", cedulaParam),
	).Scan(
		&resultado.ID,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *UsuarioRepository) Actualizar(
	ctx context.Context,
	id int32,
	nombre string,
	email string,
	role string,
	image string,
	cedula string,
	passwordHash *string,
	estado *int8,
) (ActualizarUsuarioResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Usuario_Actualizar
			@id = @ID,
			@name = @Name,
			@email = @Email,
			@role = @Role,
			@image = @Image,
			@cedula = @Cedula,
			@password = @Password,
			@estado = @Estado
	`

	var roleParam any
	var imageParam any
	var cedulaParam any
	var passwordParam any
	var estadoParam any

	if strings.TrimSpace(role) != "" {
		roleParam = role
	}

	if strings.TrimSpace(image) != "" {
		imageParam = image
	}

	if strings.TrimSpace(cedula) != "" {
		cedulaParam = cedula
	}

	if passwordHash != nil {
		passwordParam = *passwordHash
	}

	if estado != nil {
		estadoParam = *estado
	}

	var resultado ActualizarUsuarioResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("ID", id),
		sql.Named("Name", nombre),
		sql.Named("Email", email),
		sql.Named("Role", roleParam),
		sql.Named("Image", imageParam),
		sql.Named("Cedula", cedulaParam),
		sql.Named("Password", passwordParam),
		sql.Named("Estado", estadoParam),
	).Scan(
		&resultado.ID,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *UsuarioRepository) ToggleEstado(
	ctx context.Context,
	id int32,
) (ToggleUsuarioResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Usuario_ToggleEstado
			@id = @ID
	`

	var resultado ToggleUsuarioResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("ID", id),
	).Scan(
		&resultado.ID,
		&resultado.Estado,
		&resultado.Mensaje,
	)

	return resultado, err
}
