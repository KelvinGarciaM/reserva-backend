-- name: CreateReserva :execresult
INSERT INTO Reserva (
    idRecepcionista,
    idCliente,
    fechaReserva,
    fechaEntrada,
    fechaSalida,
    cantidadNoches,
    estadoReserva
)
VALUES (?, ?, ?, ?, ?, ?, ?);


-- name: GetReservaById :one
SELECT
    idReserva,
    idRecepcionista,
    idCliente,
    fechaReserva,
    fechaEntrada,
    fechaSalida,
    cantidadNoches,
    estadoReserva,
    estado
FROM Reserva
WHERE idReserva = ? AND estado = 1;


-- name: GetReservas :many
SELECT
    idReserva,
    idRecepcionista,
    idCliente,
    fechaReserva,
    fechaEntrada,
    fechaSalida,
    cantidadNoches,
    estadoReserva,
    estado
FROM Reserva
WHERE estado = 1;


-- name: GetReservasByCliente :many
SELECT
    idReserva,
    idRecepcionista,
    idCliente,
    fechaReserva,
    fechaEntrada,
    fechaSalida,
    cantidadNoches,
    estadoReserva,
    estado
FROM Reserva
WHERE idCliente = ? AND estado = 1;


-- name: GetReservasByRecepcionista :many
SELECT
    idReserva,
    idRecepcionista,
    idCliente,
    fechaReserva,
    fechaEntrada,
    fechaSalida,
    cantidadNoches,
    estadoReserva,
    estado
FROM Reserva
WHERE idRecepcionista = ? AND estado = 1;


-- name: UpdateReserva :execresult
UPDATE Reserva
SET
    idRecepcionista = ?,
    idCliente = ?,
    fechaReserva = ?,
    fechaEntrada = ?,
    fechaSalida = ?,
    cantidadNoches = ?,
    estadoReserva = ?,
    estado = ?
WHERE idReserva = ?;


-- name: UpdateEstadoReserva :execresult
UPDATE Reserva
SET estadoReserva = ?
WHERE idReserva = ?;


-- name: DeleteReserva :execresult
UPDATE Reserva
SET estado = 0
WHERE idReserva = ?;