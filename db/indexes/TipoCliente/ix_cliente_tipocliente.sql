USE reservasdbV2;
GO

/* cliente: se consulta por tipo de cliente (vista vw_Cliente_Detalle) */
CREATE NONCLUSTERED INDEX ix_cliente_tipocliente
    ON dbo.cliente (idTipoCliente)
    INCLUDE (nombre, apellidos, estado);
GO
