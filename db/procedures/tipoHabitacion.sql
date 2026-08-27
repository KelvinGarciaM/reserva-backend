USE reservasdbV2;
GO

/* =========================================================
   1. LISTAR TIPOS DE HABITACIÓN
   @soloActivos:
       NULL = todos
       1    = activos
       0    = inactivos
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_TipoHabitacion_Listar
    @soloActivos TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @soloActivos IS NOT NULL
           AND @soloActivos NOT IN (0, 1)
        BEGIN
            THROW 50001,
                'El parámetro soloActivos debe ser 0, 1 o NULL.',
                1;
        END;

        SELECT
            idTipoHabitacion,
            nombreTipoHab,
            descripcion,
            capacidadMaxima,
            estado
        FROM dbo.TipoHabitacion
        WHERE @soloActivos IS NULL
           OR estado = @soloActivos
        ORDER BY nombreTipoHab ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   2. OBTENER TIPO DE HABITACIÓN POR ID
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_TipoHabitacion_ObtenerPorId
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

/* =========================================================
   3. CREAR TIPO DE HABITACIÓN
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_TipoHabitacion_Crear
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

/* =========================================================
   4. ACTUALIZAR TIPO DE HABITACIÓN
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_TipoHabitacion_Actualizar
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

/* =========================================================
   5. ELIMINAR LÓGICAMENTE UN TIPO DE HABITACIÓN
   No borra el registro: cambia estado a 0
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_TipoHabitacion_Eliminar
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