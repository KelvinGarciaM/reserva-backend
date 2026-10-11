USE reservasdbV2;
GO

CREATE TABLE dbo.reserva
(
    idReserva INT IDENTITY(1,1) NOT NULL,
    idRecepcionista VARCHAR(20) NOT NULL,
    idCliente VARCHAR(20) NOT NULL,
    fechaReserva DATETIME NOT NULL,
    estadoReserva VARCHAR(25) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_reserva_estado DEFAULT (1),
    iva DECIMAL(10,2) NOT NULL
        CONSTRAINT df_reserva_iva DEFAULT (0.00),
    subTotal DECIMAL(10,2) NOT NULL
        CONSTRAINT df_reserva_subtotal DEFAULT (0.00),
    total DECIMAL(10,2) NOT NULL
        CONSTRAINT df_reserva_total DEFAULT (0.00),

    CONSTRAINT pk_reserva PRIMARY KEY (idReserva),
    CONSTRAINT fk_reserva_recepcionista
        FOREIGN KEY (idRecepcionista) REFERENCES dbo.recepcionista(cedula),
    CONSTRAINT fk_reserva_cliente
        FOREIGN KEY (idCliente) REFERENCES dbo.cliente(cedula),
    CONSTRAINT chk_reserva_estado CHECK (estado IN (0,1)),
    CONSTRAINT chk_reserva_montos CHECK (iva >= 0 AND subTotal >= 0 AND total >= 0)
);
GO
