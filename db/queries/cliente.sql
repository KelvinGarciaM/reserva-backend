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
    c.cedula,
    c.idTipoCliente,
    tc.nombreTipoC,
    c.nombre,
    c.apellidos,
    c.telefono,
    c.direccion,
    c.estado
FROM Cliente c
INNER JOIN tipocliente tc
    ON c.idTipoCliente = tc.idTipoCliente;

-- name: GetClienteByCedula :one
SELECT
    c.cedula,
    c.idTipoCliente,
    tc.nombreTipoC,
    c.nombre,
    c.apellidos,
    c.telefono,
    c.direccion,
    c.estado
FROM Cliente c
INNER JOIN tipocliente tc
    ON c.idTipoCliente = tc.idTipoCliente
WHERE c.cedula = ?;

-- name: GetClientesByTipoCliente :many
SELECT
    c.cedula,
    c.idTipoCliente,
    tc.nombreTipoC,
    c.nombre,
    c.apellidos,
    c.telefono,
    c.direccion,
    c.estado
FROM Cliente c
INNER JOIN tipocliente tc
    ON c.idTipoCliente = tc.idTipoCliente
WHERE c.idTipoCliente = ?;

-- name: SearchClientes :many
SELECT
    c.cedula,
    c.idTipoCliente,
    tc.nombreTipoC,
    c.nombre,
    c.apellidos,
    c.telefono,
    c.direccion,
    c.estado
FROM Cliente c
INNER JOIN tipocliente tc
    ON c.idTipoCliente = tc.idTipoCliente
WHERE
    CAST(c.cedula AS CHAR) LIKE CONCAT(?, '%')
    OR c.nombre LIKE CONCAT(?, '%')
    OR c.apellidos LIKE CONCAT(?, '%')
    OR c.telefono LIKE CONCAT(?, '%')
    OR c.direccion LIKE CONCAT(?, '%')
    OR tc.nombreTipoC LIKE CONCAT(?, '%');

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