USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Recepcionista_Resumen
AS
SELECT
    r.cedula,
    r.nombre,
    r.apellidos,
    r.telefono,
    r.correo,
    r.estado,
    COUNT(re.idReserva) AS cantidadReservas,
    MAX(re.fechaReserva) AS ultimaReserva
FROM dbo.recepcionista r
LEFT JOIN dbo.reserva re
    ON re.idRecepcionista = r.cedula
GROUP BY
    r.cedula,
    r.nombre,
    r.apellidos,
    r.telefono,
    r.correo,
    r.estado;
GO