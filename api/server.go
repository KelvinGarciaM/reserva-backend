package api

import (
	"reserva-backend/api/handlers"
	"reserva-backend/dto"
	"reserva-backend/security"
	"time"

	"github.com/gin-gonic/gin"
	cors "github.com/itsjamie/gin-cors"
)

type Server struct {
	dbtx         *dto.Queries
	Router       *gin.Engine
	tokenBuilder security.Builder
}

func NewServer(dbtx *dto.Queries, secret string) (*Server, error) {

	//Crear builder
	builder, err := security.NewPasetoBuilder(secret)
	if err != nil {
		return nil, err
	}

	server := &Server{
		dbtx:         dbtx,
		tokenBuilder: builder,
	}

	// HANDLERS
	userHandler := handlers.NewUserHandler(dbtx)
	authHandler := handlers.NewAuthHandler(dbtx, builder)
	reservaHandler := handlers.NewReservaHandler(dbtx)
	detalleReservaHandler := handlers.NewDetalleReservaHandler(dbtx)
	tarifaHandler := handlers.NewTarifaHandler(dbtx)
	clienteHandler := handlers.NewClienteHandler(dbtx)
	tipoClienteHandler := handlers.NewTipoClienteHandler(dbtx)
	recepcionistaHandler := handlers.NewRecepcionistaHandler(dbtx)
	tipoHabitacionHandler := handlers.NewTipoHabitacionHandler(dbtx)
	habitacionHandler := handlers.NewHabitacionHandler(dbtx)

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
