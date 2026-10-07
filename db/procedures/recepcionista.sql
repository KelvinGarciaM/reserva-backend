USE reservasdbV2;
GO

/* ============================================
   1. LISTAR RECEPCIONISTAS
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Listar
    @soloActivos TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @soloActivos IS NOT NULL
       AND @soloActivos NOT IN (0, 1)
    BEGIN
        THROW 50201,
            'El parámetro soloActivos debe ser 0, 1 o NULL.',
            1;
    END;

    SELECT
        cedula,
        nombre,
        apellidos,
        telefono,
        correo,
        estado
    FROM dbo.recepcionista
    WHERE @soloActivos IS NULL
       OR estado = @soloActivos
    ORDER BY nombre, apellidos;
END;
GO


/* ============================================
   2. OBTENER POR CÉDULA
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_ObtenerPorCedula
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SET @cedula = LTRIM(RTRIM(@cedula));

    IF @cedula IS NULL OR @cedula = ''
    BEGIN
        THROW 50202,
            'La cédula es obligatoria.',
            1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.recepcionista
        WHERE cedula = @cedula
    )
    BEGIN
        THROW 50203,
            'El recepcionista solicitado no existe.',
            1;
    END;

    SELECT
        cedula,
        nombre,
        apellidos,
        telefono,
        correo,
        estado
    FROM dbo.recepcionista
    WHERE cedula = @cedula;
END;
GO


/* ============================================
   3. CREAR RECEPCIONISTA
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Crear
    @cedula VARCHAR(20),
    @nombre VARCHAR(45),
    @apellidos VARCHAR(45),
    @telefono VARCHAR(20),
    @correo VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @cedula = LTRIM(RTRIM(@cedula));
        SET @nombre = LTRIM(RTRIM(@nombre));
        SET @apellidos = LTRIM(RTRIM(@apellidos));
        SET @telefono = LTRIM(RTRIM(@telefono));
        SET @correo = LTRIM(RTRIM(@correo));

        IF @cedula IS NULL OR @cedula = ''
            THROW 50204, 'La cédula es obligatoria.', 1;

        IF @nombre IS NULL OR @nombre = ''
            THROW 50205, 'El nombre es obligatorio.', 1;

        IF @apellidos IS NULL OR @apellidos = ''
            THROW 50206, 'Los apellidos son obligatorios.', 1;

        IF @telefono IS NULL OR @telefono = ''
            THROW 50207, 'El teléfono es obligatorio.', 1;

        IF @correo IS NULL OR @correo = ''
            THROW 50208, 'El correo es obligatorio.', 1;

        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1
            FROM dbo.recepcionista WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50209,
                'Ya existe un recepcionista con esa cédula.',
                1;
        END;

        INSERT INTO dbo.recepcionista
        (
            cedula,
            nombre,
            apellidos,
            telefono,
            correo,
            estado
        )
        VALUES
        (
            @cedula,
            @nombre,
            @apellidos,
            @telefono,
            @correo,
            1
        );

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            'Recepcionista registrado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* ============================================
   4. ACTUALIZAR
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Actualizar
    @cedula VARCHAR(20),
    @nombre VARCHAR(45),
    @apellidos VARCHAR(45),
    @telefono VARCHAR(20),
    @correo VARCHAR(100),
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @cedula = LTRIM(RTRIM(@cedula));
        SET @nombre = LTRIM(RTRIM(@nombre));
        SET @apellidos = LTRIM(RTRIM(@apellidos));
        SET @telefono = LTRIM(RTRIM(@telefono));
        SET @correo = LTRIM(RTRIM(@correo));

        IF @estado NOT IN (0, 1)
        BEGIN
            THROW 50210,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.recepcionista WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50211,
                'El recepcionista que intenta actualizar no existe.',
                1;
        END;

        UPDATE dbo.recepcionista
        SET
            nombre = @nombre,
            apellidos = @apellidos,
            telefono = @telefono,
            correo = @correo,
            estado = @estado
        WHERE cedula = @cedula;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @filasAfectadas AS filasAfectadas,
            'Recepcionista actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* ============================================
   5. ELIMINAR LÓGICAMENTE
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Eliminar
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.recepcionista WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50212,
                'El recepcionista no existe.',
                1;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.recepcionista
            WHERE cedula = @cedula
              AND estado = 0
        )
        BEGIN
            THROW 50213,
                'El recepcionista ya se encuentra inactivo.',
                1;
        END;

        UPDATE dbo.recepcionista
        SET estado = 0
        WHERE cedula = @cedula;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @filasAfectadas AS filasAfectadas,
            'Recepcionista desactivado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* ============================================
   6. ACTIVAR / DESACTIVAR
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_ToggleEstado
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.recepcionista
        WHERE cedula = @cedula
    )
    BEGIN
        THROW 50214,
            'El recepcionista no existe.',
            1;
    END;

    UPDATE dbo.recepcionista
    SET estado =
        CASE
            WHEN estado = 1 THEN 0
            ELSE 1
        END
    WHERE cedula = @cedula;

    SELECT
        cedula,
        estado,
        'Estado actualizado exitosamente.' AS mensaje
    FROM dbo.recepcionista
    WHERE cedula = @cedula;
END;
GO


/* ============================================
   7. BUSCAR
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Buscar
    @busqueda VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SET @busqueda = LTRIM(RTRIM(@busqueda));

    SELECT
        cedula,
        nombre,
        apellidos,
        telefono,
        correo,
        estado
    FROM dbo.recepcionista
    WHERE
        cedula LIKE @busqueda + '%'
        OR nombre LIKE @busqueda + '%'
        OR apellidos LIKE @busqueda + '%'
        OR telefono LIKE @busqueda + '%'
        OR correo LIKE @busqueda + '%'
    ORDER BY nombre, apellidos;
END;
GO