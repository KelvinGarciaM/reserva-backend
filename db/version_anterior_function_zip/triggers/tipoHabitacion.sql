USE reservasdbV2;
GO

/* =========================================================
   TABLA DE AUDITORÍA PARA TIPO HABITACIÓN
   ========================================================= */

IF OBJECT_ID('dbo.auditoriaTipoHabitacion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.auditoriaTipoHabitacion
    (
        idAuditoria INT IDENTITY(1,1) PRIMARY KEY,
        idTipoHabitacion INT NOT NULL,
        accion VARCHAR(20) NOT NULL,
        nombreAnterior VARCHAR(45) NULL,
        nombreNuevo VARCHAR(45) NULL,
        descripcionAnterior VARCHAR(100) NULL,
        descripcionNueva VARCHAR(100) NULL,
        capacidadAnterior INT NULL,
        capacidadNueva INT NULL,
        estadoAnterior TINYINT NULL,
        estadoNuevo TINYINT NULL,
        fechaCambio DATETIME NOT NULL DEFAULT GETDATE()
    );
END;
GO


/* =========================================================
   TRIGGER 1
   AUDITORÍA DE INSERT Y UPDATE
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_TipoHabitacion_Auditoria
ON dbo.tipohabitacion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* INSERT */
    INSERT INTO dbo.auditoriaTipoHabitacion
    (
        idTipoHabitacion,
        accion,
        nombreAnterior,
        nombreNuevo,
        descripcionAnterior,
        descripcionNueva,
        capacidadAnterior,
        capacidadNueva,
        estadoAnterior,
        estadoNuevo
    )
    SELECT
        i.idTipoHabitacion,
        'INSERT',
        NULL,
        i.nombreTipoHab,
        NULL,
        i.descripcion,
        NULL,
        i.capacidadMaxima,
        NULL,
        i.estado
    FROM inserted i
    LEFT JOIN deleted d
        ON i.idTipoHabitacion = d.idTipoHabitacion
    WHERE d.idTipoHabitacion IS NULL;


    /* UPDATE */
    INSERT INTO dbo.auditoriaTipoHabitacion
    (
        idTipoHabitacion,
        accion,
        nombreAnterior,
        nombreNuevo,
        descripcionAnterior,
        descripcionNueva,
        capacidadAnterior,
        capacidadNueva,
        estadoAnterior,
        estadoNuevo
    )
    SELECT
        i.idTipoHabitacion,
        'UPDATE',
        d.nombreTipoHab,
        i.nombreTipoHab,
        d.descripcion,
        i.descripcion,
        d.capacidadMaxima,
        i.capacidadMaxima,
        d.estado,
        i.estado
    FROM inserted i
    INNER JOIN deleted d
        ON i.idTipoHabitacion = d.idTipoHabitacion;
END;
GO


/* =========================================================
   TRIGGER 2
   EVITAR ELIMINACIÓN FÍSICA
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_TipoHabitacion_EvitarDeleteFisico
ON dbo.tipohabitacion
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50020,
        'No se permite eliminar físicamente un tipo de habitación. Utilice eliminación lógica.',
        1;
END;
GO