USE reservasdbV2;
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
