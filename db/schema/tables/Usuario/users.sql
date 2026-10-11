USE reservasdbV2;
GO

CREATE TABLE dbo.users
(
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(30) NULL
        CONSTRAINT df_users_role DEFAULT ('user'),
    email VARCHAR(150) NOT NULL,
    password VARCHAR(255) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_users_estado DEFAULT (1),
    image VARCHAR(255) NULL,
    cedula VARCHAR(20) NULL,
    created_at DATETIME NOT NULL
        CONSTRAINT df_users_created DEFAULT (GETDATE()),
    updated_at DATETIME NOT NULL
        CONSTRAINT df_users_updated DEFAULT (GETDATE()),

    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT fk_users_recepcionista
        FOREIGN KEY (cedula) REFERENCES dbo.recepcionista(cedula),
    CONSTRAINT chk_users_estado CHECK (estado IN (0,1))
);
GO
