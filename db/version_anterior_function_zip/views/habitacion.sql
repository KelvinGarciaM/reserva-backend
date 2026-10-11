USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Habitacion_Detalle
AS
SELECT
    h.idHabitacion,
    h.idTipoHab,
    th.nombreTipoHab,
    h.numeroHabitacion,
    h.estado
FROM dbo.habitacion AS h
INNER JOIN dbo.tipohabitacion AS th
    ON th.idTipoHabitacion = h.idTipoHab;
GO