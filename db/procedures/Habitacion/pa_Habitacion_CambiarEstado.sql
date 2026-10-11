USE reservasdbV2;
GO

/* =========================================================
   3. CAMBIAR ESTADO

   Lo utilizaremos para el DELETE lógico.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Habitacion_CambiarEstado
    @idHabitacion INT,
    @nuevoEstado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF @nuevoEstado NOT IN (0, 1)
        BEGIN
            THROW 50509,
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
            THROW 50510,
                'La habitación no existe.',
                1;
        END;

        UPDATE dbo.habitacion
        SET estado = @nuevoEstado
        WHERE idHabitacion = @idHabitacion;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idHabitacion AS idHabitacion,
            @nuevoEstado AS estado,
            @filasAfectadas AS filasAfectadas,
            CASE
                WHEN @nuevoEstado = 1
                    THEN 'Habitación activada exitosamente.'
                ELSE
                    'Habitación eliminada exitosamente.'
            END AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
