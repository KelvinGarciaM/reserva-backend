USE reservasdbV2;
GO

/* ---------- 11.5 Trigger: auditoría de reservas ----------
   Registra INSERT, DELETE y UPDATE. En UPDATE solo se registra cuando cambia
   algún campo relevante (cliente, recepcionista, estado, estado lógico o
   total). Así el recálculo automático de totales no llena la tabla de ruido
   cuando el monto no cambió. */
CREATE OR ALTER TRIGGER dbo.trg_Reserva_Auditoria
ON dbo.reserva
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    /* INSERT: existe en inserted y no en deleted */
    INSERT INTO dbo.auditoriaReserva
        (idReserva, accion, idClienteNuevo, idRecepcionistaNuevo,
         estadoReservaNuevo, estadoNuevo, totalNuevo)
    SELECT i.idReserva, 'INSERT', i.idCliente, i.idRecepcionista,
           i.estadoReserva, i.estado, i.total
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.idReserva = i.idReserva
    WHERE d.idReserva IS NULL;

    /* UPDATE: existe en ambos y cambió algo relevante */
    INSERT INTO dbo.auditoriaReserva
        (idReserva, accion,
         idClienteAnterior, idClienteNuevo,
         idRecepcionistaAnterior, idRecepcionistaNuevo,
         estadoReservaAnterior, estadoReservaNuevo,
         estadoAnterior, estadoNuevo,
         totalAnterior, totalNuevo)
    SELECT i.idReserva, 'UPDATE',
           d.idCliente, i.idCliente,
           d.idRecepcionista, i.idRecepcionista,
           d.estadoReserva, i.estadoReserva,
           d.estado, i.estado,
           d.total, i.total
    FROM inserted AS i
    INNER JOIN deleted AS d ON d.idReserva = i.idReserva
    WHERE i.idCliente       <> d.idCliente
       OR i.idRecepcionista <> d.idRecepcionista
       OR i.estadoReserva   <> d.estadoReserva
       OR i.estado          <> d.estado
       OR i.total           <> d.total;

    /* DELETE: existe en deleted y no en inserted */
    INSERT INTO dbo.auditoriaReserva
        (idReserva, accion, idClienteAnterior, idRecepcionistaAnterior,
         estadoReservaAnterior, estadoAnterior, totalAnterior)
    SELECT d.idReserva, 'DELETE', d.idCliente, d.idRecepcionista,
           d.estadoReserva, d.estado, d.total
    FROM deleted AS d
    LEFT JOIN inserted AS i ON i.idReserva = d.idReserva
    WHERE i.idReserva IS NULL;
END;
GO
