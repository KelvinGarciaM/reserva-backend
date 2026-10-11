USE reservasdbV2;
GO

/* =========================================================
   2. OBTENER TIPO DE HABITACIÓN POR ID
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_ObtenerPorId
    @idTipoHabitacion INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @idTipoHabitacion IS NULL
           OR @idTipoHabitacion <= 0
        BEGIN
            THROW 50002,
                'El ID del tipo de habitación debe ser mayor que cero.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion
            WHERE idTipoHabitacion = @idTipoHabitacion
        )
        BEGIN
            THROW 50003,
                'El tipo de habitación solicitado no existe.',
                1;
        END;

        SELECT
            idTipoHabitacion,
            nombreTipoHab,
            descripcion,
            capacidadMaxima,
            estado
        FROM dbo.TipoHabitacion
        WHERE idTipoHabitacion = @idTipoHabitacion;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
