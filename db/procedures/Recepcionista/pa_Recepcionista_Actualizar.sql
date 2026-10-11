USE reservasdbV2;
GO

/* ============================================
   4. ACTUALIZAR
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Actualizar
    @cedula VARCHAR(20),
    @nombre VARCHAR(45),
    @apellidos VARCHAR(45),
    @telefono VARCHAR(20),
    @correo VARCHAR(100),
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @cedula = LTRIM(RTRIM(@cedula));
        SET @nombre = LTRIM(RTRIM(@nombre));
        SET @apellidos = LTRIM(RTRIM(@apellidos));
        SET @telefono = LTRIM(RTRIM(@telefono));
        SET @correo = LTRIM(RTRIM(@correo));

        IF @estado NOT IN (0, 1)
        BEGIN
            THROW 50210,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.recepcionista WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50211,
                'El recepcionista que intenta actualizar no existe.',
                1;
        END;

        UPDATE dbo.recepcionista
        SET
            nombre = @nombre,
            apellidos = @apellidos,
            telefono = @telefono,
            correo = @correo,
            estado = @estado
        WHERE cedula = @cedula;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @filasAfectadas AS filasAfectadas,
            'Recepcionista actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
