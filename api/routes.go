package api

import (
	"reserva-backend/api/handlers"
	"reserva-backend/api/middleware"
	"reserva-backend/security"

	"github.com/gin-gonic/gin"
)

type Handlers struct {
	UserHandler           *handlers.UserHandler
	AuthHandler           *handlers.AuthHandler
	ReservaHandler        *handlers.ReservaHandler
	TarifaHandler         *handlers.TarifaHandler
	DetalleReservaHandler *handlers.DetalleReservaHandler
	ClienteHandler        *handlers.ClienteHandler
	TipoClienteHandler    *handlers.TipoClienteHandler
	RecepcionistaHandler  *handlers.RecepcionistaHandler
}

func SetupRoutes(r *gin.Engine, h Handlers, builder security.Builder) {

	// =========================
	// PUBLIC
	// =========================
	api := r.Group("/api/v1")
	{
		api.POST("/users", h.UserHandler.Register)
		api.POST("/login", h.AuthHandler.Login)

		// TARIFAS públicas
		api.GET("/tarifas", h.TarifaHandler.GetTarifas)
		api.GET("/tarifas/:nombreTarifa", h.TarifaHandler.GetTarifaByNombre)
	}

	// =========================
	// PROTECTED
	// =========================
	protected := r.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware(builder))
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

		// CLIENTES
		protected.POST("/clientes", h.ClienteHandler.RegisterCliente)
		protected.GET("/clientes", h.ClienteHandler.GetClientes)
		protected.GET("/clientes/buscar", h.ClienteHandler.SearchClientes)
		protected.GET("/clientes/tipo/:idtipocliente", h.ClienteHandler.GetClientesByTipoCliente)
		protected.GET("/clientes/:cedula", h.ClienteHandler.GetClienteByCedula)
		protected.PUT("/clientes", h.ClienteHandler.UpdateCliente)
		protected.DELETE("/clientes", h.ClienteHandler.DeleteCliente)
		protected.PUT("/clientes/toggle", h.ClienteHandler.ToggleClienteEstado)

		// TIPO CLIENTES
		protected.POST("/tipo-clientes", h.TipoClienteHandler.CreateTipoCliente)
		protected.GET("/tipo-clientes", h.TipoClienteHandler.GetTipoClientes)
		protected.GET("/tipo-clientes/buscar", h.TipoClienteHandler.SearchTipoClientes)
		protected.GET("/tipo-clientes/:id", h.TipoClienteHandler.GetTipoClienteById)
		protected.PUT("/tipo-clientes", h.TipoClienteHandler.UpdateTipoCliente)
		protected.DELETE("/tipo-clientes", h.TipoClienteHandler.DeleteTipoCliente)
		protected.PUT("/tipo-clientes/toggle", h.TipoClienteHandler.ToggleTipoClienteEstado)

		// RECEPCIONISTAS
		protected.POST("/recepcionistas", h.RecepcionistaHandler.CreateRecepcionista)
		protected.GET("/recepcionistas", h.RecepcionistaHandler.GetRecepcionistas)
		protected.GET("/recepcionistas/buscar", h.RecepcionistaHandler.SearchRecepcionistas)
		protected.GET("/recepcionistas/:cedula", h.RecepcionistaHandler.GetRecepcionistaByCedula)
		protected.PUT("/recepcionistas", h.RecepcionistaHandler.UpdateRecepcionista)
		protected.DELETE("/recepcionistas", h.RecepcionistaHandler.DeleteRecepcionista)
		protected.PUT("/recepcionistas/toggle", h.RecepcionistaHandler.ToggleRecepcionistaEstado)
	}
}
