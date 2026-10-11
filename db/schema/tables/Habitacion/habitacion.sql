USE reservasdbV2;
GO

CREATE TABLE dbo.habitacion
(
    idHabitacion INT IDENTITY(1,1) NOT NULL,
    idTipoHab INT NOT NULL,
    numeroHabitacion VARCHAR(45) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_habitacion_estado DEFAULT (1),

    CONSTRAINT pk_habitacion PRIMARY KEY (idHabitacion),
    CONSTRAINT fk_habitacion_tipohabitacion
        FOREIGN KEY (idTipoHab) REFERENCES dbo.tipohabitacion(idTipoHabitacion),
    CONSTRAINT chk_habitacion_estado CHECK (estado IN (0,1))
);
GO
