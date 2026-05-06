package utils

import (
	"database/sql"
	"strconv"
	"time"
)

func ParseNullDate(value *string) (sql.NullTime, error) {
	if value == nil {
		return sql.NullTime{
			Valid: false,
		}, nil
	}

	loc, err := time.LoadLocation("America/Costa_Rica")
	if err != nil {
		return sql.NullTime{}, err
	}

	t, err := time.ParseInLocation("2006-01-02", *value, loc)
	if err != nil {
		return sql.NullTime{}, err
	}

	return sql.NullTime{
		Time:  t,
		Valid: true,
	}, nil
}

func ParseNullIdTipoHabitacion(id *int32) sql.NullInt32 {
	if id == nil {
		return sql.NullInt32{
			Valid: false,
		}
	}
	return sql.NullInt32{
		Int32: *id,
		Valid: true,
	}

}

func ParseNullString(value *string) sql.NullString {
	if value == nil {
		return sql.NullString{
			Valid: false,
		}
	}
	return sql.NullString{
		String: *value,
		Valid:  true,
	}

}

func FormatNullDate(date sql.NullTime) *string {
	if !date.Valid {
		return nil
	}
	formatedd := date.Time.Format("2006-01-02")
	return &formatedd
}

func FormatEstado(estado int8) string {
	if estado == 1 {
		return "Activo"
	}

	return "Inactivo"
}

func ParseInt(id string) (int32, error) {
	valor, err := strconv.ParseInt(id, 10, 32)
	if err != nil {
		return 0, err
	}
	numero := int32(valor)
	return numero, nil
}

func ParseStringToDate(date string) (time.Time, error) {
	loc, err := time.LoadLocation("America/Costa_Rica")
	if err != nil {
		return time.Time{}, err
	}
	fecha, err := time.ParseInLocation("2006-01-02", date, loc)
	if err != nil {
		return time.Time{}, err
	}
	return fecha, nil
}

func ParseStringPtrToTime(date *string) (time.Time, error) {

	loc, err := time.LoadLocation("America/Costa_Rica")
	if err != nil {
		return time.Time{}, err
	}

	fecha, err := time.ParseInLocation("2006-01-02", *date, loc)
	if err != nil {
		return time.Time{}, err
	}

	return fecha, nil
}
