USE reservasdbV2;
GO

/* reserva: historial por cliente (fn_HistorialReservasCliente,
   fn_TotalReservasHuesped), por recepcionista y por fecha. */
CREATE NONCLUSTERED INDEX ix_reserva_cliente_fecha
    ON dbo.reserva (idCliente, fechaReserva DESC)
    INCLUDE (estadoReserva, total, estado);
GO
