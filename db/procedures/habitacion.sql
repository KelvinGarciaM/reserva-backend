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