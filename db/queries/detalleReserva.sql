-- name: CreateDetalleReserva :execresult
INSERT INTO detallereserva (idHabitacion, idReserva, idTarifa,cantidadPersonas,
                            precioAplicado,fechaEntrada,fechaSalida,iva,subTotal,total)
                            VALUES (?, ?, ?, ?,?,?,?,?,?,?);

-- name: GetDetalleReservaByID :one
SELECT
    dr.idDetalleReserva,

    -- Datos de habitación
    th.nombreTipoHab AS nombreTipoHabitacion,
    h.numeroHabitacion,

    -- Datos de reserva
    CONCAT(rp.nombre, ' ', rp.apellidos) AS nombreRecepcionista,
    CONCAT(c.nombre, ' ', c.apellidos) AS nombreCliente,
    tc.nombreTipoC AS nombreTipoCliente,
    r.fechaReserva,
    r.estadoReserva,

    -- Datos de tarifa
    t.nombreTarifa,

    -- Campos de detalleReserva
    dr.cantidadPersonas,
    dr.precioAplicado,
    dr.fechaEntrada,
    dr.fechaSalida,
    dr.iva,
    dr.subTotal,
    dr.total,
    dr.estado

FROM detallereserva dr
INNER JOIN habitacion h
    ON dr.idHabitacion = h.idHabitacion
INNER JOIN tipohabitacion th
    ON h.idTipoHab = th.idTipoHabitacion
INNER JOIN reserva r
    ON dr.idReserva = r.idReserva
INNER JOIN recepcionista rp
    ON r.idRecepcionista = rp.cedula
INNER JOIN cliente c
    ON r.idCliente = c.cedula
INNER JOIN tipocliente tc
    ON c.idTipoCliente = tc.idTipoCliente
INNER JOIN tarifa t
    ON dr.idTarifa = t.idTarifa
WHERE dr.idDetalleReserva = ?;

-- name: GetAllDetalleReserva :many
SELECT
    dr.idDetalleReserva,

    -- Datos de habitación
    th.nombreTipoHab AS nombreTipoHabitacion,
    h.numeroHabitacion,

    -- Datos de reserva
    CONCAT(rp.nombre, ' ', rp.apellidos) AS nombreRecepcionista,
    CONCAT(c.nombre, ' ', c.apellidos) AS nombreCliente,
    tc.nombreTipoC AS nombreTipoCliente,
    r.fechaReserva,
    r.estadoReserva,

    -- Datos de tarifa
    t.nombreTarifa,

    -- Campos propios de detalleReserva, sin FK
    dr.cantidadPersonas,
    dr.precioAplicado,
    dr.fechaEntrada,
    dr.fechaSalida,
    dr.iva,
    dr.subTotal,
    dr.total,
    dr.estado

FROM detallereserva dr
INNER JOIN habitacion h
    ON dr.idHabitacion = h.idHabitacion
INNER JOIN tipohabitacion th
    ON h.idTipoHab = th.idTipoHabitacion
INNER JOIN reserva r
    ON dr.idReserva = r.idReserva
INNER JOIN recepcionista rp
    ON r.idRecepcionista = rp.cedula
INNER JOIN cliente c
    ON r.idCliente = c.cedula
INNER JOIN tipocliente tc
    ON c.idTipoCliente = tc.idTipoCliente
INNER JOIN tarifa t
    ON dr.idTarifa = t.idTarifa;

-- name: UpdateDetalleReserva :execresult
UPDATE detallereserva
SET
    idHabitacion = ?,
    idTarifa = ?,
    cantidadPersonas      = ?,
    precioAplicado      = ?,
    fechaEntrada     =COALESCE(sqlc.narg(fechaEntrada),fechaEntrada),
    fechaSalida      = COALESCE(sqlc.narg(fechaSalida), fechaSalida),
    iva     = ?,
    subTotal      = ?,
    total      =?
