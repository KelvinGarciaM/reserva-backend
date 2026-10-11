USE reservasdbV2;
GO

/* ---------- 12.1 Crear respaldo completo ---------- */
CREATE OR ALTER PROCEDURE dbo.pa_Respaldo_Crear
    @rutaCarpeta NVARCHAR(260) = NULL   -- NULL = carpeta de respaldos por defecto
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ruta NVARCHAR(260) =
        COALESCE(NULLIF(LTRIM(RTRIM(@rutaCarpeta)), N''),
                 CONVERT(NVARCHAR(260), SERVERPROPERTY('InstanceDefaultBackupPath')),
                 N'C:\SQLBackups\');

    IF RIGHT(@ruta, 1) NOT IN (N'\', N'/')
        SET @ruta = @ruta + CASE WHEN CHARINDEX(N'/', @ruta) > 0 THEN N'/' ELSE N'\' END;

    DECLARE @archivo NVARCHAR(400) =
        @ruta + N'reservasdbV2_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + N'.bak';

    DECLARE @sql NVARCHAR(MAX) =
        N'BACKUP DATABASE reservasdbV2 TO DISK = N''' + REPLACE(@archivo, N'''', N'''''') +
        N''' WITH INIT, CHECKSUM, STATS = 10, NAME = N''Respaldo completo reservasdbV2'';';

    BEGIN TRY
        EXEC sys.sp_executesql @sql;

        INSERT INTO dbo.auditoriaRespaldo (tipoOperacion, archivo, resultado, mensaje)
        VALUES ('BACKUP', @archivo, 'OK', N'Respaldo completo generado.');

        SELECT @archivo AS archivo, N'Respaldo completo generado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.auditoriaRespaldo (tipoOperacion, archivo, resultado, mensaje)
        VALUES ('BACKUP', @archivo, 'ERROR', LEFT(ERROR_MESSAGE(), 500));

        THROW;
    END CATCH;
END;
GO
