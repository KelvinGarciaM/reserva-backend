USE reservasdbV2;
GO

/* =========================================================
   3. ACTIVAR / DESACTIVAR USUARIO

   Reemplaza:
       SET estado = NOT estado
   Alterna el estado lógico del usuario entre activo e inactivo.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Usuario_ToggleEstado
    @id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.users WITH (UPDLOCK, HOLDLOCK)
            WHERE id = @id
        )
        BEGIN
            THROW 50611,
                'El usuario no existe.',
                1;
        END;

        UPDATE dbo.users
        SET estado =
            CASE
                WHEN estado = 1 THEN 0
                ELSE 1
            END
        WHERE id = @id;

        DECLARE @estadoActual TINYINT;

        SELECT @estadoActual = estado
        FROM dbo.users
        WHERE id = @id;

        COMMIT TRANSACTION;

        SELECT
            @id AS id,
            @estadoActual AS estado,
            'Estado del usuario actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
