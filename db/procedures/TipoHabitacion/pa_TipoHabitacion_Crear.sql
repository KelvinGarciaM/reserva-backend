USE reservasdbV2;
GO

/* =========================================================
   3. CREAR TIPO DE HABITACIÓN
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_Crear
    @nombreTipoHab VARCHAR(45),
    @descripcion VARCHAR(100),
    @capacidadMaxima INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @nombreTipoHab = LTRIM(RTRIM(@nombreTipoHab));
        SET @descripcion = LTRIM(RTRIM(@descripcion));

        IF @nombreTipoHab IS NULL
           OR @nombreTipoHab = ''
        BEGIN
            THROW 50004,
                'El nombre del tipo de habitación es obligatorio.',
                1;
        END;

        IF @descripcion IS NULL
           OR @descripcion = ''
        BEGIN
            THROW 50005,
                'La descripción del tipo de habitación es obligatoria.',
                1;
        END;

        IF @capacidadMaxima IS NULL
           OR @capacidadMaxima <= 0
        BEGIN
            THROW 50006,
                'La capacidad máxima debe ser mayor que cero.',
                1;
        END;

        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTipoHab = @nombreTipoHab
        )
        BEGIN
            THROW 50007,
                'Ya existe un tipo de habitación con ese nombre.',
                1;
        END;

        INSERT INTO dbo.TipoHabitacion
        (
            nombreTipoHab,
            descripcion,
            capacidadMaxima,
            estado
        )
        VALUES
        (
            @nombreTipoHab,
            @descripcion,
            @capacidadMaxima,
            1
        );

        DECLARE @nuevoId INT;

        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idTipoHabitacion,
            'Tipo de habitación registrado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
