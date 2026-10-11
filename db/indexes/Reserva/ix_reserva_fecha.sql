USE reservasdbV2;
GO

CREATE NONCLUSTERED INDEX ix_reserva_fecha
    ON dbo.reserva (fechaReserva)
    INCLUDE (estadoReserva, total);
GO
