-- name: CreateTipoHabitacion :execresult
INSERT INTO TipoHabitacion (nombreTipoHab, descripcion, capacidadMaxima)
VALUES (?, ?, ?);
-- name: GetTipoHabitacionById :one
SELECT idTipoHabitacion, nombreTipoHab, descripcion, capacidadMaxima, estado
FROM TipoHabitacion
WHERE idTipoHabitacion = ? AND estado = 1;
-- name: GetTipoHabitaciones :many
SELECT idTipoHabitacion, nombreTipoHab, descripcion, capacidadMaxima, estado
FROM TipoHabitacion
WHERE estado = 1;
-- name: UpdateTipoHabitacion :execresult
UPDATE TipoHabitacion
SET nombreTipoHab = ?, descripcion = ?, capacidadMaxima = ?, estado = ?
WHERE idTipoHabitacion = ?;
-- name: updateEstadoTipoHabitacion :execresult
UPDATE TipoHabitacion
SET estado = ?
WHERE idTipoHabitacion = ?;
-- name: DeleteTipoHabitacion :execresult
UPDATE TipoHabitacion
SET estado = 0
WHERE idTipoHabitacion = ?;
