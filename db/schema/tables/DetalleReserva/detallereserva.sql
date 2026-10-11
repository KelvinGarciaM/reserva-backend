USE reservasdbV2;
GO

CREATE TABLE dbo.detallereserva
(
    idDetalleReserva INT IDENTITY(1,1) NOT NULL,
    idHabitacion INT NOT NULL,
    idReserva INT NOT NULL,
    idTarifa INT NOT NULL,
    cantidadPersonas INT NOT NULL,
    precioAplicado DECIMAL(10,2) NOT NULL,
    fechaEntrada DATETIME NOT NULL,
    fechaSalida DATETIME NOT NULL,
    iva DECIMAL(10,2) NOT NULL,
    subTotal DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_detallereserva_estado DEFAULT (1),

    CONSTRAINT pk_detallereserva PRIMARY KEY (idDetalleReserva),
    CONSTRAINT fk_detallereserva_habitacion
        FOREIGN KEY (idHabitacion) REFERENCES dbo.habitacion(idHabitacion),
    CONSTRAINT fk_detallereserva_reserva
        FOREIGN KEY (idReserva) REFERENCES dbo.reserva(idReserva),
    CONSTRAINT fk_detallereserva_tarifa
        FOREIGN KEY (idTarifa) REFERENCES dbo.tarifa(idTarifa),
    CONSTRAINT chk_cantidad_personas CHECK (cantidadPersonas > 0),
    CONSTRAINT chk_fechas_reserva CHECK (fechaSalida > fechaEntrada),
    CONSTRAINT chk_detallereserva_estado CHECK (estado IN (0,1)),
    CONSTRAINT chk_detallereserva_montos CHECK
        (precioAplicado >= 0 AND iva >= 0 AND subTotal >= 0 AND total >= 0)
);
GO
