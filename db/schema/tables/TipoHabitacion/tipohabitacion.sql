USE reservasdbV2;
GO

CREATE TABLE dbo.tipohabitacion
(
    idTipoHabitacion INT IDENTITY(1,1) NOT NULL,
    nombreTipoHab VARCHAR(45) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    capacidadMaxima INT NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_tipohabitacion_estado DEFAULT (1),

    CONSTRAINT pk_tipohabitacion PRIMARY KEY (idTipoHabitacion),
    CONSTRAINT chk_capacidad_maxima CHECK (capacidadMaxima > 0),
    CONSTRAINT chk_tipohabitacion_estado CHECK (estado IN (0,1))
);
GO
