USE reservasdbV2;
GO

/* =========================================================
   3. TOGGLE DEL ESTADO GENERAL

   Equivale al antiguo:
       SET estado = NOT estado

   Importante:
   NO modifica los detalles de la reserva.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Reserva_ToggleEstado
    @idReserva INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.reserva WITH (UPDLOCK, HOLDLOCK)
            WHERE idReserva = @idReserva
        )
        BEGIN
            THROW 50706,
                'La reserva indicada no existe.',
                1;
        END;

        UPDATE dbo.reserva
        SET estado =
            CASE
                WHEN estado = 0 THEN 1
                ELSE 0
            END
        WHERE idReserva = @idReserva;

        DECLARE @nuevoEstado TINYINT;

        SELECT @nuevoEstado = estado
        FROM dbo.reserva
        WHERE idReserva = @idReserva;

        COMMIT TRANSACTION;

        SELECT
            @idReserva AS idReserva,
            @nuevoEstado AS estado,
            'Estado actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
