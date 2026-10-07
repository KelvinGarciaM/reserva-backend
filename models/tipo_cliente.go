package models

type TipoCliente struct {
	IDTipoCliente int32   `json:"idTipoCliente"`
	NombreTipoC   string  `json:"nombreTipoC"`
	Descripcion   string  `json:"descripcion"`
	DescuentoBase float64 `json:"descuentoBase"`
	Estado        int8    `json:"estado"`
}
