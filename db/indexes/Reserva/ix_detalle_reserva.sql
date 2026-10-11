USE reservasdbV2;
GO

/* detallereserva:
   - Por reserva: lo usa el trigger trg_actualizar_totales_reserva para sumar
     los montos de cada reserva sin leer toda la tabla.
   - Por habitación y fechas: lo usa trg_evitar_reserva_habitacion_ocupada para
     detectar cruces de fechas, y fn_HabitacionesDisponibles.
   - Por tarifa: soporta la FK y los reportes por tarifa. */
CREATE NONCLUSTERED INDEX ix_detalle_reserva
    ON dbo.detallereserva (idReserva)
    INCLUDE (subTotal, iva, total, estado);
GO
