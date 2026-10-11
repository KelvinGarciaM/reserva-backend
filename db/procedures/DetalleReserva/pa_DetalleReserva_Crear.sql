USE reservasdbV2;
GO

/* =========================================================
   1. CREAR DETALLE DE RESERVA

   Los cálculos de:
   - precio aplicado
   - subtotal
   - IVA
   - total

   siguen realizándose en Go, igual que en el backend original.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_DetalleReserva_Crear
    @idHabitacion INT,
    @idReserva INT,
    @idTarifa INT,
    @cantidadPersonas INT,
    @precioAplicado DECIMAL(10,2),
    @fechaEntrada DATETIME,
    @fechaSalida DATETIME,
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
            FROM dbo.habitacion
            WHERE idHabitacion = @idHabitacion
        )
        BEGIN
            THROW 50801,
                'La habitación indicada no existe.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.reserva
            WHERE idReserva = @idReserva
        )
        BEGIN
            THROW 50802,
                'La reserva indicada no existe.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tarifa
            WHERE idTarifa = @idTarifa
        )
        BEGIN
            THROW 50803,
                'La tarifa indicada no existe.',
                1;
        END;

        INSERT INTO dbo.detallereserva
        (
            idHabitacion,
            idReserva,
            idTarifa,
            cantidadPersonas,
            precioAplicado,
            fechaEntrada,
            fechaSalida,
            iva,
            subTotal,
            total
        )
        VALUES
        (
            @idHabitacion,
            @idReserva,
            @idTarifa,
            @cantidadPersonas,
            @precioAplicado,
            @fechaEntrada,
            @fechaSalida,
            @iva,
            @subTotal,
            @total
        );

        DECLARE @nuevoId INT;
        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idDetalleReserva,
            'Detalle de reserva creado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
