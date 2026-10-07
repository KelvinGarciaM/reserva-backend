# Reserva Backend

API REST desarrollada en **Go con Gin** para el sistema de reservas de hotel.  
El backend utiliza **SQL Server** como motor de base de datos y se conecta mediante `database/sql` y `go-mssqldb`.

La API incluye autenticación con **PASETO**, control de acceso por roles y documentación mediante **Swagger**.

## Tecnologías
- Go
- Gin Framework
- SQL Server
- SQL Server Management Studio (SSMS)
- `database/sql`
- `go-mssqldb`
- PASETO
- bcrypt
- Swagger / Swaggo

## Requisitos

Antes de ejecutar el proyecto se debe tener instalado:
- Go
- SQL Server
- SQL Server Management Studio
- Git
- Swag CLI

Para instalar Swag:
go install github.com/swaggo/swag/cmd/swag@v1.16.6


## 1. Clonar el proyecto
git clone <URL_DEL_REPOSITORIO>
cd reserva-backend

## 2. Instalar dependencias
go mod tidy

## 3. Crear la base de datos

Abrir **SQL Server Management Studio** y ejecutar el script de la base de datos del proyecto.
La base utilizada actualmente es: reservasdbV2

El script contiene las tablas y objetos necesarios de SQL Server, como:
- Procedimientos almacenados
- Vistas
- Triggers
- Restricciones
- Datos necesarios para las pruebas

## 4. Configurar variables de entorno

La configuración se encuentra en: utils/app.env
Ejemplo:
env
DB_DRIVER=sqlserver
DB_SOURCE=server=localhost;database=reservasdbV2;user id=TU_USUARIO;password=TU_PASSWORD;encrypt=true;TrustServerCertificate=true

SERVER_URL=127.0.0.1:8080
API_VERSION=api/v1

SECRET=secret
TOKEN_SYMMETRIC_KEY=12345678901234567890123456789012

ADMIN_NAME=Administrador
ADMIN_EMAIL=admin@hotel.com
ADMIN_PASSWORD=admin123
ADMIN_ROLE=Administrador

El usuario y contraseña de SQL Server deben corresponder a una cuenta que tenga acceso a `reservasdbV2`.

## 5. Ejecutar el backend
Desde la raíz del proyecto: go run .
El backend estará disponible en: http://127.0.0.1:8080

Y la API utiliza como ruta base: http://127.0.0.1:8080/api/v1

## Estructura principal
reserva-backend/
│
├── api/
│   ├── handlers/
│   ├── middleware/
│   ├── routes.go
│   └── server.go
│
├── db/
│   ├── procedures/
│   ├── views/
│   └── triggers/
│
├── models/
├── repository/
├── security/
├── utils/
├── docs/
├── main.go
├── go.mod
└── README.MD

## Arquitectura
Frontend Angular
      ↓
API Go + Gin
      ↓
Handlers
      ↓
Repositories
      ↓
SQL Server