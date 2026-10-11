USE reservasdbV2;
GO

/* =========================================================
   1. CREAR CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Cliente_Crear
    @cedula VARCHAR(20),
    @idTipoCliente INT,
    @nombre VARCHAR(45),
    @apellidos VARCHAR(45),
    @telefono VARCHAR(20),
    @direccion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @cedula = LTRIM(RTRIM(@cedula));
        SET @nombre = LTRIM(RTRIM(@nombre));
        SET @apellidos = LTRIM(RTRIM(@apellidos));
        SET @telefono = LTRIM(RTRIM(@telefono));
        SET @direccion = LTRIM(RTRIM(@direccion));

        IF @cedula IS NULL OR @cedula = ''
            THROW 50301, 'La cédula es obligatoria.', 1;

        IF @nombre IS NULL OR @nombre = ''
            THROW 50302, 'El nombre es obligatorio.', 1;

        IF @apellidos IS NULL OR @apellidos = ''
            THROW 50303, 'Los apellidos son obligatorios.', 1;

        IF @telefono IS NULL OR @telefono = ''
            THROW 50304, 'El teléfono es obligatorio.', 1;

        IF @direccion IS NULL OR @direccion = ''
            THROW 50305, 'La dirección es obligatoria.', 1;

        BEGIN TRANSACTION;

        -- Verificar que no exista la cédula
        IF EXISTS (
            SELECT 1
            FROM dbo.cliente WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50306,
                'Ya existe un cliente con esa cédula.',
                1;
        END;

        -- Verificar que exista el tipo de cliente
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50307,
                'El tipo de cliente indicado no existe.',
                1;
        END;

        INSERT INTO dbo.cliente
        (
            cedula,
            idTipoCliente,
            nombre,
            apellidos,
            telefono,
            direccion,
            estado
        )
        VALUES
        (
            @cedula,
            @idTipoCliente,
            @nombre,
            @apellidos,
            @telefono,
            @direccion,
            1
        );

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            'Cliente registrado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
