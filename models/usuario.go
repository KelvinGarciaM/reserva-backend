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
