package utils

import (
	"context"
	"database/sql"
	"errors"

	"reserva-backend/repository"

	"golang.org/x/crypto/bcrypt"
)

func SeedAdmin(
	db *repository.UsuarioRepository,
	config Config,
) error {
	ctx := context.Background()

	_, err := db.ObtenerPorEmail(
		ctx,
		config.AdminEmail,
	)

	// Si ya existe y está activo, no hace nada.
	if err == nil {
		return nil
	}

	// Si el error no significa "usuario inexistente",
	// se devuelve el error real.
	if !errors.Is(err, sql.ErrNoRows) {
		return err
	}

	hashedPassword, err := bcrypt.GenerateFromPassword(
		[]byte(config.AdminPassword),
		bcrypt.DefaultCost,
	)
	if err != nil {
		return err
	}

	return db.CrearAdmin(
		ctx,
		config.AdminName,
		config.AdminEmail,
		string(hashedPassword),
		config.AdminRole,
	)
}
