USE reservasdbV2;
GO

/* =========================================================
   2. ACTUALIZAR TARIFA

   Los parámetros NULL significan:
   "conservar el valor que ya tiene".
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_Actualizar
    @idTarifa INT,
    @idTipoHabitacion INT = NULL,
    @precioBase DECIMAL(10,2) = NULL,
    @nombreTarifa VARCHAR(45) = NULL,
    @fechaInicio DATE = NULL,
    @fechaFin DATE = NULL,
    @descripcion NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF @idTarifa IS NULL OR @idTarifa <= 0
            THROW 50407, 'El ID de la tarifa no es válido.', 1;

        IF @precioBase IS NOT NULL AND @precioBase < 0
            THROW 50408, 'El precio base no puede ser negativo.', 1;

        IF @nombreTarifa IS NOT NULL
        BEGIN
            SET @nombreTarifa = LTRIM(RTRIM(@nombreTarifa));

            IF @nombreTarifa = ''
                THROW 50409, 'El nombre de la tarifa no puede estar vacío.', 1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tarifa WITH (UPDLOCK, HOLDLOCK)
            WHERE idTarifa = @idTarifa
        )
        BEGIN
            THROW 50410,
                'La tarifa que intenta actualizar no existe.',
                1;
        END;

        IF @idTipoHabitacion IS NOT NULL
           AND NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipohabitacion
            WHERE idTipoHabitacion = @idTipoHabitacion
        )
        BEGIN
            THROW 50411,
                'El tipo de habitación indicado no existe.',
                1;
        END;

        IF @nombreTarifa IS NOT NULL
           AND EXISTS
        (
            SELECT 1
            FROM dbo.tarifa
            WHERE nombreTarifa = @nombreTarifa
              AND idTarifa <> @idTarifa
        )
        BEGIN
            THROW 50412,
                'Ya existe otra tarifa con ese nombre.',
                1;
        END;

        -- Calculamos cómo quedarían finalmente las fechas
        -- antes de ejecutar el UPDATE.
        DECLARE @fechaInicioFinal DATE;
        DECLARE @fechaFinFinal DATE;

        SELECT
            @fechaInicioFinal =
                COALESCE(@fechaInicio, fechaInicio),
            @fechaFinFinal =
                COALESCE(@fechaFin, fechaFin)
        FROM dbo.tarifa
        WHERE idTarifa = @idTarifa;

        IF @fechaInicioFinal IS NOT NULL
           AND @fechaFinFinal IS NOT NULL
           AND @fechaFinFinal < @fechaInicioFinal
        BEGIN
            THROW 50413,
                'La fecha final no puede ser anterior a la fecha inicial.',
                1;
        END;

        UPDATE dbo.tarifa
        SET
            idTipoHabitacion =
                COALESCE(@idTipoHabitacion, idTipoHabitacion),

            precioBase =
                COALESCE(@precioBase, precioBase),

            nombreTarifa =
                COALESCE(@nombreTarifa, nombreTarifa),

            fechaInicio =
                COALESCE(@fechaInicio, fechaInicio),

            fechaFin =
                COALESCE(@fechaFin, fechaFin),

            descripcion =
                @descripcion -- Se permite poner NULL explícitamente

        WHERE idTarifa = @idTarifa;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTarifa AS idTarifa,
            @filasAfectadas AS filasAfectadas,
            'Tarifa actualizada correctamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
