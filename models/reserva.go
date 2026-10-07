package models

import (
	"time"

	"github.com/shopspring/decimal"
)

type Reserva struct {
	IDReserva           int32           `json:"idreserva"`
	IDRecepcionista     string          `json:"idrecepcionista"`
	IDCliente           string          `json:"idcliente"`
	NombreCliente       string          `json:"nombrecliente"`
	NombreRecepcionista string          `json:"nombrerecepcionista"`
	FechaReserva        time.Time       `json:"fechareserva"`
	EstadoReserva       string          `json:"estadoreserva"`
	Estado              int8            `json:"estado"`
	Iva                 decimal.Decimal `json:"iva"`
	SubTotal            decimal.Decimal `json:"subtotal"`
	Total               decimal.Decimal `json:"total"`
}
