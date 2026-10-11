USE reservasdbV2;
GO

/* ---------- 11.3 Auditoría de tarifas ---------- */
CREATE TABLE dbo.auditoriaTarifa
(
    idAuditoria            INT IDENTITY(1,1) NOT NULL,
    idTarifa               INT          NOT NULL,
    accion                 VARCHAR(10)  NOT NULL,
    precioBaseAnterior     DECIMAL(10,2) NULL,
    precioBaseNuevo        DECIMAL(10,2) NULL,
    fechaInicioAnterior    DATE         NULL,
    fechaInicioNueva       DATE         NULL,
    fechaFinAnterior       DATE         NULL,
    fechaFinNueva          DATE         NULL,
    estadoAnterior         TINYINT      NULL,
    estadoNuevo            TINYINT      NULL,
    usuarioBD              SYSNAME      NOT NULL
        CONSTRAINT df_audtar_usuario DEFAULT (ORIGINAL_LOGIN()),
    fechaCambio            DATETIME     NOT NULL
        CONSTRAINT df_audtar_fecha DEFAULT (GETDATE()),

    CONSTRAINT pk_auditoriaTarifa PRIMARY KEY (idAuditoria),
    CONSTRAINT chk_audtar_accion CHECK (accion IN ('INSERT','UPDATE'))
);
GO
