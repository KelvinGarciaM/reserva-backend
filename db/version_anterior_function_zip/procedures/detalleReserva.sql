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