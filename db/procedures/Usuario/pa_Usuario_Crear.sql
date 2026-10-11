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
