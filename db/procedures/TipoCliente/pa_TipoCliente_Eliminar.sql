USE reservasdbV2;
GO

/* =========================================================
   5. ELIMINAR LÓGICAMENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Eliminar
    @idTipoCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF @idTipoCliente IS NULL
           OR @idTipoCliente <= 0
        BEGIN
            THROW 50113,
                'El ID del tipo de cliente debe ser mayor que cero.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50114,
                'El tipo de cliente que intenta eliminar no existe.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
              AND estado = 0
        )
        BEGIN
            THROW 50115,
                'El tipo de cliente ya se encuentra inactivo.',
                1;
        END;

        UPDATE dbo.tipocliente
        SET estado = 0
        WHERE idTipoCliente = @idTipoCliente;

        DECLARE @filasAfectadas INT;

        SET @filasAfectadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTipoCliente AS idTipoCliente,
            @filasAfectadas AS filasAfectadas,
            'Tipo de cliente eliminado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
