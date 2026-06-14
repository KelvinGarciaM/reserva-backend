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
		api.POST("/users", h.UserHandler.Register)
		api.POST("/login", h.AuthHandler.Login)
		api.GET("/users", h.UserHandler.GetUsers)

		// TARIFAS públicas
		api.GET("/tarifas", h.TarifaHandler.GetTarifas)
		api.GET("/tarifas/nombre/:nombreTarifa", h.TarifaHandler.GetTarifaByNombre)

		api.POST("/tarifas", h.TarifaHandler.CreateTarifa)
		api.PATCH("/tarifas/:idTarifa", h.TarifaHandler.UpdateTarifa)

		api.PATCH("/tarifas/:idTarifa/activar", h.TarifaHandler.ActivarTarifa)
		api.PATCH("/tarifas/:idTarifa/desactivar", h.TarifaHandler.DesactivarTarifa)
		api.GET("/tarifas/:idTarifa/estadisticas", h.TarifaHandler.GetEstadisticasTarifa)
	}

	// =========================
	// PROTECTED (requiere autenticación)
	// =========================
	protected := r.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware(builder))
	{
		// ========== SOLO ADMIN ==========
		admin := protected.Group("/")
		admin.Use(middleware.RoleMiddleware("Administrador"))
		{
			// USERS - solo admin puede modificar/eliminar
			admin.PUT("/users/:id", h.UserHandler.UpdateUser)
			// router
			admin.DELETE("/users/:id", h.UserHandler.ToggleUserStatus)

			// TIPO CLIENTES - solo admin puede crear/editar/eliminar
			admin.POST("/tipos-cliente", h.TipoClienteHandler.CreateTipoCliente)
			admin.PUT("/tipos-cliente", h.TipoClienteHandler.UpdateTipoCliente)
			admin.DELETE("/tipos-cliente", h.TipoClienteHandler.DeleteTipoCliente)
			admin.PUT("/tipos-cliente/toggle", h.TipoClienteHandler.ToggleTipoClienteEstado)

			// RECEPCIONISTAS - solo admin puede crear/editar/eliminar
			admin.POST("/recepcionistas", h.RecepcionistaHandler.CreateRecepcionista)
			admin.PUT("/recepcionistas", h.RecepcionistaHandler.UpdateRecepcionista)
			admin.DELETE("/recepcionistas", h.RecepcionistaHandler.DeleteRecepcionista)
			admin.PUT("/recepcionistas/toggle", h.RecepcionistaHandler.ToggleRecepcionistaEstado)

			// TIPO HABITACION - solo admin puede crear/editar/eliminar
			admin.POST("/tipos-habitacion", h.TipoHabitacionHandler.RegisterTipoHabitacion)
			admin.PUT("/tipos-habitacion/:id", h.TipoHabitacionHandler.UpdateTipoHabitacion)
			admin.DELETE("/tipos-habitacion/:id", h.TipoHabitacionHandler.DeleteTipoHabitacion)
			admin.GET("/tipos-habitacion/:id", h.TipoHabitacionHandler.GetTipoHabitacionByID)
			admin.GET("/tipos-habitacion", h.TipoHabitacionHandler.GetTipoHabitacion)
			// HABITACIONES - solo admin puede crear/editar/eliminar
			admin.POST("/habitaciones", h.HabitacionHandler.RegisterHabitacion)
			admin.PUT("/habitaciones/:id", h.HabitacionHandler.UpdateHabitacion)
			admin.DELETE("/habitaciones/:id", h.HabitacionHandler.DeleteHabitacion)
			// TIPO CLIENTES - solo lectura
			admin.GET("/tipos-cliente", h.TipoClienteHandler.GetTipoClientes)
			admin.GET("/tipos-cliente/buscar", h.TipoClienteHandler.SearchTipoClientes)
			admin.GET("/tipos-cliente/:id", h.TipoClienteHandler.GetTipoClienteById)

			// RECEPCIONISTAS - solo lectura
			admin.GET("/recepcionistas", h.RecepcionistaHandler.GetRecepcionistas)
			admin.GET("/recepcionistas/buscar", h.RecepcionistaHandler.SearchRecepcionistas)
			admin.GET("/recepcionistas/:cedula", h.RecepcionistaHandler.GetRecepcionistaByCedula)

			// HABITACIONES - solo lectura
			admin.GET("/habitaciones", h.HabitacionHandler.GetHabitaciones)
			admin.GET("/habitaciones/disponibles", h.HabitacionHandler.GetHabitacionesDisponibles)
			admin.GET("/habitaciones/:id", h.HabitacionHandler.GetHabitacionByID)
			admin.GET("/habitaciones/tipo/:id", h.HabitacionHandler.GetHabitacionesByTipoHab)
		}

		// ========== ADMIN + RECEPCIONISTA ==========
		staff := protected.Group("/")
		staff.Use(middleware.RoleMiddleware("Administrador", "Recepcionista"))
		{
			// USERS - solo lectura
			// staff.GET("/users", h.UserHandler.GetUsers)
			staff.GET("/users/:email", h.UserHandler.GetUserByEmail)
			staff.POST("/users/upload", h.UserHandler.UploadUserImg)
			staff.GET("/users/download/:filename", h.UserHandler.DownloadUserImg)

			// RESERVAS
			staff.POST("/reservas", h.ReservaHandler.Register)
			staff.GET("/reservas", h.ReservaHandler.GetReservas)
			staff.GET("/reservas/:id", h.ReservaHandler.GetReservaById)
			staff.GET("/reservas/cliente/:id", h.ReservaHandler.GetReservasByCliente)
			staff.GET("/reservas/recepcionista/:id", h.ReservaHandler.GetReservasByRecepcionista)
			staff.PUT("/reservas/:id", h.ReservaHandler.UpdateReserva)
			staff.DELETE("/reservas/:id", h.ReservaHandler.ToggleReserva)
			staff.PATCH("/reservas/:id/estado", h.ReservaHandler.UpdateEstadoReserva)

			// DETALLE RESERVA
			staff.POST("/detalles-reserva", h.DetalleReservaHandler.CreateDetalleReserva)
			staff.GET("/detalles-reserva", h.DetalleReservaHandler.GetAllDetalleReserva)
			staff.GET("/detalles-reserva/:idDetalleReserva", h.DetalleReservaHandler.GetDetalleReservaById)
			staff.GET("/detalles-reserva/reserva/:idReserva", h.DetalleReservaHandler.GetDetallesByReserva)
			staff.PATCH("/detalles-reserva/:idDetalleReserva", h.DetalleReservaHandler.UpdateDetalleReserva)
			staff.DELETE("/detalles-reserva/:idDetalleReserva", h.DetalleReservaHandler.DeleteDetalleReserva)
			staff.GET("/detalles-reserva/habitacion/:idHabitacion/fechas-ocupadas", h.DetalleReservaHandler.GetFechasOcupadasByHabitacion)

			staff.GET("/detalles-reserva/habitacion/:idHabitacion/tarifa", h.DetalleReservaHandler.GetTarifaByHabitacion)
			// CLIENTES
			staff.POST("/clientes", h.ClienteHandler.RegisterCliente)
			staff.GET("/clientes", h.ClienteHandler.GetClientes)
			staff.GET("/clientes/buscar", h.ClienteHandler.SearchClientes)
			staff.GET("/clientes/tipo/:idtipocliente", h.ClienteHandler.GetClientesByTipoCliente)
			staff.GET("/clientes/:cedula", h.ClienteHandler.GetClienteByCedula)
			staff.PUT("/clientes", h.ClienteHandler.UpdateCliente)
			staff.DELETE("/clientes", h.ClienteHandler.DeleteCliente)
			staff.PUT("/clientes/toggle", h.ClienteHandler.ToggleClienteEstado)

		}
	}
}
