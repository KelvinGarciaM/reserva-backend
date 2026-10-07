USE reservasdbV2;
GO


/* =========================================================
   1. CREAR USUARIO

   La contraseña llega YA cifrada desde Go con bcrypt.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Usuario_Crear
    @name VARCHAR(100),
    @email VARCHAR(150),
    @password VARCHAR(255),
    @role VARCHAR(30) = NULL,
    @image VARCHAR(255) = NULL,
    @cedula VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @name = LTRIM(RTRIM(@name));
        SET @email = LTRIM(RTRIM(@email));

        IF @cedula IS NOT NULL
            SET @cedula = NULLIF(LTRIM(RTRIM(@cedula)), '');

        IF @role IS NOT NULL
            SET @role = NULLIF(LTRIM(RTRIM(@role)), '');

        IF @image IS NOT NULL
            SET @image = NULLIF(LTRIM(RTRIM(@image)), '');

        IF @name IS NULL OR @name = ''
            THROW 50601, 'El nombre es obligatorio.', 1;

        IF @email IS NULL OR @email = ''
            THROW 50602, 'El correo electrónico es obligatorio.', 1;

        IF @password IS NULL OR @password = ''
            THROW 50603, 'La contraseña es obligatoria.', 1;

        BEGIN TRANSACTION;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.users WITH (UPDLOCK, HOLDLOCK)
            WHERE LOWER(email) = LOWER(@email)
        )
        BEGIN
            THROW 50604,
                'El correo electrónico ya está registrado.',
                1;
        END;

        -- Si el usuario está relacionado con un recepcionista,
        -- la cédula debe existir.
        IF @cedula IS NOT NULL
           AND NOT EXISTS
        (
            SELECT 1
            FROM dbo.recepcionista
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50605,
                'El recepcionista asociado no existe.',
                1;
        END;

        INSERT INTO dbo.users
        (
            name,
            email,
            password,
            role,
            image,
            cedula,
            estado
        )
        VALUES
        (
            @name,
            @email,
            @password,
            @role,
            @image,
            @cedula,
            1
        );

        DECLARE @nuevoId INT;
        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS id,
            'Usuario creado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   2. ACTUALIZAR USUARIO

   @password = NULL
       → conserva la contraseña anterior.

   @estado = NULL
       → conserva el estado anterior.

   Esto permite reproducir la lógica actual del backend:
   - con nueva contraseña se puede enviar estado;
   - sin nueva contraseña se conserva el estado.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Usuario_Actualizar
    @id INT,
    @name VARCHAR(100),
    @email VARCHAR(150),
    @role VARCHAR(30) = NULL,
    @image VARCHAR(255) = NULL,
    @cedula VARCHAR(20) = NULL,
    @password VARCHAR(255) = NULL,
    @estado TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @name = LTRIM(RTRIM(@name));
        SET @email = LTRIM(RTRIM(@email));

        IF @cedula IS NOT NULL
            SET @cedula = NULLIF(LTRIM(RTRIM(@cedula)), '');

        IF @role IS NOT NULL
            SET @role = NULLIF(LTRIM(RTRIM(@role)), '');

        IF @image IS NOT NULL
            SET @image = NULLIF(LTRIM(RTRIM(@image)), '');

        IF @id IS NULL OR @id <= 0
            THROW 50606, 'El ID del usuario no es válido.', 1;

        IF @estado IS NOT NULL
           AND @estado NOT IN (0, 1)
        BEGIN
            THROW 50607,
                'El estado debe ser 0, 1 o NULL.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.users WITH (UPDLOCK, HOLDLOCK)
            WHERE id = @id
        )
        BEGIN
            THROW 50608,
                'El usuario que intenta actualizar no existe.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.users
            WHERE LOWER(email) = LOWER(@email)
              AND id <> @id
        )
        BEGIN
            THROW 50609,
                'El correo electrónico ya está registrado por otro usuario.',
                1;
        END;

        IF @cedula IS NOT NULL
           AND NOT EXISTS
        (
            SELECT 1
            FROM dbo.recepcionista
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50610,
                'El recepcionista asociado no existe.',
                1;
        END;

        UPDATE dbo.users
        SET
            name = @name,
            role = @role,
            email = @email,
            password = COALESCE(@password, password),
            image = @image,
            cedula = @cedula,
            estado = COALESCE(@estado, estado)
        WHERE id = @id;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @id AS id,
            @filasAfectadas AS filasAfectadas,
            'Usuario actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   3. ACTIVAR / DESACTIVAR USUARIO

   Reemplaza:
       SET estado = NOT estado
   Alterna el estado lógico del usuario entre activo e inactivo.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Usuario_ToggleEstado
    @id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.users WITH (UPDLOCK, HOLDLOCK)
            WHERE id = @id
        )
        BEGIN
            THROW 50611,
                'El usuario no existe.',
                1;
        END;

        UPDATE dbo.users
        SET estado =
            CASE
                WHEN estado = 1 THEN 0
                ELSE 1
            END
        WHERE id = @id;

        DECLARE @estadoActual TINYINT;

        SELECT @estadoActual = estado
        FROM dbo.users
        WHERE id = @id;

        COMMIT TRANSACTION;

        SELECT
            @id AS id,
            @estadoActual AS estado,
            'Estado del usuario actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO