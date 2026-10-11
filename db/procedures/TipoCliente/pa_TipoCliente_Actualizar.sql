USE reservasdbV2;
GO

/* =========================================================
   4. ACTUALIZAR TIPO DE CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Actualizar
    @idTipoCliente INT,
    @nombreTipoC VARCHAR(45),
    @descripcion VARCHAR(100),
    @descuentoBase DECIMAL(10,2),
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @nombreTipoC = LTRIM(RTRIM(@nombreTipoC));
        SET @descripcion = LTRIM(RTRIM(@descripcion));

        IF @idTipoCliente IS NULL
           OR @idTipoCliente <= 0
        BEGIN
            THROW 50107,
                'El ID del tipo de cliente debe ser mayor que cero.',
                1;
        END;

        IF @nombreTipoC IS NULL
           OR @nombreTipoC = ''
        BEGIN
            THROW 50108,
                'El nombre del tipo de cliente es obligatorio.',
                1;
        END;

        IF @descuentoBase IS NULL
           OR @descuentoBase < 0
        BEGIN
            THROW 50109,
                'El descuento base no puede ser negativo.',
                1;
        END;

        IF @estado IS NULL
           OR @estado NOT IN (0, 1)
        BEGIN
            THROW 50110,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50111,
                'El tipo de cliente que intenta actualizar no existe.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTipoC = @nombreTipoC
              AND idTipoCliente <> @idTipoCliente
        )
        BEGIN
            THROW 50112,
                'Ya existe otro tipo de cliente con ese nombre.',
                1;
        END;

        UPDATE dbo.tipocliente
        SET
            nombreTipoC = @nombreTipoC,
            descripcion = @descripcion,
            descuentoBase = @descuentoBase,
            estado = @estado
        WHERE idTipoCliente = @idTipoCliente;

        DECLARE @filasAfectadas INT;

        SET @filasAfectadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTipoCliente AS idTipoCliente,
            @filasAfectadas AS filasAfectadas,
            'Tipo de cliente actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
