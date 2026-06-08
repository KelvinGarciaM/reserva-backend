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
    idReserva,
    idRecepcionista,
    idCliente,
    fechaReserva,
    estadoReserva,
    estado,
    iva,
    subTotal,
    total
FROM Reserva
WHERE idReserva = ? AND estado = 1;


-- name: GetReservas :many
SELECT
    idReserva,
    idRecepcionista,
    idCliente,
    fechaReserva,
    estadoReserva,
    estado,
    iva,
    subTotal,
    total
FROM Reserva
WHERE estado = 1;


-- name: GetReservasByCliente :many
SELECT
    idReserva,
    idRecepcionista,
    idCliente,
    fechaReserva,
    estadoReserva,
    estado,
    iva,
    subTotal,
    total
FROM Reserva
WHERE idCliente = ? AND estado = 1;


-- name: GetReservasByRecepcionista :many
SELECT
    idReserva,
    idRecepcionista,
    idCliente,
    fechaReserva,
    estadoReserva,
    estado,
    iva,
    subTotal,
    total
FROM Reserva
WHERE idRecepcionista = ? AND estado = 1;


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


-- name: DeleteReserva :execresult
UPDATE reserva
SET estado = CASE
    WHEN estado = 1 THEN 0
    ELSE 1
END
WHERE idReserva = sqlc.arg(idReserva);