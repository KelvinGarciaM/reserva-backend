USE reservasdbV2;
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
