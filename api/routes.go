package api

import (
	"reserva-backend/api/handlers"
	"reserva-backend/api/middleware"

	"github.com/gin-gonic/gin"
)

type Handlers struct {
	UserHandler    *handlers.UserHandler
	AuthHandler    *handlers.AuthHandler
	ReservaHandler *handlers.ReservaHandler
}

func SetupRoutes(r *gin.Engine, h Handlers) {

	// =========================
	// PUBLIC
	// =========================
	api := r.Group("/api/v1")
	{
		// PUBLIC
		api.POST("/users", h.UserHandler.Register)
		api.POST("/login", h.AuthHandler.Login)
	}

	// =========================
	// PROTECTED
	// =========================
	protected := r.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware())
	{
		// USERS
		protected.GET("/users", h.UserHandler.GetUsers)
		protected.GET("/users/:email", h.UserHandler.GetUserByEmail)
		protected.PUT("/users", h.UserHandler.UpdateUser)
		protected.DELETE("/users", h.UserHandler.DeleteUser)

		//  RESERVAS
		protected.POST("/reservas", h.ReservaHandler.Register)
		protected.GET("/reservas", h.ReservaHandler.GetReservas)
		protected.GET("/reservas/:id", h.ReservaHandler.GetReservaById)
		protected.GET("/reservas/cliente/:id", h.ReservaHandler.GetReservasByCliente)
		protected.GET("/reservas/recepcionista/:id", h.ReservaHandler.GetReservasByRecepcionista)
		protected.PUT("/reservas/:id", h.ReservaHandler.UpdateReserva)
		protected.DELETE("/reservas/:id", h.ReservaHandler.DeleteReserva)
	}
}
