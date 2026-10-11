USE reservasdbV2;
GO

CREATE TABLE dbo.tarifa
(
    idTarifa INT IDENTITY(1,1) NOT NULL,
    idTipoHabitacion INT NOT NULL,
    precioBase DECIMAL(10,2) NOT NULL,
    nombreTarifa VARCHAR(45) NOT NULL,
    fechaInicio DATE NULL,
    fechaFin DATE NULL,
    descripcion NVARCHAR(MAX) NULL,
    desactivadaManual TINYINT NOT NULL
        CONSTRAINT df_tarifa_desactivadamanual DEFAULT (0),
    estado TINYINT NOT NULL
        CONSTRAINT df_tarifa_estado DEFAULT (1),

    CONSTRAINT pk_tarifa PRIMARY KEY (idTarifa),
    CONSTRAINT fk_tarifa_tipohabitacion
        FOREIGN KEY (idTipoHabitacion) REFERENCES dbo.tipohabitacion(idTipoHabitacion),
    CONSTRAINT chk_precio_tarifa CHECK (precioBase >= 0),
    CONSTRAINT chk_tarifa_estado CHECK (estado IN (0,1)),
    CONSTRAINT chk_tarifa_desactivadamanual CHECK (desactivadaManual IN (0,1)),
    CONSTRAINT chk_tarifa_fechas CHECK (fechaInicio IS NULL OR fechaFin IS NULL OR fechaFin >= fechaInicio)
);
GO
