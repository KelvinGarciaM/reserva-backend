/* ============================================================================
   14. SEGURIDAD: LOGINS, USUARIOS, ROLES Y PRIVILEGIOS
   ----------------------------------------------------------------------------
   Dos usuarios reales del motor SQL Server con privilegios distintos. La
   aplicación inicia sesión con ellos y habilita o deshabilita funciones según
   el rol (rol_admin_hotel o rol_recepcion).
   La autenticación y los permisos los controla el motor de base de datos
   (no existe una tabla de usuarios en la aplicación).
   Las contraseñas de ejemplo van también en el documento escrito (apartado i).
   ============================================================================ */

/* ---------- 14.1 Logins a nivel de servidor ---------- */
USE master;
GO
IF SUSER_ID(N'login_admin_hotel') IS NULL
    CREATE LOGIN login_admin_hotel
        WITH PASSWORD = N'Admin#Hotel2026!',
             CHECK_POLICY = ON, CHECK_EXPIRATION = OFF,
             DEFAULT_DATABASE = reservasdbV2;
GO
IF SUSER_ID(N'login_recepcion_hotel') IS NULL
    CREATE LOGIN login_recepcion_hotel
        WITH PASSWORD = N'Recep#Hotel2026!',
             CHECK_POLICY = ON, CHECK_EXPIRATION = OFF,
             DEFAULT_DATABASE = reservasdbV2;
GO

/* El administrador necesita usuario en master solo para poder ejecutar el
   procedimiento de restauración. */
IF USER_ID(N'usr_admin_hotel_master') IS NULL
    CREATE USER usr_admin_hotel_master FOR LOGIN login_admin_hotel;
GO
GRANT EXECUTE ON dbo.pa_Restaurar_reservasdbV2 TO usr_admin_hotel_master;
GO

/* ---------- 14.2 Usuarios y roles en la base de datos ---------- */
USE reservasdbV2;
GO

CREATE USER usr_admin_hotel     FOR LOGIN login_admin_hotel;
CREATE USER usr_recepcion_hotel FOR LOGIN login_recepcion_hotel;
GO

CREATE ROLE rol_admin_hotel;
CREATE ROLE rol_recepcion;
GO
ALTER ROLE rol_admin_hotel ADD MEMBER usr_admin_hotel;
ALTER ROLE rol_recepcion   ADD MEMBER usr_recepcion_hotel;
GO

/* ---------- 14.3 ADMINISTRADOR: privilegios completos ---------- */
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO rol_admin_hotel;
GO

/* ---------- 14.4 RECEPCIÓN: privilegios restringidos ----------
   - Lectura de las tablas operativas; la escritura solo mediante
     procedimientos almacenados (INSERT, UPDATE y DELETE directos negados).
   - Solo ve vistas de operación diaria; no ve recepcionistas,
     auditoría ni respaldos.
   - Solo ejecuta procedimientos de clientes, reservas y detalle de reserva. */
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rol_recepcion;

GRANT SELECT ON dbo.vw_Cliente_Detalle        TO rol_recepcion;
GRANT SELECT ON dbo.vw_Habitacion_Detalle     TO rol_recepcion;
GRANT SELECT ON dbo.vw_Reserva_Detalle        TO rol_recepcion;
GRANT SELECT ON dbo.vw_DetalleReserva_Detalle TO rol_recepcion;
GRANT SELECT ON dbo.vw_TipoHabitacion_Resumen TO rol_recepcion;
GRANT SELECT ON dbo.vw_TipoCliente_Resumen    TO rol_recepcion;
GRANT SELECT ON dbo.vw_Tarifa_Detalle         TO rol_recepcion;

GRANT SELECT  ON dbo.fn_HabitacionesDisponibles  TO rol_recepcion;
GRANT SELECT  ON dbo.fn_TarifasVigentes          TO rol_recepcion;
GRANT SELECT  ON dbo.fn_HistorialReservasCliente TO rol_recepcion;
GRANT EXECUTE ON dbo.fn_TotalReservasHuesped     TO rol_recepcion;
GRANT EXECUTE ON dbo.fn_NochesEstancia           TO rol_recepcion;
GRANT EXECUTE ON dbo.fn_RecepcionistaActual       TO rol_recepcion;

-- Lectura de las tablas operativas que consulta directamente la aplicación
-- (habitaciones disponibles, fechas ocupadas, tarifa de una habitación, etc.).
-- Solo lectura: no incluye recepcionistas, auditoría ni la asignación de
-- logins, y la escritura sigue negada (DENY INSERT, UPDATE, DELETE).
GRANT SELECT ON dbo.cliente        TO rol_recepcion;
GRANT SELECT ON dbo.tipocliente    TO rol_recepcion;
GRANT SELECT ON dbo.tipohabitacion TO rol_recepcion;
GRANT SELECT ON dbo.habitacion     TO rol_recepcion;
GRANT SELECT ON dbo.tarifa         TO rol_recepcion;
GRANT SELECT ON dbo.reserva        TO rol_recepcion;
GRANT SELECT ON dbo.detallereserva TO rol_recepcion;

-- Mantenimiento de vigencia de tarifas (solo actualiza estados según fechas);
-- la aplicación lo invoca al consultar tarifas.
GRANT EXECUTE ON dbo.pa_Tarifa_SincronizarVigencia TO rol_recepcion;

GRANT EXECUTE ON dbo.pa_Cliente_Crear                   TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_Cliente_Actualizar              TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_Reserva_Crear                   TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_Reserva_Actualizar              TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_Reserva_ActualizarEstadoReserva TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_DetalleReserva_Crear            TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_DetalleReserva_Actualizar       TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_Auditoria_RegistrarSesion       TO rol_recepcion;

-- Operaciones que la aplicación permite a recepción (activar/desactivar y
-- consultas de catálogos que se usan al crear clientes y reservas)
GRANT EXECUTE ON dbo.pa_Cliente_CambiarEstado           TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_Reserva_ToggleEstado            TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_DetalleReserva_ToggleEstado     TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_TipoCliente_Listar              TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_TipoCliente_Buscar              TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_TipoCliente_ObtenerPorId        TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_TipoHabitacion_Listar           TO rol_recepcion;
GRANT EXECUTE ON dbo.pa_TipoHabitacion_ObtenerPorId     TO rol_recepcion;

/* Prohibiciones explícitas (recepción) */
DENY SELECT  ON dbo.vw_Recepcionista_Resumen TO rol_recepcion;
DENY SELECT  ON dbo.vw_Auditoria_Reciente    TO rol_recepcion;
DENY SELECT  ON dbo.auditoriaSesion          TO rol_recepcion;
DENY SELECT  ON dbo.auditoriaReserva         TO rol_recepcion;
DENY SELECT  ON dbo.auditoriaTarifa          TO rol_recepcion;
DENY SELECT  ON dbo.auditoriaRespaldo        TO rol_recepcion;
DENY SELECT  ON dbo.auditoriaTipoHabitacion  TO rol_recepcion;
DENY SELECT  ON dbo.recepcionistalogin      TO rol_recepcion;
DENY EXECUTE ON dbo.pa_Respaldo_Crear        TO rol_recepcion;
DENY EXECUTE ON dbo.pa_Respaldo_Listar       TO rol_recepcion;
GO