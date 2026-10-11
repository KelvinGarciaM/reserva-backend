USE reservasdbV2;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Restaurar_reservasdbV2
    @archivo NVARCHAR(400)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    IF DB_ID(N'reservasdbV2') IS NULL
        THROW 51201, 'La base de datos reservasdbV2 no existe en esta instancia.', 1;

    /* Seguridad: solo se restauran archivos que el propio sistema respaldó. */
    DECLARE @valido BIT = 0;
    EXEC sys.sp_executesql
        N'SELECT @v = CASE WHEN EXISTS (
              SELECT 1 FROM reservasdbV2.dbo.auditoriaRespaldo
              WHERE tipoOperacion = ''BACKUP'' AND resultado = ''OK'' AND archivo = @a
          ) THEN 1 ELSE 0 END;',
        N'@a NVARCHAR(400), @v BIT OUTPUT',
        @a = @archivo, @v = @valido OUTPUT;

    IF @valido = 0
        THROW 51202, 'El archivo indicado no está en la lista de respaldos válidos del sistema.', 1;

    DECLARE @usuario SYSNAME = ORIGINAL_LOGIN();
    DECLARE @sql NVARCHAR(MAX) =
        N'RESTORE DATABASE reservasdbV2 FROM DISK = N''' + REPLACE(@archivo, N'''', N'''''') +
        N''' WITH REPLACE, RECOVERY, CHECKSUM, STATS = 10;';

    BEGIN TRY
        ALTER DATABASE reservasdbV2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        EXEC sys.sp_executesql @sql;
        ALTER DATABASE reservasdbV2 SET MULTI_USER;

        /* Se deja constancia dentro de la base ya restaurada. */
        EXEC sys.sp_executesql
            N'INSERT INTO reservasdbV2.dbo.auditoriaRespaldo
                  (tipoOperacion, archivo, resultado, mensaje, usuarioBD)
              VALUES (''RESTORE'', @a, ''OK'', N''Restauración completada.'', @u);',
            N'@a NVARCHAR(400), @u SYSNAME', @a = @archivo, @u = @usuario;

        SELECT @archivo AS archivo, N'Base de datos restaurada correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        /* Si algo falla, nunca se deja la base bloqueada en modo SINGLE_USER. */
        IF EXISTS (SELECT 1 FROM sys.databases
                   WHERE name = N'reservasdbV2' AND state_desc = N'ONLINE')
            ALTER DATABASE reservasdbV2 SET MULTI_USER;
        THROW;
    END CATCH;
END;
GO
