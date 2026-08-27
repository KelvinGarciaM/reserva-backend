package models

type TipoHabitacion struct {
	IDTipoHabitacion int32  `json:"idtipohabitacion"`
	NombreTipoHab    string `json:"nombretipohab"`
	Descripcion      string `json:"descripcion"`
	CapacidadMaxima  int32  `json:"capacidadmaxima"`
	Estado           int8   `json:"estado"`
}
