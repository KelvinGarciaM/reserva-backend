USE reservasdbV2;
GO

/* =========================================================
   1. CREAR HABITACIÓN
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Habitacion_Crear
    @idTipoHab INT,
    @numeroHabitacion VARCHAR(45)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @numeroHabitacion = LTRIM(RTRIM(@numeroHabitacion));

        IF @numeroHabitacion IS NULL OR @numeroHabitacion = ''
        BEGIN
            THROW 50501,
                'El número de habitación es obligatorio.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipohabitacion
            WHERE idTipoHabitacion = @idTipoHab
        )
        BEGIN
            THROW 50502,
                'El tipo de habitación indicado no existe.',
                1;
        END;

        -- El backend original ya impedía crear
        -- habitaciones con el mismo número.
        IF EXISTS
        (
            SELECT 1
            FROM dbo.habitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE numeroHabitacion = @numeroHabitacion
        )
        BEGIN
            THROW 50503,
                'Ya existe una habitación con ese número.',
                1;
        END;

        INSERT INTO dbo.habitacion
        (
            idTipoHab,
            numeroHabitacion,
            estado
        )
        VALUES
        (
            @idTipoHab,
            @numeroHabitacion,
            1
        );

        DECLARE @nuevoId INT;

        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idHabitacion,
            'Habitación creada exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
