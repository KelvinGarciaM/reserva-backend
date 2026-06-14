-- name: CreateHabitacion :execresult
INSERT INTO Habitacion (idTipoHab, numeroHabitacion)
VALUES (?, ?);
-- name: GetHabitacionById :one
SELECT idHabitacion, idTipoHab, numeroHabitacion, estado
FROM Habitacion
WHERE idHabitacion = ?;
-- name: GetHabitacionesByTipo :many
SELECT idHabitacion, idTipoHab, numeroHabitacion, estado
FROM Habitacion
WHERE idTipoHab = ?;
-- name: GetHabitaciones :many
SELECT
    h.idHabitacion,
    h.idTipoHab,
    th.nombreTipoHab,
    h.numeroHabitacion,
    h.estado
FROM Habitacion h
INNER JOIN TipoHabitacion th
    ON h.idTipoHab = th.idTipoHabitacion;
-- name: GetHabitacionByNumero :one
SELECT idHabitacion, idTipoHab, numeroHabitacion, estado
FROM Habitacion
WHERE numeroHabitacion = ?
LIMIT 1;
-- name: UpdateHabitacion :execresult
UPDATE Habitacion
SET idTipoHab = ?, numeroHabitacion = ?, estado = ?
WHERE idHabitacion = ?;
-- name: updateEstadoHabitacion :execresult
UPDATE Habitacion
SET estado = ?
WHERE idHabitacion = ?;
-- name: DeleteHabitacion :execresult
UPDATE Habitacion
SET estado = 0
WHERE idHabitacion = ?;

-- name: GetHabitacionesDisponibles :many
SELECT
    h.idHabitacion,
    h.numeroHabitacion,
    th.nombreTipoHab,
    t.idTarifa,
    t.nombreTarifa,
    t.precioBase,
    th.capacidadMaxima
FROM habitacion h
INNER JOIN tipohabitacion th
    ON h.idTipoHab = th.idTipoHabitacion
INNER JOIN tarifa t
    ON th.idTipoHabitacion = t.idTipoHabitacion
WHERE h.estado = 1
  AND th.estado = 1
  AND t.estado = 1
  AND t.desactivadaManual = 0
  AND CURDATE() BETWEEN t.fechaInicio AND t.fechaFin;