USE reservasdbV2;
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
