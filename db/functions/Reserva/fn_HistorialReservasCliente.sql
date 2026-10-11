USE reservasdbV2;
GO

/* =========================================================
   FUNCIÓN: fn_HistorialReservasCliente

   Descripción:
   Devuelve el historial de reservas de un cliente junto con
   la habitación, tipo de habitación, tarifa, fechas y montos.

   Incluye el estado de la reserva y del detalle para que
   también puedan consultarse registros históricos que hayan
   sido cancelados o desactivados.

   Importancia:
   Centraliza la consulta del historial de un cliente y evita
   repetir los JOIN necesarios en reportes y consultas.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_HistorialReservasCliente
(
    @cedulaCliente VARCHAR(20)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        r.idReserva,
        r.fechaReserva,
        r.estadoReserva,
        r.estado AS estadoReservaRegistro,

        h.idHabitacion,
        h.numeroHabitacion,
        th.nombreTipoHab,

        t.idTarifa,
        t.nombreTarifa,

        dr.idDetalleReserva,
        dr.fechaEntrada,
        dr.fechaSalida,
        dr.precioAplicado,
        dr.subTotal,
        dr.iva,
        dr.total,
        dr.estado AS estadoDetalle

    FROM dbo.reserva AS r

    INNER JOIN dbo.detallereserva AS dr
        ON dr.idReserva = r.idReserva

    INNER JOIN dbo.habitacion AS h
        ON h.idHabitacion = dr.idHabitacion

    INNER JOIN dbo.tipohabitacion AS th
        ON th.idTipoHabitacion = h.idTipoHab

    INNER JOIN dbo.tarifa AS t
        ON t.idTarifa = dr.idTarifa

    WHERE r.idCliente = @cedulaCliente
);
GO
