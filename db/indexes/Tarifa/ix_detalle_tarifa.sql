USE reservasdbV2;
GO

CREATE NONCLUSTERED INDEX ix_detalle_tarifa
    ON dbo.detallereserva (idTarifa);
GO
