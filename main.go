package main

import (
	"database/sql"
	"log"

	"reserva-backend/api"
	"reserva-backend/conexion"
	docs "reserva-backend/docs"
	"reserva-backend/repository"
	"reserva-backend/security"
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
// @description Escribe "Bearer " + tu token. Ejemplo: "Bearer v2.local...."

func main() {
	docs.SwaggerInfo.BasePath = "/api/v1"

	// 1. Cargar configuración
	config, err := utils.LoadConfig("./utils")
	if err != nil {
		log.Fatal("Error cargando config:", err)
	}

	// 2. Verificación de conectividad con SQL Server.
	// DB_SOURCE solo se usa para comprobar que el servidor responde y como
	// plantilla (servidor y base) del login. Esta conexión se cierra enseguida:
	// cada persona trabaja con SU propia conexión, con su usuario del motor.
	conn, err := sql.Open(config.DBDriver, config.DBSource)
	if err != nil {
		log.Fatal("Error preparando la conexión:", err)
	}

	if err := conn.Ping(); err != nil {
		log.Fatal("No fue posible conectar con SQL Server:", err)
	}
	_ = conn.Close()

	log.Println("Conexión con SQL Server verificada correctamente")

	// 3. Selector de conexión por usuario y almacén de sesiones
	resolver := conexion.NewResolver()
	sessions := security.NewSessionStore()

	// 4. Repositorios (usan la conexión del usuario que hace la petición)
	tipoHabitacionRepository :=
		repository.NewTipoHabitacionRepository(resolver)

	tipoClienteRepository :=
		repository.NewTipoClienteRepository(resolver)

	recepcionistaRepository :=
		repository.NewRecepcionistaRepository(resolver)

	clienteRepository :=
		repository.NewClienteRepository(resolver)

	tarifaRepository :=
		repository.NewTarifaRepository(resolver)

	habitacionRepository :=
		repository.NewHabitacionRepository(resolver)

	reservaRepository :=
		repository.NewReservaRepository(resolver)

	detalleReservaRepository :=
		repository.NewDetalleReservaRepository(resolver)

	// 5. Server
	server, err := api.NewServer(
		tipoHabitacionRepository,
		tipoClienteRepository,
		recepcionistaRepository,
		clienteRepository,
		tarifaRepository,
		habitacionRepository,
		reservaRepository,
		detalleReservaRepository,
		sessions,
		config.DBSource,
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
