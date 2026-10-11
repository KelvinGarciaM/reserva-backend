USE reservasdbV2;
GO

/* habitacion: se filtra por tipo y estado (fn_HabitacionesDisponibles).
   El número de habitación no debe repetirse (integridad + búsqueda rápida). */
CREATE NONCLUSTERED INDEX ix_habitacion_tipo
    ON dbo.habitacion (idTipoHab)
    INCLUDE (numeroHabitacion, estado);
GO
