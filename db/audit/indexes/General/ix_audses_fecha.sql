USE reservasdbV2;
GO

CREATE NONCLUSTERED INDEX ix_audses_fecha ON dbo.auditoriaSesion (fechaHora DESC);
GO
