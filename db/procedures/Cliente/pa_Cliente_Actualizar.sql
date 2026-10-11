USE reservasdbV2;
GO

/* =========================================================
   2. ACTUALIZAR CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Cliente_Actualizar
    @cedula VARCHAR(20),
    @idTipoCliente INT,
    @nombre VARCHAR(45),
    @apellidos VARCHAR(45),
    @telefono VARCHAR(20),
    @direccion VARCHAR(100),
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
        SET @direccion = LTRIM(RTRIM(@direccion));

        IF @estado NOT IN (0, 1)
        BEGIN
            THROW 50308,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        -- Comprobar cliente
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.cliente WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50309,
                'El cliente que intenta actualizar no existe.',
                1;
        END;

        -- Comprobar tipo de cliente
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50310,
                'El tipo de cliente indicado no existe.',
                1;
        END;

        UPDATE dbo.cliente
        SET
            idTipoCliente = @idTipoCliente,
            nombre = @nombre,
            apellidos = @apellidos,
            telefono = @telefono,
            direccion = @direccion,
            estado = @estado
        WHERE cedula = @cedula;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @filasAfectadas AS filasAfectadas,
            'Cliente actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
