-- name: CreateTipoCliente :execresult
INSERT INTO tipoCliente (
    nombreTipoC,
    descripcion,
    descuentoBase
)
VALUES (?, ?, ?);

-- name: GetTipoClientes :many
SELECT
    idTipoCliente,
    nombreTipoC,
    descripcion,
    descuentoBase,
    estado
FROM tipoCliente;

-- name: GetTipoClienteById :one
SELECT
    idTipoCliente,
    nombreTipoC,
    descripcion,
    descuentoBase,
    estado
FROM tipoCliente
WHERE idTipoCliente = ?;

-- name: SearchTipoClientes :many
SELECT
    idTipoCliente,
    nombreTipoC,
    descripcion,
    descuentoBase,
    estado
FROM tipoCliente
WHERE
    CAST(idTipoCliente AS CHAR) LIKE CONCAT(?, '%')
    OR nombreTipoC LIKE CONCAT(?, '%')
    OR descripcion LIKE CONCAT(?, '%');

-- name: UpdateTipoCliente :execresult
UPDATE tipoCliente
SET
    nombreTipoC = ?,
    descripcion = ?,
    descuentoBase = ?,
    estado = ?
WHERE idTipoCliente = ?;

-- name: DeleteTipoCliente :execresult
UPDATE tipoCliente
SET estado = 0
WHERE idTipoCliente = ?;

-- name: ToggleTipoClienteEstado :execresult
UPDATE tipoCliente
SET estado = NOT estado
WHERE idTipoCliente = ?;