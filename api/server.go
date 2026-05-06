package api

import (
	"reserva-backend/api/handlers"
	"reserva-backend/dto"
	"time"

	"github.com/gin-gonic/gin"
	cors "github.com/itsjamie/gin-cors"
)

type Server struct {
	dbtx   *dto.Queries
	router *gin.Engine
}

func NewServer(dbtx *dto.Queries) (*Server, error) {

	server := &Server{
		dbtx: dbtx,
	}

	userHandler := handlers.NewUserHandler(dbtx)
	authHandler := handlers.NewAuthHandler(dbtx)
	reservaHandler := handlers.NewReservaHandler(dbtx)
	detalleReservaHandler := handlers.NewDetalleReservaHandler(dbtx)

	router := gin.Default()

	router.Use(cors.Middleware(cors.Config{
		Origins:        "*",
		Methods:        "GET,POST,PUT,DELETE",
		RequestHeaders: "Origin,Authorization,Content-Type",
		MaxAge:         50 * time.Second,
	}))

	SetupRoutes(router, Handlers{
		UserHandler:           userHandler,
		AuthHandler:           authHandler,
		ReservaHandler:        reservaHandler,
		DetalleReservaHandler: detalleReservaHandler,
	})

	server.router = router
	return server, nil
}

func (server *Server) Start(url string) error {
	return server.router.Run(url)
}
