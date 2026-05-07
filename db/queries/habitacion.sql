-- name: CreateHabitacion :execresult
INSERT INTO Habitacion (idTipoHab, numeroHabitacion, estadoHabitacion)
VALUES (?, ?, ?);
-- name: GetHabitacionById :one
SELECT idHabitacion, idTipoHab, numeroHabitacion, estadoHabitacion, estado
FROM Habitacion
WHERE idHabitacion = ? AND estado = 1;
-- name: GetHabitacionesByTipo :many
SELECT idHabitacion, idTipoHab, numeroHabitacion, estadoHabitacion, estado
FROM Habitacion
WHERE idTipoHab = ? AND estado = 1;
-- name: GetHabitaciones :many
SELECT idHabitacion, idTipoHab, numeroHabitacion, estadoHabitacion, estado
FROM Habitacion
WHERE estado = 1;
-- name: UpdateHabitacion :execresult
UPDATE Habitacion
SET idTipoHab = ?, numeroHabitacion = ?, estadoHabitacion = ?, estado = ?
WHERE idHabitacion = ?;
-- name: updateEstadoHabitacion :execresult
UPDATE Habitacion
SET estado = ?
WHERE idHabitacion = ?;
-- name: DeleteHabitacion :execresult
UPDATE Habitacion
SET estado = 0
WHERE idHabitacion = ?;