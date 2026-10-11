USE reservasdbV2;
GO

/* ---------- 11.4 Auditoría de respaldos y restauraciones ---------- */
CREATE TABLE dbo.auditoriaRespaldo
(
    idAuditoria    INT IDENTITY(1,1) NOT NULL,
    tipoOperacion  VARCHAR(10)   NOT NULL,
    archivo        NVARCHAR(400) NULL,
    resultado      VARCHAR(10)   NOT NULL,
    mensaje        NVARCHAR(500) NULL,
    usuarioBD      SYSNAME       NOT NULL
        CONSTRAINT df_audresp_usuario DEFAULT (ORIGINAL_LOGIN()),
    fechaHora      DATETIME      NOT NULL
        CONSTRAINT df_audresp_fecha DEFAULT (GETDATE()),

    CONSTRAINT pk_auditoriaRespaldo PRIMARY KEY (idAuditoria),
    CONSTRAINT chk_audresp_tipo CHECK (tipoOperacion IN ('BACKUP','RESTORE')),
    CONSTRAINT chk_audresp_resultado CHECK (resultado IN ('OK','ERROR'))
);
GO
