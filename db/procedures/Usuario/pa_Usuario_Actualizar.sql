USE reservasdbV2;
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
