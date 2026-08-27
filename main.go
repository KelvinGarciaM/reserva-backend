package main

import (
	"database/sql"
	"log"

	"reserva-backend/api"
	docs "reserva-backend/docs"
	"reserva-backend/dto"
	"reserva-backend/repository"
	"reserva-backend/utils"

	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"

	_ "github.com/microsoft/go-mssqldb"
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
		log.Fatal("Error preparando la conexión:", err)
	}
	defer conn.Close()

	if err := conn.Ping(); err != nil {
		log.Fatal("No fue posible conectar con SQL Server:", err)
	}

	log.Println("Conexión con SQL Server establecida correctamente")
	// 3. SQLC temporalmente continua para los modulos donde no hemos hecho la migracion
	dbtx := dto.New(conn)
	//esto es neuvo para la migracion de mysql a sql server
	tipoHabitacionRepository :=
		repository.NewTipoHabitacionRepository(conn)
	usuarioRepository :=
		repository.NewUsuarioRepository(conn)

	err = utils.SeedAdmin(
		usuarioRepository,
		config,
	)
	if err != nil {
		log.Fatal("Error creando administrador:", err)
	}

	log.Println(
		"Administrador verificado correctamente:",
		config.AdminEmail,
	)
	// 5. Server
	server, err := api.NewServer(
		dbtx,
		tipoHabitacionRepository,
		usuarioRepository,
		config.TokenSymmetricKey,
	)
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
