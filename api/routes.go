package api

import (
	"reserva-backend/api/handlers"
	"reserva-backend/api/middleware"

	"github.com/gin-gonic/gin"
)

type Handlers struct {
	UserHandler           *handlers.UserHandler
	AuthHandler           *handlers.AuthHandler
	ReservaHandler        *handlers.ReservaHandler
	TarifaHandler         *handlers.TarifaHandler
	DetalleReservaHandler *handlers.DetalleReservaHandler
}

func SetupRoutes(r *gin.Engine, h Handlers) {

	// =========================
	// PUBLIC
	// =========================
	api := r.Group("/api/v1")
	{
		api.POST("/users", h.UserHandler.Register)
		api.POST("/login", h.AuthHandler.Login)

		// Opcionalmente públicas
		api.GET("/tarifas", h.TarifaHandler.GetTarifas)
		api.GET("/tarifas/:nombreTarifa", h.TarifaHandler.GetTarifaByNombre)
	}

	protected := r.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware())
	{
		// USERS
		protected.GET("/users", h.UserHandler.GetUsers)
		protected.GET("/users/:email", h.UserHandler.GetUserByEmail)
		protected.PUT("/users", h.UserHandler.UpdateUser)
		protected.DELETE("/users", h.UserHandler.DeleteUser)

		// RESERVAS
		protected.POST("/reservas", h.ReservaHandler.Register)
		protected.GET("/reservas", h.ReservaHandler.GetReservas)
		protected.GET("/reservas/:id", h.ReservaHandler.GetReservaById)
		protected.GET("/reservas/cliente/:id", h.ReservaHandler.GetReservasByCliente)
		protected.GET("/reservas/recepcionista/:id", h.ReservaHandler.GetReservasByRecepcionista)
		protected.PUT("/reservas/:id", h.ReservaHandler.UpdateReserva)
		protected.DELETE("/reservas/:id", h.ReservaHandler.DeleteReserva)

		// DETALLE RESERVA
		protected.POST("/detallereservas", h.DetalleReservaHandler.CreateDetalleReserva)
		protected.GET("/detallereservas", h.DetalleReservaHandler.GetAllDetalleReserva)
		protected.GET("/detallereservas/:idDetalleReserva", h.DetalleReservaHandler.GetDetalleReservaById)
		protected.PATCH("/detallereservas/:idDetalleReserva", h.DetalleReservaHandler.UpdateDetalleReserva)
		protected.DELETE("/detallereservas/:idDetalleReserva", h.DetalleReservaHandler.DeleteDetalleReserva)

		// TARIFAS ADMIN
		protected.POST("/tarifas", h.TarifaHandler.CreateTarifa)
		protected.PATCH("/tarifas/:idTarifa", h.TarifaHandler.UpdateTarifa)
		protected.DELETE("/tarifas/:idTarifa", h.TarifaHandler.DeleteTarifa)
	}
}
