USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_Cliente_EvitarDeleteFisico
ON dbo.cliente
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50320,
        'No se permite eliminar físicamente un cliente. Utilice eliminación lógica.',
        1;
END;
GO