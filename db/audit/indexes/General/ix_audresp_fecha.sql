USE reservasdbV2;
GO

CREATE NONCLUSTERED INDEX ix_audresp_fecha ON dbo.auditoriaRespaldo (fechaHora DESC);
GO
