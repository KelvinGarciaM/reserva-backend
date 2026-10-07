package api

import (
	"reserva-backend/api/handlers"
	"reserva-backend/repository"
	"reserva-backend/security"
	"time"

	"github.com/gin-gonic/gin"
	cors "github.com/itsjamie/gin-cors"
)

type Server struct {
	Router       *gin.Engine
	tokenBuilder security.Builder
}

func NewServer(
	tipoHabitacionRepository *repository.TipoHabitacionRepository,
	tipoClienteRepository *repository.TipoClienteRepository,
	recepcionistaRepository *repository.RecepcionistaRepository,
	clienteRepository *repository.ClienteRepository,
	tarifaRepository *repository.TarifaRepository,
	habitacionRepository *repository.HabitacionRepository,
	reservaRepository *repository.ReservaRepository,
	detalleReservaRepository *repository.DetalleReservaRepository,
	usuarioRepository *repository.UsuarioRepository,
	secret string,
) (*Server, error) {

	//Crear builder
	builder, err := security.NewPasetoBuilder(secret)
	if err != nil {
		return nil, err
	}

	server := &Server{
		tokenBuilder: builder,
	}

	// HANDLERS
	userHandler := handlers.NewUserHandler(usuarioRepository)
	authHandler := handlers.NewAuthHandler(usuarioRepository, builder)
	reservaHandler := handlers.NewReservaHandler(reservaRepository)
	detalleReservaHandler := handlers.NewDetalleReservaHandler(detalleReservaRepository)
	tarifaHandler := handlers.NewTarifaHandler(tarifaRepository)
	clienteHandler := handlers.NewClienteHandler(clienteRepository)
	tipoClienteHandler := handlers.NewTipoClienteHandler(tipoClienteRepository)
	recepcionistaHandler := handlers.NewRecepcionistaHandler(recepcionistaRepository)
	tipoHabitacionHandler := handlers.NewTipoHabitacionHandler(tipoHabitacionRepository)
	habitacionHandler := handlers.NewHabitacionHandler(habitacionRepository)

	// ROUTER
	router := gin.Default()

	router.Use(cors.Middleware(cors.Config{
		Origins:        "*",
		Methods:        "GET,POST,PUT,DELETE,PATCH",
		RequestHeaders: "Origin,Authorization,Content-Type",
		MaxAge:         50 * time.Second,
	}))

	// PASAMOS BUILDER A LAS RUTAS
	SetupRoutes(router, Handlers{
		UserHandler:           userHandler,
		AuthHandler:           authHandler,
		ReservaHandler:        reservaHandler,
		DetalleReservaHandler: detalleReservaHandler,
		TarifaHandler:         tarifaHandler,
		ClienteHandler:        clienteHandler,
		TipoClienteHandler:    tipoClienteHandler,
		RecepcionistaHandler:  recepcionistaHandler,
		TipoHabitacionHandler: tipoHabitacionHandler,
		HabitacionHandler:     habitacionHandler,
	}, builder)
	server.Router = router
	return server, nil
}

func (server *Server) Start(url string) error {
	return server.Router.Run(url)
}
