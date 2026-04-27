-- name: CreateReserva :exec
INSERT INTO Reserva (idRecepcionista, idCliente, fechaReserva, fechaEntrada, fechaSalida, cantidadNoches, horaCheckIn, horaCheckOut, estadoReserva, estado)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: GetReservaById :one
SELECT idReserva, idRecepcionista, idCliente, fechaReserva, fechaEntrada, fechaSalida, cantidadNoches, horaCheckIn, horaCheckOut, estadoReserva, estado
FROM Reserva
WHERE idReserva = ?;

-- name: GetReservas :many
SELECT idReserva, idRecepcionista, idCliente, fechaReserva, fechaEntrada, fechaSalida, cantidadNoches, horaCheckIn, horaCheckOut, estadoReserva, estado
FROM Reserva
WHERE estado = 1;

-- name: GetReservasByCliente :many
SELECT idReserva, idRecepcionista, idCliente, fechaReserva, fechaEntrada, fechaSalida, cantidadNoches, horaCheckIn, horaCheckOut, estadoReserva, estado
FROM Reserva
WHERE idCliente = ? AND estado = 1;

-- name: GetReservasByRecepcionista :many
SELECT idReserva, idRecepcionista, idCliente, fechaReserva, fechaEntrada, fechaSalida, cantidadNoches, horaCheckIn, horaCheckOut, estadoReserva, estado
FROM Reserva
WHERE idRecepcionista = ? AND estado = 1;

-- name: UpdateReserva :exec
UPDATE Reserva
SET
    idRecepcionista = ?,
    idCliente = ?,
    fechaReserva = ?,
    fechaEntrada = ?,
    fechaSalida = ?,
    cantidadNoches = ?,
    horaCheckIn = ?,
    horaCheckOut = ?,
    estadoReserva = ?
WHERE idReserva = ?;

-- name: UpdateEstadoReserva :exec
UPDATE Reserva
SET estadoReserva = ?
WHERE idReserva = ?;

-- name: DeleteReserva :exec
UPDATE Reserva
SET estado = 0
WHERE idReserva = ?;