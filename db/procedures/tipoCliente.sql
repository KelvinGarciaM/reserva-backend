USE reservasdbV2;
GO


/* =========================================================
   1. LISTAR TIPOS DE CLIENTE
   @soloActivos:
       NULL = todos
       1    = activos
       0    = inactivos
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Listar
    @soloActivos TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF @soloActivos IS NOT NULL
           AND @soloActivos NOT IN (0, 1)
        BEGIN
            THROW 50101,
                'El parámetro soloActivos debe ser 0, 1 o NULL.',
                1;
        END;

        SELECT
            idTipoCliente,
            nombreTipoC,
            descripcion,
            descuentoBase,
            estado
        FROM dbo.tipocliente
        WHERE @soloActivos IS NULL
           OR estado = @soloActivos
        ORDER BY nombreTipoC ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO


/* =========================================================
   2. OBTENER TIPO DE CLIENTE POR ID
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_ObtenerPorId
    @idTipoCliente INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF @idTipoCliente IS NULL
           OR @idTipoCliente <= 0
        BEGIN
            THROW 50102,
                'El ID del tipo de cliente debe ser mayor que cero.',
                1;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50103,
                'El tipo de cliente solicitado no existe.',
                1;
        END;

        SELECT
            idTipoCliente,
            nombreTipoC,
            descripcion,
            descuentoBase,
            estado
        FROM dbo.tipocliente
        WHERE idTipoCliente = @idTipoCliente;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO


/* =========================================================
   3. CREAR TIPO DE CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Crear
    @nombreTipoC VARCHAR(45),
    @descripcion VARCHAR(100),
    @descuentoBase DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @nombreTipoC = LTRIM(RTRIM(@nombreTipoC));
        SET @descripcion = LTRIM(RTRIM(@descripcion));

        IF @nombreTipoC IS NULL
           OR @nombreTipoC = ''
        BEGIN
            THROW 50104,
                'El nombre del tipo de cliente es obligatorio.',
                1;
        END;

        IF @descuentoBase IS NULL
           OR @descuentoBase < 0
        BEGIN
            THROW 50105,
                'El descuento base no puede ser negativo.',
                1;
        END;

        BEGIN TRANSACTION;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTipoC = @nombreTipoC
        )
        BEGIN
            THROW 50106,
                'Ya existe un tipo de cliente con ese nombre.',
                1;
        END;

        INSERT INTO dbo.tipocliente
        (
            nombreTipoC,
            descripcion,
            descuentoBase,
            estado
        )
        VALUES
        (
            @nombreTipoC,
            @descripcion,
            @descuentoBase,
            1
        );

        DECLARE @nuevoId INT;

        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idTipoCliente,
            'Tipo de cliente registrado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   4. ACTUALIZAR TIPO DE CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Actualizar
    @idTipoCliente INT,
    @nombreTipoC VARCHAR(45),
    @descripcion VARCHAR(100),
    @descuentoBase DECIMAL(10,2),
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @nombreTipoC = LTRIM(RTRIM(@nombreTipoC));
        SET @descripcion = LTRIM(RTRIM(@descripcion));

        IF @idTipoCliente IS NULL
           OR @idTipoCliente <= 0
        BEGIN
            THROW 50107,
                'El ID del tipo de cliente debe ser mayor que cero.',
                1;
        END;

        IF @nombreTipoC IS NULL
           OR @nombreTipoC = ''
        BEGIN
            THROW 50108,
                'El nombre del tipo de cliente es obligatorio.',
                1;
        END;

        IF @descuentoBase IS NULL
           OR @descuentoBase < 0
        BEGIN
            THROW 50109,
                'El descuento base no puede ser negativo.',
                1;
        END;

        IF @estado IS NULL
           OR @estado NOT IN (0, 1)
        BEGIN
            THROW 50110,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50111,
                'El tipo de cliente que intenta actualizar no existe.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTipoC = @nombreTipoC
              AND idTipoCliente <> @idTipoCliente
        )
        BEGIN
            THROW 50112,
                'Ya existe otro tipo de cliente con ese nombre.',
                1;
        END;

        UPDATE dbo.tipocliente
        SET
            nombreTipoC = @nombreTipoC,
            descripcion = @descripcion,
            descuentoBase = @descuentoBase,
            estado = @estado
        WHERE idTipoCliente = @idTipoCliente;

        DECLARE @filasAfectadas INT;

        SET @filasAfectadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTipoCliente AS idTipoCliente,
            @filasAfectadas AS filasAfectadas,
            'Tipo de cliente actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   5. ELIMINAR LÓGICAMENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Eliminar
    @idTipoCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF @idTipoCliente IS NULL
           OR @idTipoCliente <= 0
        BEGIN
            THROW 50113,
                'El ID del tipo de cliente debe ser mayor que cero.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50114,
                'El tipo de cliente que intenta eliminar no existe.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
              AND estado = 0
        )
        BEGIN
            THROW 50115,
                'El tipo de cliente ya se encuentra inactivo.',
                1;
        END;

        UPDATE dbo.tipocliente
        SET estado = 0
        WHERE idTipoCliente = @idTipoCliente;

        DECLARE @filasAfectadas INT;

        SET @filasAfectadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTipoCliente AS idTipoCliente,
            @filasAfectadas AS filasAfectadas,
            'Tipo de cliente eliminado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   6. ACTIVAR / DESACTIVAR
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_ToggleEstado
    @idTipoCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50116,
                'El tipo de cliente no existe.',
                1;
        END;

        UPDATE dbo.tipocliente
        SET estado =
            CASE
                WHEN estado = 1 THEN 0
                ELSE 1
            END
        WHERE idTipoCliente = @idTipoCliente;

        SELECT
            idTipoCliente,
            estado,
            'Estado actualizado exitosamente.' AS mensaje
        FROM dbo.tipocliente
        WHERE idTipoCliente = @idTipoCliente;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO


/* =========================================================
   7. BUSCAR TIPOS DE CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Buscar
    @busqueda VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        idTipoCliente,
        nombreTipoC,
        descripcion,
        descuentoBase,
        estado
    FROM dbo.tipocliente
    WHERE
        CAST(idTipoCliente AS VARCHAR(20)) LIKE @busqueda + '%'
        OR nombreTipoC LIKE @busqueda + '%'
        OR descripcion LIKE @busqueda + '%'
    ORDER BY nombreTipoC;
END;
GO