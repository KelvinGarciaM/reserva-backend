USE reservasdbV2;
GO

/* =========================================================
   2. ACTUALIZAR DETALLE

   fechaEntrada y fechaSalida son opcionales.

   Si las fechas llegan en NULL, se conservan los valores existentes.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_DetalleReserva_Actualizar
    @idDetalleReserva INT,
    @idHabitacion INT,
    @idTarifa INT,
    @cantidadPersonas INT,
    @precioAplicado DECIMAL(10,2),
    @fechaEntrada DATETIME = NULL,
    @fechaSalida DATETIME = NULL,
    @iva DECIMAL(10,2),
    @subTotal DECIMAL(10,2),
    @total DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.detallereserva
        SET
            idHabitacion = @idHabitacion,
            idTarifa = @idTarifa,
            cantidadPersonas = @cantidadPersonas,
            precioAplicado = @precioAplicado,

            fechaEntrada =
                COALESCE(@fechaEntrada, fechaEntrada),

            fechaSalida =
                COALESCE(@fechaSalida, fechaSalida),

            iva = @iva,
            subTotal = @subTotal,
            total = @total

        WHERE idDetalleReserva = @idDetalleReserva;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idDetalleReserva AS idDetalleReserva,
            @filasAfectadas AS filasAfectadas,
            'Detalle de reserva actualizado.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
