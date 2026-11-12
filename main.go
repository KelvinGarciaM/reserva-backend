package main

import (
	"database/sql"
	"log"
	"net/url"
	"os"

	"reserva-backend/api"
	"reserva-backend/api/handlers"
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

	// 2. Conexión usada SOLO para leer la tabla users durante el login
	// (todavía no hay sesión, así que se usa el login admin del motor).
	// DB_SOURCE se usa como plantilla: servidor y base de datos.
	dbAuth, err := abrirConexion(
		config.DBDriver,
		config.DBSource,
		config.DBAdminUser,
		config.DBAdminPassword,
	)
	if err != nil {
		log.Fatal("No fue posible conectar con SQL Server:", err)
	}
	defer dbAuth.Close()

	log.Println("Conexión con SQL Server verificada correctamente")

	// 3. Selector de conexión por usuario y almacén de sesiones
	resolver := conexion.NewResolver()
	sessions := security.NewSessionStore()

	// 4. Repositorios
	// El de usuarios usa la conexión de login (dbAuth).
	// Los demás usan la conexión de la sesión de quien hace la petición.
	usuarioRepository :=
		repository.NewUsuarioRepository(dbAuth)

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
		usuarioRepository,
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
		handlers.CredencialBD{
			Usuario: config.DBAdminUser,
			Clave:   config.DBAdminPassword,
		},
		handlers.CredencialBD{
			Usuario: config.DBRecepcionUser,
			Clave:   config.DBRecepcionPassword,
		},
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

	// 7. Iniciar servidor usando el puerto de Render
	port := os.Getenv("PORT")

	if port == "" {
		port = "8080"
	}

	log.Println("Iniciando backend en puerto:", port)

	err = server.Start(":" + port)
	if err != nil {
		log.Fatal("Error al correr server:", err)
	}
}

// abrirConexion toma DB_SOURCE (formato URL), le pone el usuario y la
// contraseña indicados y comprueba que el servidor los acepte.
func abrirConexion(driver, dsn, usuario, clave string) (*sql.DB, error) {
	u, err := url.Parse(dsn)
	if err != nil {
		return nil, err
	}
	u.User = url.UserPassword(usuario, clave)

	db, err := sql.Open(driver, u.String())
	if err != nil {
		return nil, err
	}

	if err := db.Ping(); err != nil {
		_ = db.Close()
		return nil, err
	}

	return db, nil
}
