-- name: CreateTarifa :execresult
INSERT INTO tarifa (idTipoHabitacion, precioBase, nombreTarifa,fechaInicio,fechaFin)
VALUES (?, ?, ?, ?,?);

-- name: GetTarifaByNombre :one
SELECT 
    t.idTarifa,
    t.nombreTarifa,
    th.nombreTipoHab AS tipoHabitacion,
    t.precioBase,
    t.fechaInicio,
    t.fechaFin,
    t.estado
FROM Tarifa t
INNER JOIN TipoHabitacion th 
    ON t.idTipoHabitacion = th.idTipoHabitacion
WHERE t.nombreTarifa = ?;

-- name: GetTarifas :many
SELECT 
    t.idTarifa,
    t.nombreTarifa,
    th.nombreTipoHab AS tipoHabitacion,
    t.precioBase,
    t.fechaInicio,
    t.fechaFin,
    t.estado
FROM Tarifa t
INNER JOIN TipoHabitacion th 
    ON t.idTipoHabitacion = th.idTipoHabitacion;

-- name: UpdateTarifa :execresult
UPDATE tarifa
SET
    idTipoHabitacion = COALESCE(sqlc.narg(idTipoHabitacion), idTipoHabitacion),
    precioBase       = COALESCE(sqlc.narg(precioBase), precioBase),
    nombreTarifa     = COALESCE(sqlc.narg(nombreTarifa), nombreTarifa),
    fechaInicio      = COALESCE(sqlc.narg(fechaInicio), fechaInicio),
    fechaFin         = COALESCE(sqlc.narg(fechaFin), fechaFin)
WHERE idTarifa = sqlc.arg(idTarifa);

-- name: DeleteTarifa :execresult
UPDATE tarifa
SET estado = CASE
    WHEN estado = 1 THEN 0
    ELSE 1
END
WHERE idTarifa = sqlc.arg(idTarifa);