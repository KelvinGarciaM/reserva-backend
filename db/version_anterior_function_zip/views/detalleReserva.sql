USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_DetalleReserva_Detalle
AS
SELECT
    dr.idDetalleReserva,
    dr.idHabitacion,
    dr.idReserva,
    dr.idTarifa,

    -- Habitación
    th.nombreTipoHab AS nombreTipoHabitacion,
    h.numeroHabitacion,

    -- Reserva
    CONCAT(rp.nombre, ' ', rp.apellidos)
        AS nombreRecepcionista,

    CONCAT(c.nombre, ' ', c.apellidos)
        AS nombreCliente,

    tc.nombreTipoC AS nombreTipoCliente,
    tc.descuentoBase,

    r.fechaReserva,
    r.estadoReserva,

    -- Tarifa
    t.nombreTarifa,

    -- Detalle
    dr.cantidadPersonas,
    dr.precioAplicado,
    dr.fechaEntrada,
    dr.fechaSalida,
    dr.iva,
    dr.subTotal,
    dr.total,
    dr.estado

FROM dbo.detallereserva AS dr

INNER JOIN dbo.habitacion AS h
    ON dr.idHabitacion = h.idHabitacion

INNER JOIN dbo.tipohabitacion AS th
    ON h.idTipoHab = th.idTipoHabitacion

INNER JOIN dbo.reserva AS r
    ON dr.idReserva = r.idReserva

INNER JOIN dbo.recepcionista AS rp
    ON r.idRecepcionista = rp.cedula

INNER JOIN dbo.cliente AS c
    ON r.idCliente = c.cedula

INNER JOIN dbo.tipocliente AS tc
    ON c.idTipoCliente = tc.idTipoCliente

INNER JOIN dbo.tarifa AS t
    ON dr.idTarifa = t.idTarifa;
GO