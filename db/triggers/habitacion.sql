USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_Habitacion_EvitarDeleteFisico
ON dbo.habitacion
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50520,
        'No se permite eliminar físicamente una habitación. Utilice eliminación lógica.',
        1;
END;
GO