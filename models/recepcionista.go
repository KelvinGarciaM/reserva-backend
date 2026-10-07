package models

type Recepcionista struct {
	Cedula    string `json:"cedula"`
	Nombre    string `json:"nombre"`
	Apellidos string `json:"apellidos"`
	Telefono  string `json:"telefono"`
	Correo    string `json:"correo"`
	Estado    int8   `json:"estado"`
}