WHERE idDetalleReserva = sqlc.arg(idDetalleReserva);

-- name: DeleteDetalleReserva :execresult
UPDATE detallereserva
SET estado = CASE
    WHEN estado = 1 THEN 0
    ELSE 1
END
WHERE idDetalleReserva= sqlc.arg(idDetalleReserva);

-- name: GetEstadoDetalleReserva :one
SELECT estado
FROM detalleReserva 
WHERE idDetalleReserva = ?;
-- name: GetTipoHabitacionByHabitacion :one
SELECT idTipoHab
FROM habitacion
WHERE idHabitacion = ? AND estado = 1;

-- name: GetReservanByIdDetalleReserva :one
SELECT idReserva
FROM detallereserva
WHERE idDetalleReserva = ? AND estado = 1;
-- name: GetFechasByIdDetalleReserva :one
SELECT fechaEntrada,fechaSalida
FROM detallereserva
WHERE idDetalleReserva = ? AND estado = 1;

-- name: GetTarifaActivaByTipoHabitacionAndFecha :one
SELECT idTarifa, precioBase, nombreTarifa
FROM tarifa
WHERE idTipoHabitacion = sqlc.arg(idTipoHabitacion)
  AND estado = 1
  AND (
        (fechaInicio IS NULL AND fechaFin IS NULL)
        OR
        (CAST(sqlc.arg(fecha) AS DATE) BETWEEN fechaInicio AND fechaFin)
      )
ORDER BY 
    CASE 
        WHEN fechaInicio IS NOT NULL AND fechaFin IS NOT NULL THEN 1
        ELSE 2
    END
LIMIT 1;

-- name: GetClienteByReserva :one
SELECT 
    tc.descuentoBase
FROM reserva r
INNER JOIN cliente c
    ON r.idCliente = c.cedula
INNER JOIN tipocliente tc
    ON c.idTipoCliente = tc.idTipoCliente
WHERE r.idReserva = ?;

-- name: CountTraslapesDetalleReserva :one
SELECT COUNT(*)
FROM detallereserva
WHERE idHabitacion = sqlc.arg(idHabitacion)
  AND fechaEntrada < sqlc.arg(fechaSalida)
  AND fechaSalida > sqlc.arg(fechaEntrada);

-- name: CountTraslapesDetalleReservaUpdate :one
SELECT COUNT(*)
FROM detallereserva
WHERE idHabitacion = sqlc.arg(idHabitacion)
  AND idDetalleReserva <> sqlc.arg(idDetalleReserva)
  AND fechaEntrada < sqlc.arg(fechaSalida)
  AND fechaSalida > sqlc.arg(fechaEntrada);




-- name: GetDetallesByReserva :many
SELECT
    dr.idDetalleReserva,
    th.nombreTipoHab AS nombreTipoHabitacion,
    h.numeroHabitacion,
    t.nombreTarifa,
    tc.descuentoBase,
    dr.cantidadPersonas,
    dr.precioAplicado,
    dr.fechaEntrada,
    dr.fechaSalida,
    dr.iva,
    dr.subTotal,
    dr.total,
    dr.estado
FROM detallereserva dr
INNER JOIN habitacion h ON dr.idHabitacion = h.idHabitacion
INNER JOIN tipohabitacion th ON h.idTipoHab = th.idTipoHabitacion
INNER JOIN tarifa t ON dr.idTarifa = t.idTarifa
INNER JOIN reserva r ON dr.idReserva = r.idReserva
INNER JOIN cliente c ON r.idCliente = c.cedula
INNER JOIN tipocliente tc ON c.idTipoCliente = tc.idTipoCliente
WHERE dr.idReserva = ? AND dr.estado = 1;


-- name: GetFechasOcupadasByHabitacion :many
SELECT fechaEntrada, fechaSalida
FROM detallereserva
WHERE idHabitacion = ? AND estado = 1;