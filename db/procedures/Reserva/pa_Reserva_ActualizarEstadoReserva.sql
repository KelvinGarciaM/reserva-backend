USE reservasdbV2;
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
