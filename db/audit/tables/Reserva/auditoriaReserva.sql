USE reservasdbV2;
GO

/* ---------- 11.2 Auditoría de reservas ---------- */
CREATE TABLE dbo.auditoriaReserva
(
    idAuditoria              INT IDENTITY(1,1) NOT NULL,
    idReserva                INT          NOT NULL,
    accion                   VARCHAR(10)  NOT NULL,
    idClienteAnterior        VARCHAR(20)  NULL,
    idClienteNuevo           VARCHAR(20)  NULL,
    idRecepcionistaAnterior  VARCHAR(20)  NULL,
    idRecepcionistaNuevo     VARCHAR(20)  NULL,
    estadoReservaAnterior    VARCHAR(25)  NULL,
    estadoReservaNuevo       VARCHAR(25)  NULL,
    estadoAnterior           TINYINT      NULL,
    estadoNuevo              TINYINT      NULL,
    totalAnterior            DECIMAL(10,2) NULL,
    totalNuevo               DECIMAL(10,2) NULL,
    usuarioBD                SYSNAME      NOT NULL
        CONSTRAINT df_audres_usuario DEFAULT (ORIGINAL_LOGIN()),
    fechaCambio              DATETIME     NOT NULL
        CONSTRAINT df_audres_fecha DEFAULT (GETDATE()),

    CONSTRAINT pk_auditoriaReserva PRIMARY KEY (idAuditoria),
    CONSTRAINT chk_audres_accion CHECK (accion IN ('INSERT','UPDATE','DELETE'))
);
GO
