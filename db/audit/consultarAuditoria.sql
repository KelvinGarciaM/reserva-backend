/* ============================================================================
   CONSULTAS DE AUDITORÍA (para revisar y para la demostración)
   Ejecutar conectado como login_admin_hotel o con tu usuario de Windows.
   Con login_recepcion_hotel estas consultas dan "permiso denegado" (a propósito).
   ============================================================================ */
USE reservasdbV2;
GO

/* ---------- 1. TODO JUNTO (lo más reciente primero) ----------
   Une sesiones, reservas, tarifas y respaldos en una sola lista. */
SELECT TOP (100) *
FROM dbo.vw_Auditoria_Reciente
ORDER BY fecha DESC;
GO

/* ---------- 2. INICIOS Y CIERRES DE SESIÓN ---------- */
SELECT idAuditoriaSesion, fechaHora, loginBD, rolBD, accion, ipOrigen, detalle
FROM dbo.auditoriaSesion
ORDER BY fechaHora DESC;
GO

/* ---------- 3. CAMBIOS EN RESERVAS ----------
   Muestra el antes y el después de cada cambio. */
SELECT idAuditoria, fechaCambio, usuarioBD, accion, idReserva,
       idClienteNuevo, idRecepcionistaNuevo,
       estadoReservaAnterior, estadoReservaNuevo,
       totalAnterior, totalNuevo
FROM dbo.auditoriaReserva
ORDER BY fechaCambio DESC;
GO

/* ---------- 4. CAMBIOS EN TARIFAS ---------- */
SELECT idAuditoria, fechaCambio, usuarioBD, accion, idTarifa,
       precioBaseAnterior, precioBaseNuevo,
       fechaInicioAnterior, fechaInicioNueva,
       fechaFinAnterior, fechaFinNueva,
       estadoAnterior, estadoNuevo
FROM dbo.auditoriaTarifa
ORDER BY fechaCambio DESC;
GO

/* ---------- 5. RESPALDOS Y RESTAURACIONES ---------- */
SELECT idAuditoria, fechaHora, usuarioBD, tipoOperacion, resultado, archivo, mensaje
FROM dbo.auditoriaRespaldo
ORDER BY fechaHora DESC;
GO

/* ---------- 6. CAMBIOS EN TIPOS DE HABITACIÓN ---------- */
SELECT *
FROM dbo.auditoriaTipoHabitacion;
GO

/* ============================================================================
   FILTROS ÚTILES
   ============================================================================ */

/* ---------- 7. Solo lo que hizo un usuario ---------- */
SELECT * FROM dbo.vw_Auditoria_Reciente
WHERE usuario = 'login_recepcion_hotel'
ORDER BY fecha DESC;
GO

/* ---------- 8. Solo lo de hoy ---------- */
SELECT * FROM dbo.vw_Auditoria_Reciente
WHERE fecha >= CAST(GETDATE() AS DATE)
ORDER BY fecha DESC;
GO

/* ---------- 9. Historia completa de UNA reserva (cambia el número) ---------- */
SELECT fechaCambio, usuarioBD, accion,
       estadoReservaAnterior, estadoReservaNuevo,
       totalAnterior, totalNuevo
FROM dbo.auditoriaReserva
WHERE idReserva = 7
ORDER BY fechaCambio;
GO

/* ---------- 10. Resumen: cuántas acciones hizo cada usuario ---------- */
SELECT usuario, origen, accion, COUNT(*) AS cantidad
FROM dbo.vw_Auditoria_Reciente
GROUP BY usuario, origen, accion
ORDER BY usuario, origen, accion;
GO

/* ---------- 11. Últimas sesiones por usuario ---------- */
SELECT loginBD, rolBD, accion, MAX(fechaHora) AS ultimaVez, COUNT(*) AS veces
FROM dbo.auditoriaSesion
GROUP BY loginBD, rolBD, accion
ORDER BY loginBD, accion;
GO

/* ---------- 12. Entre dos fechas (ajusta las fechas) ---------- */
SELECT * FROM dbo.vw_Auditoria_Reciente
WHERE fecha >= '20261001' AND fecha < '20261101'
ORDER BY fecha DESC;
GO

/* ============================================================================
   PRUEBA PARA LA DEMO: recepción NO puede ver la auditoría
   (debe fallar con "The SELECT permission was denied")
   ============================================================================ */
EXECUTE AS USER = 'usr_recepcion_hotel';
BEGIN TRY
    SELECT TOP (1) * FROM dbo.auditoriaReserva;
END TRY
BEGIN CATCH
    SELECT 'Correcto: recepción no puede ver la auditoría' AS resultado,
           ERROR_MESSAGE() AS mensaje;
END CATCH;
REVERT;
GO