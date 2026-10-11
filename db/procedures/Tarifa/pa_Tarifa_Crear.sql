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
