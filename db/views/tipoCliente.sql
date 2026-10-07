USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_TipoCliente_Resumen
AS
SELECT
    tc.idTipoCliente,
    tc.nombreTipoC,
    tc.descripcion,
    tc.descuentoBase,
    tc.estado,
    COUNT(c.cedula) AS cantidadClientes
FROM dbo.tipocliente tc
LEFT JOIN dbo.cliente c
    ON c.idTipoCliente = tc.idTipoCliente
GROUP BY
    tc.idTipoCliente,
    tc.nombreTipoC,
    tc.descripcion,
    tc.descuentoBase,
    tc.estado;
GO