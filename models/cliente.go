package models

type Cliente struct {
	Cedula        string `json:"cedula"`
	IDTipoCliente int32  `json:"idTipoCliente"`
	NombreTipoC   string `json:"nombreTipoC"`
	Nombre        string `json:"nombre"`
	Apellidos     string `json:"apellidos"`
	Telefono      string `json:"telefono"`
	Direccion     string `json:"direccion"`
	Estado        int8   `json:"estado"`
}
