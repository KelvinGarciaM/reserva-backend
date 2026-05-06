package api

import (
	"reserva-backend/api/handlers"
	"reserva-backend/api/middleware"

	"github.com/gin-gonic/gin"
)

type Handlers struct {
	UserHandler          *handlers.UserHandler
	AuthHandler          *handlers.AuthHandler
	ReservaHandler       *handlers.ReservaHandler
	ClienteHandler       *handlers.ClienteHandler
	TipoClienteHandler   *handlers.TipoClienteHandler
	RecepcionistaHandler *handlers.RecepcionistaHandler
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

		// CLIENTES
		api.POST("/clientes", h.ClienteHandler.RegisterCliente)
		api.GET("/clientes", h.ClienteHandler.GetClientes)
		api.GET("/clientes/buscar", h.ClienteHandler.SearchClientes)
		api.GET("/clientes/tipo/:idtipocliente", h.ClienteHandler.GetClientesByTipoCliente)
		api.GET("/clientes/:cedula", h.ClienteHandler.GetClienteByCedula)
		api.PUT("/clientes", h.ClienteHandler.UpdateCliente)
		api.DELETE("/clientes", h.ClienteHandler.DeleteCliente)
		api.PUT("/clientes/toggle", h.ClienteHandler.ToggleClienteEstado)

		// TIPO CLIENTES
		api.POST("/tipo-clientes", h.TipoClienteHandler.CreateTipoCliente)
		api.GET("/tipo-clientes", h.TipoClienteHandler.GetTipoClientes)
		api.GET("/tipo-clientes/buscar", h.TipoClienteHandler.SearchTipoClientes)
		api.GET("/tipo-clientes/:id", h.TipoClienteHandler.GetTipoClienteById)
		api.PUT("/tipo-clientes", h.TipoClienteHandler.UpdateTipoCliente)
		api.DELETE("/tipo-clientes", h.TipoClienteHandler.DeleteTipoCliente)
		api.PUT("/tipo-clientes/toggle", h.TipoClienteHandler.ToggleTipoClienteEstado)

		// RECEPCIONISTAS
		api.POST("/recepcionistas", h.RecepcionistaHandler.CreateRecepcionista)
		api.GET("/recepcionistas", h.RecepcionistaHandler.GetRecepcionistas)
		api.GET("/recepcionistas/buscar", h.RecepcionistaHandler.SearchRecepcionistas)
		api.GET("/recepcionistas/:cedula", h.RecepcionistaHandler.GetRecepcionistaByCedula)
		api.PUT("/recepcionistas", h.RecepcionistaHandler.UpdateRecepcionista)
		api.DELETE("/recepcionistas", h.RecepcionistaHandler.DeleteRecepcionista)
		api.PUT("/recepcionistas/toggle", h.RecepcionistaHandler.ToggleRecepcionistaEstado)

	}
}
