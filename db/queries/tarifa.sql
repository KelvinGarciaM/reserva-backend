-- name: CreateTarifa :execresult
INSERT INTO tarifa (idTipoHabitacion, precioBase, nombreTarifa,fechaInicio,fechaFin,descripcion,estado)
VALUES (?, ?, ?, ?, ? , ?, ?);

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
    t.descripcion,
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
    fechaFin         = COALESCE(sqlc.narg(fechaFin), fechaFin),
    descripcion      = ?
WHERE idTarifa = sqlc.arg(idTarifa);


-- name: UpdateTarifasVencidasAutomatico :exec
UPDATE tarifa
SET estado = 0,
    desactivadaManual = 0
WHERE fechaFin < CURDATE();

-- name: ActivarTarifasVigentesAutomatico :exec
UPDATE tarifa
SET estado = 1
WHERE estado = 0
AND desactivadaManual = 0
AND fechaInicio <= CURDATE()
AND fechaFin >= CURDATE();

-- name: ActivarTarifaSiEstaVigentePorUsuario :execresult
UPDATE tarifa
SET estado = 1,
desactivadaManual = 0
WHERE idTarifa = ?
AND fechaInicio <= CURDATE()
AND fechaFin >= CURDATE();

-- name: DesactivarTarifaPorUsuario :execresult
UPDATE tarifa
SET estado = 0,
desactivadaManual = 1
WHERE idTarifa = ?;