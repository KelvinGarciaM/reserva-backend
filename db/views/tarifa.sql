USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Tarifa_Detalle
AS
SELECT
    t.idTarifa,
    t.idTipoHabitacion,
    t.nombreTarifa,
    th.nombreTipoHab AS tipoHabitacion,
    t.precioBase,
    t.fechaInicio,
    t.fechaFin,
    t.descripcion,
    t.estado,
    t.desactivadaManual
FROM dbo.tarifa AS t
INNER JOIN dbo.tipohabitacion AS th
    ON th.idTipoHabitacion = t.idTipoHabitacion;
GO