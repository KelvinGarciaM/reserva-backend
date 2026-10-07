/* =========================================================
   FUNCIÓN: fn_TarifasVigentes

   Descripción:
   Devuelve las tarifas disponibles para una fecha específica,
   considerando su estado, desactivación manual, período de
   vigencia y estado del tipo de habitación.

   Importancia:
   Centraliza la lógica utilizada para determinar qué tarifa
   puede aplicarse según la fecha de una estadía.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_TarifasVigentes
(
    @fecha DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        t.idTarifa,
        t.nombreTarifa,
        t.idTipoHabitacion,
        th.nombreTipoHab,
        t.precioBase,
        t.fechaInicio,
        t.fechaFin

    FROM dbo.tarifa AS t

    INNER JOIN dbo.tipohabitacion AS th
        ON th.idTipoHabitacion = t.idTipoHabitacion

    WHERE @fecha IS NOT NULL
      AND t.estado = 1
      AND t.desactivadaManual = 0
      AND th.estado = 1

      AND (
            t.fechaInicio IS NULL
            OR t.fechaInicio <= @fecha
          )

      AND (
            t.fechaFin IS NULL
            OR t.fechaFin >= @fecha
          )
);
GO

-- Ejemplo:
-- SELECT *
-- FROM dbo.fn_TarifasVigentes('2026-12-24');