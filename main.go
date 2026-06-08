package main

import (
	"database/sql"
	"log"

	"reserva-backend/api"
	docs "reserva-backend/docs"
	"reserva-backend/dto"
	"reserva-backend/utils"

	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	_ "github.com/go-sql-driver/mysql"
)

// @title API de Reservas
// @version 1.0
// @description API para sistema de reservas de hotel
// @host localhost:8080
// @BasePath /api/v1
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Escribe "Bearer " + tu token JWT. Ejemplo: "Bearer eyJhbGciOiJIUzI1NiIs..."

func main() {
	docs.SwaggerInfo.BasePath = "/api/v1"

	// 1. Cargar configuración
	config, err := utils.LoadConfig("./utils")
	if err != nil {
		log.Fatal("Error cargando config:", err)
	}

	// 2. Conexión a la base de datos
	conn, err := sql.Open(config.DBDriver, config.DBSource)
	if err != nil {
		log.Fatal("Error conectando DB:", err)
	}

	// 3. SQLC
	dbtx := dto.New(conn)

	// 4. Crear admin por defecto
	err = utils.SeedAdmin(dbtx, config)
	if err != nil {
		log.Fatal("Error creando admin:", err)
	}

	// 5. Server
	server, err := api.NewServer(dbtx, config.TokenSymmetricKey)
	if err != nil {
		log.Fatal("Error iniciando server:", err)
	}

	// 6. Configuración de Swagger para exponer la documentación de la API en /swagger
	server.Router.GET(
		"/swagger/*any",
		ginSwagger.WrapHandler(swaggerFiles.Handler),
	)
	// 7. Iniciar servidor
	err = server.Start(config.ServerURL)
	if err != nil {
		log.Fatal("Error al correr server:", err)
	}
}
