USE reservasdbV2;
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
