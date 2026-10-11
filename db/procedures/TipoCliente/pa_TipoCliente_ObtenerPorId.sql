USE reservasdbV2;
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
