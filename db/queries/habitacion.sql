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