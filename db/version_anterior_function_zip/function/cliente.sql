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

-- Ejemplo:
-- SELECT *
-- FROM dbo.fn_HistorialReservasCliente('10101010')
-- ORDER BY fechaReserva DESC;


/* =========================================================
   FUNCIÓN: fn_TotalReservasHuesped

   Descripción:
   Devuelve la cantidad de reservas activas y no canceladas
   asociadas a un cliente.

   Importancia:
   Puede utilizarse para identificar clientes frecuentes,
   generar estadísticas y apoyar futuras reglas comerciales.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_TotalReservasHuesped
(
    @cedula VARCHAR(20)
)
RETURNS INT
AS
BEGIN
    DECLARE @total INT;

    SELECT @total = COUNT(*)
    FROM dbo.reserva
    WHERE idCliente = @cedula
      AND estado = 1
      AND estadoReserva <> 'Cancelada';

    RETURN ISNULL(@total, 0);
END;
GO

-- Ejemplo:
-- SELECT
--     cedula,
--     dbo.fn_TotalReservasHuesped(cedula) AS totalReservas
-- FROM dbo.cliente;