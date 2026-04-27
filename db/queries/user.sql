-- name: CreateUser :exec
INSERT INTO users (name, email, password, role)
VALUES (?, ?, ?, ?);

-- name: GetUserByEmail :one
SELECT id, name, role, email, password, created_at, updated_at, remember_token
FROM users
WHERE email = ?;

-- name: GetUsers :many
SELECT id, name, role, email, created_at, updated_at
FROM users;

-- name: UpdateUser :exec
UPDATE users
SET
    name = ?,
    role = ?,
    email = ?,
    password = ?
WHERE id = ?;

-- name: DeleteUser :exec
DELETE FROM users WHERE id = ?;