-- name: CreateUser :exec
INSERT INTO users (name, email, password, role)
VALUES (?, ?, ?, ?);

-- name: GetUserByEmail :one
SELECT id, name, role, email, password, created_at, updated_at, estado
FROM users
WHERE email = ? AND estado = 1;

-- name: GetUsers :many
SELECT id, name, role, email, created_at, updated_at, estado
FROM users where estado = 1;

-- name: UpdateUserWithPassword :execresult
UPDATE users
SET
    name = ?,
    role = ?,
    email = ?,
    password = ?,
    estado = ?
WHERE id = ?;

-- name: UpdateUserWithoutPassword :execresult
UPDATE users
SET
    name = ?,
    role = ?,
    email = ?,
    estado = ?
WHERE id = ?;

-- name: DeleteUser :execresult
UPDATE users
SET estado = 0
WHERE id = ?;