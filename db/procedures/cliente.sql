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


/* =========================================================
   2. ACTUALIZAR CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Cliente_Actualizar
    @cedula VARCHAR(20),
    @idTipoCliente INT,
    @nombre VARCHAR(45),
    @apellidos VARCHAR(45),
    @telefono VARCHAR(20),
    @direccion VARCHAR(100),
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
        SET @direccion = LTRIM(RTRIM(@direccion));

        IF @estado NOT IN (0, 1)
        BEGIN
            THROW 50308,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        -- Comprobar cliente
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.cliente WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50309,
                'El cliente que intenta actualizar no existe.',
                1;
        END;

        -- Comprobar tipo de cliente
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50310,
                'El tipo de cliente indicado no existe.',
                1;
        END;

        UPDATE dbo.cliente
        SET
            idTipoCliente = @idTipoCliente,
            nombre = @nombre,
            apellidos = @apellidos,
            telefono = @telefono,
            direccion = @direccion,
            estado = @estado
        WHERE cedula = @cedula;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @filasAfectadas AS filasAfectadas,
            'Cliente actualizado exitosamente.' AS mensaje;

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

   @nuevoEstado:
       0 = desactivar
       1 = activar
       NULL = invertir estado actual (toggle)
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Cliente_CambiarEstado
    @cedula VARCHAR(20),
    @nuevoEstado TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @cedula = LTRIM(RTRIM(@cedula));

        IF @nuevoEstado IS NOT NULL
           AND @nuevoEstado NOT IN (0, 1)
        BEGIN
            THROW 50311,
                'El nuevo estado debe ser 0, 1 o NULL.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.cliente WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50312,
                'El cliente no existe.',
                1;
        END;

        UPDATE dbo.cliente
        SET estado =
            CASE
                WHEN @nuevoEstado IS NULL THEN
                    CASE
                        WHEN estado = 1 THEN 0
                        ELSE 1
                    END
                ELSE @nuevoEstado
            END
        WHERE cedula = @cedula;

        DECLARE @estadoActual TINYINT;

        SELECT @estadoActual = estado
        FROM dbo.cliente
        WHERE cedula = @cedula;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @estadoActual AS estado,
            'Estado del cliente actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO