package models

import (
	"database/sql"
)

type UsuarioLogin struct {
	ID        int32
	Name      string
	Role      sql.NullString
	Email     string
	Password  string
	Image     sql.NullString
	Cedula    sql.NullString
	CreatedAt sql.NullTime
	UpdatedAt sql.NullTime
	Estado    int8
}

type Usuario struct {
	ID        int32          `json:"id"`
	Name      string         `json:"name"`
	Role      sql.NullString `json:"role"`
	Email     string         `json:"email"`
	Image     sql.NullString `json:"image"`
	Cedula    sql.NullString `json:"cedula"`
	CreatedAt sql.NullTime   `json:"created_at"`
	UpdatedAt sql.NullTime   `json:"updated_at"`
	Estado    int8           `json:"estado"`
}
