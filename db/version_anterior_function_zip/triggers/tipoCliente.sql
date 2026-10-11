USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_TipoCliente_EvitarDeleteFisico
ON dbo.tipocliente
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50120,
        'No se permite eliminar físicamente un tipo de cliente. Utilice eliminación lógica.',
        1;
END;
GO