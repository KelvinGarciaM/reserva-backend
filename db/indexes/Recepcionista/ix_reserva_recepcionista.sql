USE reservasdbV2;
GO

CREATE NONCLUSTERED INDEX ix_reserva_recepcionista
    ON dbo.reserva (idRecepcionista)
    INCLUDE (fechaReserva, estadoReserva);
GO
