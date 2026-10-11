USE reservasdbV2;
GO

CREATE NONCLUSTERED INDEX ix_audres_reserva ON dbo.auditoriaReserva (idReserva, fechaCambio DESC);
GO
