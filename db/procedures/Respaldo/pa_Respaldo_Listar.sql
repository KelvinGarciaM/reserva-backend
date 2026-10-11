USE reservasdbV2;
GO

/* ---------- 12.2 Listar respaldos disponibles para restaurar ---------- */
CREATE OR ALTER PROCEDURE dbo.pa_Respaldo_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (50)
           idAuditoria, archivo, usuarioBD, fechaHora
    FROM dbo.auditoriaRespaldo
    WHERE tipoOperacion = 'BACKUP' AND resultado = 'OK'
    ORDER BY fechaHora DESC;
END;
GO
