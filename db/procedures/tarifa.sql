USE reservasdbV2;
GO


/* =========================================================
   1. CREAR TARIFA
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_Crear
    @idTipoHabitacion INT,
    @precioBase DECIMAL(10,2),
    @nombreTarifa VARCHAR(45),
    @fechaInicio DATE = NULL,
    @fechaFin DATE = NULL,
    @descripcion NVARCHAR(MAX) = NULL,
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @nombreTarifa = LTRIM(RTRIM(@nombreTarifa));

        IF @nombreTarifa IS NULL OR @nombreTarifa = ''
            THROW 50401, 'El nombre de la tarifa es obligatorio.', 1;

        IF @precioBase IS NULL OR @precioBase < 0
            THROW 50402, 'El precio base no puede ser negativo.', 1;

        IF @estado NOT IN (0, 1)
            THROW 50403, 'El estado debe ser 0 o 1.', 1;

        IF @fechaInicio IS NOT NULL
           AND @fechaFin IS NOT NULL
           AND @fechaFin < @fechaInicio
        BEGIN
            THROW 50404,
                'La fecha final no puede ser anterior a la fecha inicial.',
                1;
        END;

        BEGIN TRANSACTION;

        -- El tipo de habitación debe existir
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipohabitacion
            WHERE idTipoHabitacion = @idTipoHabitacion
        )
        BEGIN
            THROW 50405,
                'El tipo de habitación indicado no existe.',
                1;
        END;

        -- El API busca tarifas por nombre, por eso evitamos
        -- nombres duplicados que producirían ambigüedad.
        IF EXISTS
        (
            SELECT 1
            FROM dbo.tarifa WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTarifa = @nombreTarifa
        )
        BEGIN
            THROW 50406,
                'Ya existe una tarifa con ese nombre.',
                1;
        END;

        INSERT INTO dbo.tarifa
        (
            idTipoHabitacion,
            precioBase,
            nombreTarifa,
            fechaInicio,
            fechaFin,
            descripcion,
            desactivadaManual,
            estado
        )
        VALUES
        (
            @idTipoHabitacion,
            @precioBase,
            @nombreTarifa,
            @fechaInicio,
            @fechaFin,
            @descripcion,
            0,
            @estado
        );

        DECLARE @nuevoId INT;
        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idTarifa,
            'Tarifa creada correctamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
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


/* =========================================================
   3. ACTIVAR / DESACTIVAR TARIFA

   @activar:
       1 = activar
       0 = desactivar manualmente
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_CambiarEstado
    @idTarifa INT,
    @activar TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF @activar NOT IN (0, 1)
            THROW 50414, 'El parámetro activar debe ser 0 o 1.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tarifa WITH (UPDLOCK, HOLDLOCK)
            WHERE idTarifa = @idTarifa
        )
        BEGIN
            THROW 50415, 'La tarifa indicada no existe.', 1;
        END;

        -- ACTIVAR
        IF @activar = 1
        BEGIN

            -- Se conserva la regla que ya tenía el backend:
            -- solo puede activarse dentro del rango de vigencia.
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.tarifa
                WHERE idTarifa = @idTarifa
                  AND fechaInicio <= CAST(GETDATE() AS DATE)
                  AND fechaFin >= CAST(GETDATE() AS DATE)
            )
            BEGIN
                THROW 50416,
                    'La tarifa solo puede activarse si la fecha actual está dentro del rango de vigencia.',
                    1;
            END;

            UPDATE dbo.tarifa
            SET
                estado = 1,
                desactivadaManual = 0
            WHERE idTarifa = @idTarifa;

        END
        ELSE
        BEGIN

            -- DESACTIVACIÓN MANUAL
            UPDATE dbo.tarifa
            SET
                estado = 0,
                desactivadaManual = 1
            WHERE idTarifa = @idTarifa;

        END;

        DECLARE @estadoActual TINYINT;
        DECLARE @manualActual TINYINT;

        SELECT
            @estadoActual = estado,
            @manualActual = desactivadaManual
        FROM dbo.tarifa
        WHERE idTarifa = @idTarifa;

        COMMIT TRANSACTION;

        SELECT
            @idTarifa AS idTarifa,
            @estadoActual AS estado,
            @manualActual AS desactivadaManual,
            CASE
                WHEN @activar = 1
                    THEN 'Tarifa activada correctamente.'
                ELSE
                    'Tarifa desactivada correctamente.'
            END AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   4. SINCRONIZAR VIGENCIA AUTOMÁTICAMENTE

   Reemplaza:
   - UpdateTarifasVencidasAutomatico
   - ActivarTarifasVigentesAutomatico
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_SincronizarVigencia
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        DECLARE @hoy DATE = CAST(GETDATE() AS DATE);
        DECLARE @vencidas INT;
        DECLARE @activadas INT;

        BEGIN TRANSACTION;

        -- Tarifas cuya vigencia terminó
        UPDATE dbo.tarifa
        SET
            estado = 0,
            desactivadaManual = 0
        WHERE fechaFin IS NOT NULL
          AND fechaFin < @hoy;

        SET @vencidas = @@ROWCOUNT;

        -- Reactivar únicamente las que no fueron
        -- desactivadas manualmente.
        UPDATE dbo.tarifa
        SET estado = 1
        WHERE estado = 0
          AND desactivadaManual = 0
          AND fechaInicio IS NOT NULL
          AND fechaFin IS NOT NULL
          AND fechaInicio <= @hoy
          AND fechaFin >= @hoy;

        SET @activadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @vencidas AS tarifasVencidas,
            @activadas AS tarifasActivadas;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO