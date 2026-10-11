USE reservasdbV2;
GO

/* =========================================================
   2. ACTUALIZAR RESERVA

   Se mantienen todos los campos del UPDATE original,
   incluidos iva, subtotal y total.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Reserva_Actualizar
    @idReserva INT,
    @idRecepcionista VARCHAR(20),
    @idCliente VARCHAR(20),
    @fechaReserva DATETIME,
    @estadoReserva VARCHAR(25),
    @estado TINYINT,
    @iva DECIMAL(10,2),
    @subTotal DECIMAL(10,2),
    @total DECIMAL(10,2)
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
            THROW 50703,
                'La reserva indicada no existe.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.recepcionista
            WHERE cedula = @idRecepcionista
        )
        BEGIN
            THROW 50704,
                'El recepcionista indicado no existe.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.cliente
            WHERE cedula = @idCliente
        )
        BEGIN
            THROW 50705,
                'El cliente indicado no existe.',
                1;
        END;

        UPDATE dbo.reserva
        SET
            idRecepcionista = @idRecepcionista,
            idCliente = @idCliente,
            fechaReserva = @fechaReserva,
            estadoReserva = @estadoReserva,
            estado = @estado,
            iva = @iva,
            subTotal = @subTotal,
            total = @total
        WHERE idReserva = @idReserva;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idReserva AS idReserva,
            @filasAfectadas AS filasAfectadas,
            'Reserva actualizada exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
