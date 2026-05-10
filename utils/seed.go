package utils

import (
	"context"
	"database/sql"
	"reserva-backend/dto"

	"golang.org/x/crypto/bcrypt"
)

func SeedAdmin(db *dto.Queries, config Config) error {

	_, err := db.GetUserByEmail(
		context.Background(),
		config.AdminEmail,
	)

	// si ya existe, no hace nada
	if err == nil {
		return nil
	}

	hashedPassword, err := bcrypt.GenerateFromPassword(
		[]byte(config.AdminPassword),
		bcrypt.DefaultCost,
	)

	if err != nil {
		return err
	}

	err = db.CreateUser(context.Background(), dto.CreateUserParams{
		Name: config.AdminName,
		Role: sql.NullString{
			String: config.AdminRole,
			Valid:  true,
		},
		Email:    config.AdminEmail,
		Password: string(hashedPassword),
	})

	return err
}
