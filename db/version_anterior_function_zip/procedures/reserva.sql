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


/* =========================================================
   4. CAMBIAR ESTADO DE LA RESERVA

   Este es estadoReserva:
   Pendiente, Confirmada, Cancelada, etc.

   NO es el campo estado (0/1).
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Reserva_ActualizarEstadoReserva
    @idReserva INT,
    @estadoReserva VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.reserva
    SET estadoReserva = @estadoReserva
    WHERE idReserva = @idReserva;

    DECLARE @filasAfectadas INT = @@ROWCOUNT;

    SELECT
        @idReserva AS idReserva,
        @filasAfectadas AS filasAfectadas,
        'Estado de reserva actualizado.' AS mensaje;
END;
GO