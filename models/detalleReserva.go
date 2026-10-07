package models

import (
	"time"

	"github.com/shopspring/decimal"
)

type DetalleReserva struct {
	IDDetalleReserva     int32
	NombreTipoHabitacion string
	NumeroHabitacion     string
	NombreRecepcionista  string
	NombreCliente        string
	NombreTipoCliente    string
	FechaReserva         time.Time
	EstadoReserva        string
	NombreTarifa         string
	CantidadPersonas     int32
	PrecioAplicado       decimal.Decimal
	FechaEntrada         time.Time
	FechaSalida          time.Time
	Iva                  decimal.Decimal
	SubTotal             decimal.Decimal
	Total                decimal.Decimal
	Estado               int8
}

type DetalleReservaPorReserva struct {
	IDDetalleReserva     int32
	NombreTipoHabitacion string
	NumeroHabitacion     string
	NombreTarifa         string
	DescuentoBase        decimal.Decimal
	CantidadPersonas     int32
	PrecioAplicado       decimal.Decimal
	FechaEntrada         time.Time
	FechaSalida          time.Time
	Iva                  decimal.Decimal
	SubTotal             decimal.Decimal
	Total                decimal.Decimal
	Estado               int8
}

type TarifaActivaDetalle struct {
	IDTarifa     int32
	PrecioBase   decimal.Decimal
	NombreTarifa string
}

type FechasDetalleReserva struct {
	FechaEntrada time.Time
	FechaSalida  time.Time
}
