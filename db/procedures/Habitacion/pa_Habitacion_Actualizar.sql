USE reservasdbV2;
GO

/* =========================================================
   2. ACTUALIZAR HABITACIÓN
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Habitacion_Actualizar
    @idHabitacion INT,
    @idTipoHab INT,
    @numeroHabitacion VARCHAR(45),
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @numeroHabitacion = LTRIM(RTRIM(@numeroHabitacion));

        IF @idHabitacion IS NULL OR @idHabitacion <= 0
        BEGIN
            THROW 50504,
                'El ID de la habitación debe ser mayor que cero.',
                1;
        END;

        IF @numeroHabitacion IS NULL OR @numeroHabitacion = ''
        BEGIN
            THROW 50505,
                'El número de habitación es obligatorio.',
                1;
        END;

        IF @estado NOT IN (0, 1)
        BEGIN
            THROW 50506,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.habitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE idHabitacion = @idHabitacion
        )
        BEGIN
            THROW 50507,
                'La habitación que intenta actualizar no existe.',
                1;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipohabitacion
            WHERE idTipoHabitacion = @idTipoHab
        )
        BEGIN
            THROW 50508,
                'El tipo de habitación indicado no existe.',
                1;
        END;

        UPDATE dbo.habitacion
        SET
            idTipoHab = @idTipoHab,
            numeroHabitacion = @numeroHabitacion,
            estado = @estado
        WHERE idHabitacion = @idHabitacion;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idHabitacion AS idHabitacion,
            @filasAfectadas AS filasAfectadas,
            'Habitación actualizada exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
