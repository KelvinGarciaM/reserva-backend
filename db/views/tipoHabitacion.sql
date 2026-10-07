USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_TipoHabitacion_Resumen
AS
SELECT
    th.idTipoHabitacion,
    th.nombreTipoHab,
    th.descripcion,
    th.capacidadMaxima,
    th.estado,
    COUNT(h.idHabitacion) AS cantidadHabitaciones
FROM dbo.tipohabitacion th
LEFT JOIN dbo.habitacion h
    ON h.idTipoHab = th.idTipoHabitacion
GROUP BY
    th.idTipoHabitacion,
    th.nombreTipoHab,
    th.descripcion,
    th.capacidadMaxima,
    th.estado;
GO