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
