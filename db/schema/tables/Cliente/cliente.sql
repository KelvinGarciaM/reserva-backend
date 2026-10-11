USE reservasdbV2;
GO

CREATE TABLE dbo.cliente
(
    cedula VARCHAR(20) NOT NULL,
    idTipoCliente INT NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    apellidos VARCHAR(45) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_cliente_estado DEFAULT (1),

    CONSTRAINT pk_cliente PRIMARY KEY (cedula),
    CONSTRAINT fk_cliente_tipocliente
        FOREIGN KEY (idTipoCliente) REFERENCES dbo.tipocliente(idTipoCliente),
    CONSTRAINT chk_cliente_estado CHECK (estado IN (0,1))
);
GO
