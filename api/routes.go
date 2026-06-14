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
	TipoHabitacionHandler *handlers.TipoHabitacionHandler
	HabitacionHandler     *handlers.HabitacionHandler
}

func SetupRoutes(r *gin.Engine, h Handlers, builder security.Builder) {

	// =========================
	// PUBLIC
	// =========================
	api := r.Group("/api/v1")
	{
		api.POST("/login", h.AuthHandler.Login)
	}

	// =========================
	// PROTECTED
	// =========================
	protected := r.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware(builder))
	{
		// ========== SOLO ADMIN ==========
		admin := protected.Group("/")
		admin.Use(middleware.RoleMiddleware("Administrador"))
		{
			// USERS
			admin.GET("/users", h.UserHandler.GetUsers)
			admin.POST("/users", h.UserHandler.Register)
			admin.PUT("/users/:id", h.UserHandler.UpdateUser)
			admin.DELETE("/users/:id", h.UserHandler.ToggleUserStatus)

			// TIPO CLIENTE - escritura
			admin.POST("/tipos-cliente", h.TipoClienteHandler.CreateTipoCliente)
			admin.PUT("/tipos-cliente", h.TipoClienteHandler.UpdateTipoCliente)
			admin.DELETE("/tipos-cliente", h.TipoClienteHandler.DeleteTipoCliente)
			admin.PUT("/tipos-cliente/toggle", h.TipoClienteHandler.ToggleTipoClienteEstado)

			// RECEPCIONISTAS - escritura
			admin.POST("/recepcionistas", h.RecepcionistaHandler.CreateRecepcionista)
			admin.PUT("/recepcionistas", h.RecepcionistaHandler.UpdateRecepcionista)
			admin.DELETE("/recepcionistas", h.RecepcionistaHandler.DeleteRecepcionista)
			admin.PUT("/recepcionistas/toggle", h.RecepcionistaHandler.ToggleRecepcionistaEstado)

			// TIPO HABITACION - escritura
			admin.POST("/tipos-habitacion", h.TipoHabitacionHandler.RegisterTipoHabitacion)
			admin.PUT("/tipos-habitacion/:id", h.TipoHabitacionHandler.UpdateTipoHabitacion)
			admin.DELETE("/tipos-habitacion/:id", h.TipoHabitacionHandler.DeleteTipoHabitacion)

			// HABITACIONES - escritura
			admin.POST("/habitaciones", h.HabitacionHandler.RegisterHabitacion)
			admin.PUT("/habitaciones/:id", h.HabitacionHandler.UpdateHabitacion)
			admin.DELETE("/habitaciones/:id", h.HabitacionHandler.DeleteHabitacion)

			// TARIFAS - escritura
			admin.POST("/tarifas", h.TarifaHandler.CreateTarifa)
			admin.PATCH("/tarifas/:idTarifa", h.TarifaHandler.UpdateTarifa)
			admin.PATCH("/tarifas/:idTarifa/activar", h.TarifaHandler.ActivarTarifa)
			admin.PATCH("/tarifas/:idTarifa/desactivar", h.TarifaHandler.DesactivarTarifa)

			// RECEPCIONISTAS - lectura solo admin
			admin.GET("/recepcionistas", h.RecepcionistaHandler.GetRecepcionistas)
			admin.GET("/recepcionistas/buscar", h.RecepcionistaHandler.SearchRecepcionistas)
			admin.GET("/recepcionistas/:cedula", h.RecepcionistaHandler.GetRecepcionistaByCedula)
		}

		// ========== ADMIN + RECEPCIONISTA ==========
		staff := protected.Group("/")
		staff.Use(middleware.RoleMiddleware("Administrador", "Recepcionista"))
		{
			// USERS
			staff.GET("/users/:email", h.UserHandler.GetUserByEmail)
			staff.POST("/users/upload", h.UserHandler.UploadUserImg)
			staff.GET("/users/download/:filename", h.UserHandler.DownloadUserImg)

			// TIPO CLIENTE - lectura
			staff.GET("/tipos-cliente", h.TipoClienteHandler.GetTipoClientes)
			staff.GET("/tipos-cliente/buscar", h.TipoClienteHandler.SearchTipoClientes)
			staff.GET("/tipos-cliente/:id", h.TipoClienteHandler.GetTipoClienteById)

			// TIPO HABITACION - lectura
			staff.GET("/tipos-habitacion", h.TipoHabitacionHandler.GetTipoHabitacion)
			staff.GET("/tipos-habitacion/:id", h.TipoHabitacionHandler.GetTipoHabitacionByID)

			// HABITACIONES - lectura
			staff.GET("/habitaciones", h.HabitacionHandler.GetHabitaciones)
			staff.GET("/habitaciones/disponibles", h.HabitacionHandler.GetHabitacionesDisponibles)
			staff.GET("/habitaciones/:id", h.HabitacionHandler.GetHabitacionByID)
			staff.GET("/habitaciones/tipo/:id", h.HabitacionHandler.GetHabitacionesByTipoHab)

			// TARIFAS - lectura
			staff.GET("/tarifas", h.TarifaHandler.GetTarifas)
			staff.GET("/tarifas/nombre/:nombreTarifa", h.TarifaHandler.GetTarifaByNombre)
			staff.GET("/tarifas/:idTarifa/estadisticas", h.TarifaHandler.GetEstadisticasTarifa)

			// CLIENTES
			staff.GET("/clientes", h.ClienteHandler.GetClientes)
			staff.GET("/clientes/buscar", h.ClienteHandler.SearchClientes)
			staff.GET("/clientes/tipo/:idtipocliente", h.ClienteHandler.GetClientesByTipoCliente)
			staff.GET("/clientes/:cedula", h.ClienteHandler.GetClienteByCedula)
			staff.POST("/clientes", h.ClienteHandler.RegisterCliente)
			staff.PUT("/clientes", h.ClienteHandler.UpdateCliente)
			staff.DELETE("/clientes", h.ClienteHandler.DeleteCliente)
			staff.PUT("/clientes/toggle", h.ClienteHandler.ToggleClienteEstado)

			// RESERVAS
			staff.GET("/reservas", h.ReservaHandler.GetReservas)
			staff.GET("/reservas/:id", h.ReservaHandler.GetReservaById)
			staff.GET("/reservas/cliente/:id", h.ReservaHandler.GetReservasByCliente)
			staff.GET("/reservas/recepcionista/:id", h.ReservaHandler.GetReservasByRecepcionista)
			staff.POST("/reservas", h.ReservaHandler.Register)
			staff.PUT("/reservas/:id", h.ReservaHandler.UpdateReserva)
			staff.DELETE("/reservas/:id", h.ReservaHandler.ToggleReserva)
			staff.PATCH("/reservas/:id/estado", h.ReservaHandler.UpdateEstadoReserva)

			// DETALLE RESERVA
			staff.GET("/detalles-reserva", h.DetalleReservaHandler.GetAllDetalleReserva)
			staff.GET("/detalles-reserva/:idDetalleReserva", h.DetalleReservaHandler.GetDetalleReservaById)
			staff.GET("/detalles-reserva/reserva/:idReserva", h.DetalleReservaHandler.GetDetallesByReserva)
			staff.GET("/detalles-reserva/habitacion/:idHabitacion/fechas-ocupadas", h.DetalleReservaHandler.GetFechasOcupadasByHabitacion)
			staff.GET("/detalles-reserva/habitacion/:idHabitacion/tarifa", h.DetalleReservaHandler.GetTarifaByHabitacion)
			staff.POST("/detalles-reserva", h.DetalleReservaHandler.CreateDetalleReserva)
			staff.PATCH("/detalles-reserva/:idDetalleReserva", h.DetalleReservaHandler.UpdateDetalleReserva)
			staff.DELETE("/detalles-reserva/:idDetalleReserva", h.DetalleReservaHandler.DeleteDetalleReserva)
		}
	}
}
