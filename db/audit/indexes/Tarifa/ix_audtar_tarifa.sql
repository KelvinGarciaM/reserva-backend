USE reservasdbV2;
GO

CREATE NONCLUSTERED INDEX ix_audtar_tarifa ON dbo.auditoriaTarifa (idTarifa, fechaCambio DESC);
GO
