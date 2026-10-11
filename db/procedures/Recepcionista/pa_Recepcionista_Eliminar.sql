USE reservasdbV2;
GO

/* ============================================
   5. ELIMINAR LÓGICAMENTE
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Eliminar
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.recepcionista WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50212,
                'El recepcionista no existe.',
                1;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.recepcionista
            WHERE cedula = @cedula
              AND estado = 0
        )
        BEGIN
            THROW 50213,
                'El recepcionista ya se encuentra inactivo.',
                1;
        END;

        UPDATE dbo.recepcionista
        SET estado = 0
        WHERE cedula = @cedula;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @filasAfectadas AS filasAfectadas,
            'Recepcionista desactivado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
