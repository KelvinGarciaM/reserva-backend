USE reservasdbV2;
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
