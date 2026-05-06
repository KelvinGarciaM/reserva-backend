-- name: CreateCliente :execresult
INSERT INTO Cliente (
    cedula,
    idTipoCliente,
    nombre,
    apellidos,
    telefono,
    direccion
)
VALUES (?, ?, ?, ?, ?, ?);

-- name: GetClientes :many
SELECT
    cedula,
    idTipoCliente,
    nombre,
    apellidos,
    telefono,
    direccion,
    estado
FROM Cliente;

-- name: GetClienteByCedula :one
SELECT
    cedula,
    idTipoCliente,
    nombre,
    apellidos,
    telefono,
    direccion,
    estado
FROM Cliente
WHERE cedula = ?;

-- name: GetClientesByTipoCliente :many
SELECT
    cedula,
    idTipoCliente,
    nombre,
    apellidos,
    telefono,
    direccion,
    estado
FROM Cliente
WHERE idTipoCliente = ?;

-- name: SearchClientes :many
SELECT
    cedula,
    idTipoCliente,
    nombre,
    apellidos,
    telefono,
    direccion,
    estado
FROM Cliente
WHERE
    CAST(cedula AS CHAR) LIKE CONCAT(?, '%')
    OR nombre LIKE CONCAT(?, '%')
    OR apellidos LIKE CONCAT(?, '%')
    OR telefono LIKE CONCAT(?, '%')
    OR direccion LIKE CONCAT(?, '%');

-- name: UpdateCliente :execresult
UPDATE Cliente
SET
    idTipoCliente = ?,
    nombre = ?,
    apellidos = ?,
    telefono = ?,
    direccion = ?,
    estado = ?
WHERE cedula = ?;

-- name: DeleteCliente :execresult
UPDATE Cliente
SET estado = 0
WHERE cedula = ?;

-- name: ToggleClienteEstado :execresult
UPDATE Cliente
SET estado = NOT estado
WHERE cedula = ?;