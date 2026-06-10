-- name: CreateUser :exec
INSERT INTO users (name, email, password, role, image, cedula)
VALUES (?, ?, ?, ?, ?, ?);

-- name: GetUserByEmail :one
SELECT id, name, role, email, password, image, cedula, created_at, updated_at, estado
FROM users
WHERE email = ? AND estado = 1;

-- name: GetUsers :many
SELECT id, name, role, email, image, cedula, created_at, updated_at, estado
FROM users;


-- name: UpdateUserWithPassword :execresult
UPDATE users
SET
    name     = ?,
    role     = ?,
    email    = ?,
    password = ?,
    image    = ?,
    cedula   = ?,
    estado   = ?
WHERE id = ?;

-- name: UpdateUserWithoutPassword :execresult
UPDATE users
SET
    name   = ?,
    role   = ?,
    email  = ?,
    image  = ?,
    cedula = ?
WHERE id = ?;

-- name: ToggleUserStatus :execresult
UPDATE users
SET estado = NOT estado
WHERE id = ?;