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
