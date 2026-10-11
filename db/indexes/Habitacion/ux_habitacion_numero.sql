USE reservasdbV2;
GO

CREATE UNIQUE NONCLUSTERED INDEX ux_habitacion_numero
    ON dbo.habitacion (numeroHabitacion);
GO
