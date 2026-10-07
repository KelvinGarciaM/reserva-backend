package models

import "github.com/shopspring/decimal"

type Habitacion struct {
	IDHabitacion     int32  `json:"idHabitacion"`
	IDTipoHab        int32  `json:"idTipoHab"`
	NombreTipoHab    string `json:"nombreTipoHab"`
	NumeroHabitacion string `json:"numeroHabitacion"`
	Estado           int8   `json:"estado"`
}

type HabitacionDisponible struct {
	IDHabitacion     int32           `json:"idHabitacion"`
	NumeroHabitacion string          `json:"numeroHabitacion"`
	NombreTipoHab    string          `json:"nombreTipoHab"`
	IDTarifa         int32           `json:"idTarifa"`
	NombreTarifa     string          `json:"nombreTarifa"`
	PrecioBase       decimal.Decimal `json:"precioBase"`
	CapacidadMaxima  int32           `json:"capacidadMaxima"`
}
