-- name: CreateReserva :execresult
INSERT INTO Reserva (
    idRecepcionista,
    idCliente,
    fechaReserva,
    estadoReserva,
    iva,
    subTotal,
    total
)
VALUES (?, ?, ?, ?, ?, ?, ?);


-- name: GetReservaById :one
SELECT
    r.idReserva,
    r.idRecepcionista,
    r.idCliente,
    CONCAT(c.nombre, ' ', c.apellidos) AS nombreCliente,
    CONCAT(re.nombre, ' ', re.apellidos) AS nombreRecepcionista,
    r.fechaReserva,
    r.estadoReserva,
    r.estado,
    r.iva,
    r.subTotal,
    r.total
FROM Reserva r
INNER JOIN cliente c ON r.idCliente = c.cedula
INNER JOIN recepcionista re ON r.idRecepcionista = re.cedula
WHERE r.idReserva = ? AND r.estado = 1;


-- name: GetReservas :many
SELECT
    r.idReserva,
    r.idRecepcionista,
    r.idCliente,
    CONCAT(c.nombre, ' ', c.apellidos) AS nombreCliente,
    CONCAT(re.nombre, ' ', re.apellidos) AS nombreRecepcionista,
    r.fechaReserva,
    r.estadoReserva,
    r.estado,
    r.iva,
    r.subTotal,
    r.total
FROM Reserva r
INNER JOIN cliente c ON r.idCliente = c.cedula
INNER JOIN recepcionista re ON r.idRecepcionista = re.cedula
WHERE r.estado = 1;


-- name: GetReservasByCliente :many
SELECT
    r.idReserva,
    r.idRecepcionista,
    r.idCliente,
    CONCAT(c.nombre, ' ', c.apellidos) AS nombreCliente,
    CONCAT(re.nombre, ' ', re.apellidos) AS nombreRecepcionista,
    r.fechaReserva,
    r.estadoReserva,
    r.estado,
    r.iva,
    r.subTotal,
    r.total
FROM Reserva r
INNER JOIN cliente c ON r.idCliente = c.cedula
INNER JOIN recepcionista re ON r.idRecepcionista = re.cedula
WHERE r.idCliente = ? AND r.estado = 1;


-- name: GetReservasByRecepcionista :many
SELECT
    r.idReserva,
    r.idRecepcionista,
    r.idCliente,
    CONCAT(c.nombre, ' ', c.apellidos) AS nombreCliente,
    CONCAT(re.nombre, ' ', re.apellidos) AS nombreRecepcionista,
    r.fechaReserva,
    r.estadoReserva,
    r.estado,
    r.iva,
    r.subTotal,
    r.total
FROM Reserva r
INNER JOIN cliente c ON r.idCliente = c.cedula
INNER JOIN recepcionista re ON r.idRecepcionista = re.cedula
WHERE r.idRecepcionista = ? AND r.estado = 1;


-- name: UpdateReserva :execresult
UPDATE Reserva
SET
    idRecepcionista = ?,
    idCliente = ?,
    fechaReserva = ?,
    estadoReserva = ?,
    estado = ?,
    iva = ?,
    subTotal = ?,
    total = ?
WHERE idReserva = ?;


-- name: UpdateEstadoReserva :execresult
UPDATE Reserva
SET estadoReserva = ?
WHERE idReserva = ?;


-- name: ToggleReserva :execresult
UPDATE reserva
SET estado = NOT estado
WHERE idReserva = ?;