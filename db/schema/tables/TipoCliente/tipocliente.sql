USE reservasdbV2;
GO

/* ============================================================================
   3. TABLAS
   ============================================================================ */

CREATE TABLE dbo.tipocliente
(
    idTipoCliente INT IDENTITY(1,1) NOT NULL,
    nombreTipoC VARCHAR(45) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    descuentoBase DECIMAL(10,2) NOT NULL
        CONSTRAINT df_tipocliente_descuento DEFAULT (0.00),
    estado TINYINT NOT NULL
        CONSTRAINT df_tipocliente_estado DEFAULT (1),

    CONSTRAINT pk_tipocliente PRIMARY KEY (idTipoCliente),
    CONSTRAINT chk_tipocliente_descuento CHECK (descuentoBase >= 0 AND descuentoBase <= 100),
    CONSTRAINT chk_tipocliente_estado CHECK (estado IN (0,1))
);
GO
