USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Cliente_Detalle
AS
SELECT
    c.cedula,
    c.idTipoCliente,
    tc.nombreTipoC,
    c.nombre,
    c.apellidos,
    c.telefono,
    c.direccion,
    c.estado
FROM dbo.cliente AS c
INNER JOIN dbo.tipocliente AS tc
    ON tc.idTipoCliente = c.idTipoCliente;
GO