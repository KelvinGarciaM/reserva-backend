/* =========================================================
   FUNCIÓN: fn_HabitacionesDisponibles

   Descripción:
   Devuelve las habitaciones activas que se encuentran
   disponibles dentro de un rango de fechas determinado.

   Una habitación se considera disponible cuando no existe
   ningún detalle de reserva activo cuyo rango de fechas se
   cruce con las fechas solicitadas.

   También devuelve el tipo de habitación y su capacidad
   máxima para facilitar su selección desde la aplicación.

   Importancia:
   Centraliza la validación de disponibilidad y evita repetir
   la lógica de traslape en distintas consultas del sistema.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_HabitacionesDisponibles
(
    @fechaEntrada DATETIME,
    @fechaSalida  DATETIME
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        h.idHabitacion,
        h.idTipoHab,
        h.numeroHabitacion,
        th.nombreTipoHab,
        th.capacidadMaxima
    FROM dbo.habitacion AS h

    INNER JOIN dbo.tipohabitacion AS th
        ON th.idTipoHabitacion = h.idTipoHab

    WHERE h.estado = 1
      AND th.estado = 1

      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.detallereserva AS dr

          WHERE dr.idHabitacion = h.idHabitacion
            AND dr.estado = 1

            -- Existe traslape cuando:
            AND dr.fechaEntrada < @fechaSalida
            AND dr.fechaSalida  > @fechaEntrada
      )
);
GO

-- Ejemplo:
-- SELECT *
-- FROM dbo.fn_HabitacionesDisponibles(
--     '2026-10-10 14:00:00',
--     '2026-10-13 12:00:00'
-- );