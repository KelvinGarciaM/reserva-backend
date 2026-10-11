USE reservasdbV2;
GO

CREATE TABLE dbo.recepcionista
(
    cedula VARCHAR(20) NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    apellidos VARCHAR(45) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_recepcionista_estado DEFAULT (1),

    CONSTRAINT pk_recepcionista PRIMARY KEY (cedula),
    CONSTRAINT chk_recepcionista_estado CHECK (estado IN (0,1))
);
GO
