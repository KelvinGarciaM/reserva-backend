-- name: CreateUser :exec
INSERT INTO users (name, email, password, role, image)
VALUES (?, ?, ?, ?, ?);

-- name: GetUserByEmail :one
SELECT id, name, role, email, password, image, created_at, updated_at, estado
FROM users
WHERE email = ? AND estado = 1;

-- name: GetUsers :many
SELECT id, name, role, email, image, created_at, updated_at, estado
FROM users
WHERE estado = 1;

-- name: UpdateUserWithPassword :execresult
UPDATE users
SET
    name = ?,
    role = ?,
    email = ?,
    password = ?,
    image = ?,      
    estado = ?
WHERE id = ?;

-- name: UpdateUserWithoutPassword :execresult
UPDATE users
SET
    name = ?,
    role = ?,
    email = ?,
    image = ?,      
    estado = ?
WHERE id = ?;

-- name: DeleteUser :execresult
UPDATE users
SET estado = NOT estado
WHERE id = ?;