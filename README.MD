# 🚀 Reserva Backend API

API REST desarrollada en Go utilizando Gin, SQLC y MySQL. Incluye autenticación con PASETO, middleware y CRUD de usuarios.

# 🧠 Tecnologías

- Go
- Gin Framework
- MySQL
- SQLC
- PASETO
- bcrypt

# 📌 Funcionalidades

## Usuarios
- Registro de usuario
- Login con token
- Listar usuarios
- Buscar usuario por email
- Actualizar usuario
- Eliminar usuario

## Seguridad
- Autenticación con PASETO
- Middleware de rutas protegidas
- Hash de contraseñas con bcrypt

# ⚙️ Instalación

## 1. Clonar repositorio
git clone https://github.com/TU_USUARIO/reserva-backend.git
cd reserva-backend

## 2. Instalar dependencias
go mod tidy

## 3. Crear base de datos MySQL
mysql -u root -p

CREATE DATABASE reserva_db;
USE reserva_db;

## 4. Crear tabla users
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

## 5. Configurar variables de entorno (.env)
DB_DRIVER=mysql
DB_SOURCE=root:password@tcp(localhost:3306)/reserva_db
SERVER_URL=:8080

## 6. Generar SQLC
sqlc generate

## 7. Ejecutar servidor
go run main.go

# 🌐 Endpoints

## Públicos

POST /api/v1/users
POST /api/v1/login

## Protegidos (requiere token)
Authorization: Bearer <token>

GET /api/v1/users
GET /api/v1/users/:email
PUT /api/v1/users
DELETE /api/v1/users

# 🔐 Login Response

{
  "access_token": "token_generado",
  "payload": {
    "id": 1,
    "email": "user@test.com",
    "role": "admin"
  }
}

# 🚀 Flujo del proyecto

SQL → sqlc generate → dto → handlers → server → API funcionando