USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_Recepcionista_EvitarDeleteFisico
ON dbo.recepcionista
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50220,
        'No se permite eliminar físicamente un recepcionista. Utilice eliminación lógica.',
        1;
END;
GO