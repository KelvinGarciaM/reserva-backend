USE reservasdbV2;
GO

/* =========================================================
   5. ELIMINAR LÓGICAMENTE UN TIPO DE HABITACIÓN
   No borra el registro: cambia estado a 0
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_Eliminar
    @idTipoHabitacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @idTipoHabitacion IS NULL
           OR @idTipoHabitacion <= 0
        BEGIN
            THROW 50015,
                'El ID del tipo de habitación debe ser mayor que cero.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE idTipoHabitacion = @idTipoHabitacion
        )
        BEGIN
            THROW 50016,
                'El tipo de habitación que intenta eliminar no existe.',
                1;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion
            WHERE idTipoHabitacion = @idTipoHabitacion
              AND estado = 0
        )
        BEGIN
            THROW 50017,
                'El tipo de habitación ya se encuentra inactivo.',
                1;
        END;

        UPDATE dbo.TipoHabitacion
        SET estado = 0
        WHERE idTipoHabitacion = @idTipoHabitacion;

        DECLARE @filasAfectadas INT;

        SET @filasAfectadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTipoHabitacion AS idTipoHabitacion,
            @filasAfectadas AS filasAfectadas,
            'Tipo de habitación eliminado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
