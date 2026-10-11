USE reservasdbV2;
GO

/* tarifa: búsqueda de la tarifa vigente por tipo y rango de fechas
   (fn_TarifasVigentes, pa_Tarifa_SincronizarVigencia). */
CREATE NONCLUSTERED INDEX ix_tarifa_tipo_vigencia
    ON dbo.tarifa (idTipoHabitacion, fechaInicio, fechaFin)
    INCLUDE (precioBase, estado, desactivadaManual);
GO
