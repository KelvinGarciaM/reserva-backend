USE reservasdbV2;
GO

/* =========================================================
   4. ACTUALIZAR TIPO DE HABITACIÓN
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_Actualizar
    @idTipoHabitacion INT,
    @nombreTipoHab VARCHAR(45),
    @descripcion VARCHAR(100),
    @capacidadMaxima INT,
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @nombreTipoHab = LTRIM(RTRIM(@nombreTipoHab));
        SET @descripcion = LTRIM(RTRIM(@descripcion));

        IF @idTipoHabitacion IS NULL
           OR @idTipoHabitacion <= 0
        BEGIN
            THROW 50008,
                'El ID del tipo de habitación debe ser mayor que cero.',
                1;
        END;

        IF @nombreTipoHab IS NULL
           OR @nombreTipoHab = ''
        BEGIN
            THROW 50009,
                'El nombre del tipo de habitación es obligatorio.',
                1;
        END;

        IF @descripcion IS NULL
           OR @descripcion = ''
        BEGIN
            THROW 50010,
                'La descripción del tipo de habitación es obligatoria.',
                1;
        END;

        IF @capacidadMaxima IS NULL
           OR @capacidadMaxima <= 0
        BEGIN
            THROW 50011,
                'La capacidad máxima debe ser mayor que cero.',
                1;
        END;

        IF @estado IS NULL
           OR @estado NOT IN (0, 1)
        BEGIN
            THROW 50012,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE idTipoHabitacion = @idTipoHabitacion
        )
        BEGIN
            THROW 50013,
                'El tipo de habitación que intenta actualizar no existe.',
                1;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTipoHab = @nombreTipoHab
              AND idTipoHabitacion <> @idTipoHabitacion
        )
        BEGIN
            THROW 50014,
                'Ya existe otro tipo de habitación con ese nombre.',
                1;
        END;

        UPDATE dbo.TipoHabitacion
        SET
            nombreTipoHab = @nombreTipoHab,
            descripcion = @descripcion,
            capacidadMaxima = @capacidadMaxima,
            estado = @estado
        WHERE idTipoHabitacion = @idTipoHabitacion;

        DECLARE @filasAfectadas INT;

        SET @filasAfectadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTipoHabitacion AS idTipoHabitacion,
            @filasAfectadas AS filasAfectadas,
            'Tipo de habitación actualizado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
