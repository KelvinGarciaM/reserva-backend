-- name: CreateRecepcionista :execresult
INSERT INTO Recepcionista (
    cedula,
    nombre,
    apellidos,
    telefono,
    correo
)
VALUES (?, ?, ?, ?, ?);

-- name: GetRecepcionistas :many
SELECT
    cedula,
    nombre,
    apellidos,
    telefono,
    correo,
    estado
FROM Recepcionista;

-- name: GetRecepcionistaByCedula :one
SELECT
    cedula,
    nombre,
    apellidos,
    telefono,
    correo,
    estado
FROM Recepcionista
WHERE cedula = ?;

-- name: SearchRecepcionistas :many
SELECT
    cedula,
    nombre,
    apellidos,
    telefono,
    correo,
    estado
FROM Recepcionista
WHERE
    CAST(cedula AS CHAR) LIKE CONCAT(?, '%')
    OR nombre LIKE CONCAT(?, '%')
    OR apellidos LIKE CONCAT(?, '%')
    OR telefono LIKE CONCAT(?, '%')
    OR correo LIKE CONCAT(?, '%');

-- name: UpdateRecepcionista :execresult
UPDATE Recepcionista
SET
    nombre = ?,
    apellidos = ?,
    telefono = ?,
    correo = ?,
    estado = ?
WHERE cedula = ?;

-- name: DeleteRecepcionista :execresult
UPDATE Recepcionista
SET estado = 0
WHERE cedula = ?;

-- name: ToggleRecepcionistaEstado :execresult
UPDATE Recepcionista
SET estado = NOT estado
WHERE cedula = ?;