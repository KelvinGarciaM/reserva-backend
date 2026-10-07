package models

import (
	"database/sql"

	"github.com/shopspring/decimal"
)

type Tarifa struct {
	IDTarifa          int32           `json:"idTarifa"`
	IDTipoHabitacion  int32           `json:"idTipoHabitacion"`
	NombreTarifa      string          `json:"nombreTarifa"`
	TipoHabitacion    string          `json:"tipoHabitacion"`
	PrecioBase        decimal.Decimal `json:"precioBase"`
	FechaInicio       sql.NullTime    `json:"-"`
	FechaFin          sql.NullTime    `json:"-"`
	Descripcion       sql.NullString  `json:"-"`
	Estado            int8            `json:"estado"`
	DesactivadaManual int8            `json:"desactivadaManual"`
}
