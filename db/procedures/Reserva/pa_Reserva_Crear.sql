USE reservasdbV2;
GO

/* =========================================================
   1. CREAR RESERVA
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Reserva_Crear
    @idRecepcionista VARCHAR(20),
    @idCliente VARCHAR(20),
    @fechaReserva DATETIME,
    @estadoReserva VARCHAR(25),
    @iva DECIMAL(10,2),
    @subTotal DECIMAL(10,2),
    @total DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Mantenemos las mismas relaciones que ya exige la FK.
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.recepcionista
            WHERE cedula = @idRecepcionista
        )
        BEGIN
            THROW 50701,
                'El recepcionista indicado no existe.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.cliente
            WHERE cedula = @idCliente
        )
        BEGIN
            THROW 50702,
                'El cliente indicado no existe.',
                1;
        END;

        INSERT INTO dbo.reserva
        (
            idRecepcionista,
            idCliente,
            fechaReserva,
            estadoReserva,
            iva,
            subTotal,
            total
        )
        VALUES
        (
            @idRecepcionista,
            @idCliente,
            @fechaReserva,
            @estadoReserva,
            @iva,
            @subTotal,
            @total
        );

        DECLARE @nuevoId INT;
        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idReserva,
            'Reserva creada exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
