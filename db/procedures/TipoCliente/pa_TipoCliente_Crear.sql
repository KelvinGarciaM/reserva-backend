USE reservasdbV2;
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
