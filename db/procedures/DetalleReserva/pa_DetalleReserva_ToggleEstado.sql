USE reservasdbV2;
GO

/* =========================================================
   3. ACTIVAR / DESACTIVAR DETALLE

   Igual al backend anterior:
       1 -> 0
       0 -> 1

   Al cambiar estado se ejecutará también:
       trg_actualizar_totales_reserva

   Y al reactivar se aplican los triggers de
   traslape y capacidad.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_DetalleReserva_ToggleEstado
    @idDetalleReserva INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.detallereserva WITH (UPDLOCK, HOLDLOCK)
            WHERE idDetalleReserva = @idDetalleReserva
        )
        BEGIN
            THROW 50804,
                'El detalle de reserva indicado no existe.',
                1;
        END;

        UPDATE dbo.detallereserva
        SET estado =
            CASE
                WHEN estado = 1 THEN 0
                ELSE 1
            END
        WHERE idDetalleReserva = @idDetalleReserva;

        DECLARE @nuevoEstado TINYINT;

        SELECT @nuevoEstado = estado
        FROM dbo.detallereserva
        WHERE idDetalleReserva = @idDetalleReserva;

        COMMIT TRANSACTION;

        SELECT
            @idDetalleReserva AS idDetalleReserva,
            @nuevoEstado AS estado,
            1 AS filasAfectadas;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
