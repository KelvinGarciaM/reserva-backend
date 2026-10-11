USE reservasdbV2;
GO

/* ---------- 11.1 Auditoría de sesiones ---------- */
CREATE TABLE dbo.auditoriaSesion
(
    idAuditoriaSesion INT IDENTITY(1,1) NOT NULL,
    loginBD           SYSNAME      NOT NULL
        CONSTRAINT df_audses_login DEFAULT (ORIGINAL_LOGIN()),
    rolBD             VARCHAR(30)  NULL,
    accion            VARCHAR(20)  NOT NULL,
    usuarioApp        VARCHAR(150) NULL,
    ipOrigen          VARCHAR(45)  NULL,
    detalle           VARCHAR(200) NULL,
    fechaHora         DATETIME     NOT NULL
        CONSTRAINT df_audses_fecha DEFAULT (GETDATE()),

    CONSTRAINT pk_auditoriaSesion PRIMARY KEY (idAuditoriaSesion),
    CONSTRAINT chk_audses_accion CHECK (accion IN ('LOGIN','LOGOUT','LOGIN_FALLIDO'))
);
GO
