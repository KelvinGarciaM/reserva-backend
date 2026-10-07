USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_Tarifa_EvitarDeleteFisico
ON dbo.tarifa
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50420,
        'No se permite eliminar físicamente una tarifa. Utilice la desactivación.',
        1;
END;
GO