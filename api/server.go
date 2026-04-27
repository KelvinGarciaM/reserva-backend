package api

import (
	"time"

	"reserva-backend/api/handlers"
	"reserva-backend/api/middleware"
	"reserva-backend/dto"

	"github.com/gin-gonic/gin"
	cors "github.com/itsjamie/gin-cors"
)

type Server struct {
	dbtx        *dto.Queries
	router      *gin.Engine
	userHandler *handlers.UserHandler
	authHandler *handlers.AuthHandler
}

func NewServer(dbtx *dto.Queries) (*Server, error) {

	server := &Server{
		dbtx: dbtx,
	}

	// =========================
	// INIT HANDLERS
	// =========================
	server.userHandler = handlers.NewUserHandler(dbtx)
	server.authHandler = handlers.NewAuthHandler(dbtx)

	router := gin.Default()

	// =========================
	// CORS
	// =========================
	router.Use(cors.Middleware(cors.Config{
		Origins:         "*",
		Methods:         "GET,POST,PUT,DELETE",
		RequestHeaders:  "Origin,Authorization,Content-Type",
		ExposedHeaders:  "",
		MaxAge:          50 * time.Second,
		Credentials:     false,
		ValidateHeaders: false,
	}))

	// =========================
	// ROUTES PUBLICAS
	// =========================
	api := router.Group("/api/v1")
	{
		api.POST("/users", server.userHandler.Register)
		api.POST("/login", server.authHandler.Login)
	}

	// =========================
	// ROUTES PROTEGIDAS
	// =========================
	protected := router.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware())
	{
		protected.GET("/users", server.userHandler.GetUsers)
		protected.GET("/users/:email", server.userHandler.GetUserByEmail)
		protected.PUT("/users", server.userHandler.UpdateUser)
		protected.DELETE("/users", server.userHandler.DeleteUser)
	}

	server.router = router
	return server, nil
}

func (server *Server) Start(url string) error {
	return server.router.Run(url)
}
