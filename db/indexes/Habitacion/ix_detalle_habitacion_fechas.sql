USE reservasdbV2;
GO

CREATE NONCLUSTERED INDEX ix_detalle_habitacion_fechas
    ON dbo.detallereserva (idHabitacion, fechaEntrada, fechaSalida)
    INCLUDE (estado);
GO
