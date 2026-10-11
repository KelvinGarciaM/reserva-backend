/* ============================================================================
   PROYECTO FINAL - ADMINISTRACIÓN DE BASES DE DATOS AVANZADAS
   BASE DE DATOS: reservasdbV2
   MOTOR: Microsoft SQL Server
   SCRIPT MAESTRO COMPLETO (V2) - BACKEND ACTUAL + SEGURIDAD, INDICES,
   AUDITORIA, RESPALDO/RESTAURACION Y DATOS DE EJEMPLO

   FUENTE DE VERDAD PARA OBJETOS SQL:
   - db/views (archivos .sql)
   - db/procedures (archivos .sql)
   - db/function (archivos .sql)
   - db/triggers (archivos .sql)
   - triggers base de db/reservasdbV2.sql

   Se conserva del ScriptV1 únicamente la creación física de la BD, tablas,
   restricciones y datos iniciales. Las vistas, procedimientos, funciones y
   triggers se incorporan desde los archivos reales del backend, sin resumirlos.

   IMPORTANTE: este script RECREA reservasdbV2 desde cero.
   ============================================================================ */

USE master;
GO

/* ============================================================================
   1. ELIMINACIÓN CONTROLADA DE LA BASE (ENTORNO DE DESARROLLO / DEMOSTRACIÓN)
   ============================================================================ */
IF DB_ID(N'reservasdbV2') IS NOT NULL
BEGIN
    ALTER DATABASE reservasdbV2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE reservasdbV2;
END;
GO

/* ============================================================================
   2. CREACIÓN FÍSICA DE LA BASE DE DATOS

   Se utilizan las rutas DATA y LOG configuradas por defecto en la instancia
   de SQL Server. De esta forma el script especifica físicamente los archivos
   y sigue siendo portable entre las computadoras del equipo.
   ============================================================================ */
DECLARE @DataPath NVARCHAR(4000) = CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @LogPath  NVARCHAR(4000) = CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultLogPath'));

IF @DataPath IS NULL OR @LogPath IS NULL
BEGIN
    THROW 51000, 'No fue posible obtener las rutas por defecto DATA/LOG de SQL Server.', 1;
END;

IF RIGHT(@DataPath,1) NOT IN ('\','/')
    SET @DataPath = @DataPath + CASE WHEN CHARINDEX('/',@DataPath)>0 THEN '/' ELSE '\' END;
IF RIGHT(@LogPath,1) NOT IN ('\','/')
    SET @LogPath = @LogPath + CASE WHEN CHARINDEX('/',@LogPath)>0 THEN '/' ELSE '\' END;

DECLARE @CreateDb NVARCHAR(MAX);
SET @CreateDb = N'
CREATE DATABASE reservasdbV2
ON PRIMARY
(
    NAME = N''reservasdbV2'',
    FILENAME = N''' + REPLACE(@DataPath, '''', '''''') + N'reservasdbV2.mdf'',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 25MB
)
LOG ON
(
    NAME = N''reservasdbV2_log'',
    FILENAME = N''' + REPLACE(@LogPath, '''', '''''') + N'reservasdbV2_log.ldf'',
    SIZE = 15MB,
    MAXSIZE = 80MB,
    FILEGROWTH = 15%
);';

EXEC sys.sp_executesql @CreateDb;
GO

USE reservasdbV2;
GO

/* ============================================================================
   3. TABLAS
   ============================================================================ */

CREATE TABLE dbo.tipocliente
(
    idTipoCliente INT IDENTITY(1,1) NOT NULL,
    nombreTipoC VARCHAR(45) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    descuentoBase DECIMAL(10,2) NOT NULL
        CONSTRAINT df_tipocliente_descuento DEFAULT (0.00),
    estado TINYINT NOT NULL
        CONSTRAINT df_tipocliente_estado DEFAULT (1),

    CONSTRAINT pk_tipocliente PRIMARY KEY (idTipoCliente),
    CONSTRAINT chk_tipocliente_descuento CHECK (descuentoBase >= 0 AND descuentoBase <= 100),
    CONSTRAINT chk_tipocliente_estado CHECK (estado IN (0,1))
);
GO

CREATE TABLE dbo.cliente
(
    cedula VARCHAR(20) NOT NULL,
    idTipoCliente INT NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    apellidos VARCHAR(45) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_cliente_estado DEFAULT (1),

    CONSTRAINT pk_cliente PRIMARY KEY (cedula),
    CONSTRAINT fk_cliente_tipocliente
        FOREIGN KEY (idTipoCliente) REFERENCES dbo.tipocliente(idTipoCliente),
    CONSTRAINT chk_cliente_estado CHECK (estado IN (0,1))
);
GO

CREATE TABLE dbo.tipohabitacion
(
    idTipoHabitacion INT IDENTITY(1,1) NOT NULL,
    nombreTipoHab VARCHAR(45) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    capacidadMaxima INT NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_tipohabitacion_estado DEFAULT (1),

    CONSTRAINT pk_tipohabitacion PRIMARY KEY (idTipoHabitacion),
    CONSTRAINT chk_capacidad_maxima CHECK (capacidadMaxima > 0),
    CONSTRAINT chk_tipohabitacion_estado CHECK (estado IN (0,1))
);
GO

CREATE TABLE dbo.habitacion
(
    idHabitacion INT IDENTITY(1,1) NOT NULL,
    idTipoHab INT NOT NULL,
    numeroHabitacion VARCHAR(45) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_habitacion_estado DEFAULT (1),

    CONSTRAINT pk_habitacion PRIMARY KEY (idHabitacion),
    CONSTRAINT fk_habitacion_tipohabitacion
        FOREIGN KEY (idTipoHab) REFERENCES dbo.tipohabitacion(idTipoHabitacion),
    CONSTRAINT chk_habitacion_estado CHECK (estado IN (0,1))
);
GO

CREATE TABLE dbo.recepcionista
(
    cedula VARCHAR(20) NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    apellidos VARCHAR(45) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_recepcionista_estado DEFAULT (1),

    CONSTRAINT pk_recepcionista PRIMARY KEY (cedula),
    CONSTRAINT chk_recepcionista_estado CHECK (estado IN (0,1))
);
GO

CREATE TABLE dbo.reserva
(
    idReserva INT IDENTITY(1,1) NOT NULL,
    idRecepcionista VARCHAR(20) NOT NULL,
    idCliente VARCHAR(20) NOT NULL,
    fechaReserva DATETIME NOT NULL,
    estadoReserva VARCHAR(25) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_reserva_estado DEFAULT (1),
    iva DECIMAL(10,2) NOT NULL
        CONSTRAINT df_reserva_iva DEFAULT (0.00),
    subTotal DECIMAL(10,2) NOT NULL
        CONSTRAINT df_reserva_subtotal DEFAULT (0.00),
    total DECIMAL(10,2) NOT NULL
        CONSTRAINT df_reserva_total DEFAULT (0.00),

    CONSTRAINT pk_reserva PRIMARY KEY (idReserva),
    CONSTRAINT fk_reserva_recepcionista
        FOREIGN KEY (idRecepcionista) REFERENCES dbo.recepcionista(cedula),
    CONSTRAINT fk_reserva_cliente
        FOREIGN KEY (idCliente) REFERENCES dbo.cliente(cedula),
    CONSTRAINT chk_reserva_estado CHECK (estado IN (0,1)),
    CONSTRAINT chk_reserva_montos CHECK (iva >= 0 AND subTotal >= 0 AND total >= 0)
);
GO

CREATE TABLE dbo.tarifa
(
    idTarifa INT IDENTITY(1,1) NOT NULL,
    idTipoHabitacion INT NOT NULL,
    precioBase DECIMAL(10,2) NOT NULL,
    nombreTarifa VARCHAR(45) NOT NULL,
    fechaInicio DATE NULL,
    fechaFin DATE NULL,
    descripcion NVARCHAR(MAX) NULL,
    desactivadaManual TINYINT NOT NULL
        CONSTRAINT df_tarifa_desactivadamanual DEFAULT (0),
    estado TINYINT NOT NULL
        CONSTRAINT df_tarifa_estado DEFAULT (1),

    CONSTRAINT pk_tarifa PRIMARY KEY (idTarifa),
    CONSTRAINT fk_tarifa_tipohabitacion
        FOREIGN KEY (idTipoHabitacion) REFERENCES dbo.tipohabitacion(idTipoHabitacion),
    CONSTRAINT chk_precio_tarifa CHECK (precioBase >= 0),
    CONSTRAINT chk_tarifa_estado CHECK (estado IN (0,1)),
    CONSTRAINT chk_tarifa_desactivadamanual CHECK (desactivadaManual IN (0,1)),
    CONSTRAINT chk_tarifa_fechas CHECK (fechaInicio IS NULL OR fechaFin IS NULL OR fechaFin >= fechaInicio)
);
GO

CREATE TABLE dbo.detallereserva
(
    idDetalleReserva INT IDENTITY(1,1) NOT NULL,
    idHabitacion INT NOT NULL,
    idReserva INT NOT NULL,
    idTarifa INT NOT NULL,
    cantidadPersonas INT NOT NULL,
    precioAplicado DECIMAL(10,2) NOT NULL,
    fechaEntrada DATETIME NOT NULL,
    fechaSalida DATETIME NOT NULL,
    iva DECIMAL(10,2) NOT NULL,
    subTotal DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_detallereserva_estado DEFAULT (1),

    CONSTRAINT pk_detallereserva PRIMARY KEY (idDetalleReserva),
    CONSTRAINT fk_detallereserva_habitacion
        FOREIGN KEY (idHabitacion) REFERENCES dbo.habitacion(idHabitacion),
    CONSTRAINT fk_detallereserva_reserva
        FOREIGN KEY (idReserva) REFERENCES dbo.reserva(idReserva),
    CONSTRAINT fk_detallereserva_tarifa
        FOREIGN KEY (idTarifa) REFERENCES dbo.tarifa(idTarifa),
    CONSTRAINT chk_cantidad_personas CHECK (cantidadPersonas > 0),
    CONSTRAINT chk_fechas_reserva CHECK (fechaSalida > fechaEntrada),
    CONSTRAINT chk_detallereserva_estado CHECK (estado IN (0,1)),
    CONSTRAINT chk_detallereserva_montos CHECK
        (precioAplicado >= 0 AND iva >= 0 AND subTotal >= 0 AND total >= 0)
);
GO

/* ============================================================================
   4. DATOS INICIALES DE DESARROLLO
   ============================================================================ */

INSERT INTO dbo.tipocliente (nombreTipoC, descripcion, descuentoBase)
VALUES
('Regular', 'Cliente regular sin descuento', 0.00),
('VIP', 'Cliente VIP con descuento especial', 15.00),
('Empresarial', 'Cliente corporativo', 10.00);
GO

INSERT INTO dbo.cliente
(cedula, idTipoCliente, nombre, apellidos, telefono, direccion)
VALUES
('10101010', 1, 'Juan', 'Perez Mora', '8888-1111', 'San Jose, Costa Rica'),
('20202020', 2, 'Maria', 'Lopez Salas', '8888-2222', 'Heredia, Costa Rica'),
('30303030', 3, 'Carlos', 'Ramirez Vega', '8888-3333', 'Alajuela, Costa Rica'),
('40404040', 1, 'Laura', 'Jimenez Soto', '8888-4444', 'Cartago, Costa Rica'),
('50505050', 2, 'Pedro', 'Castro Nunez', '8888-5555', 'Limon, Costa Rica');
GO

INSERT INTO dbo.tipohabitacion
(nombreTipoHab, descripcion, capacidadMaxima)
VALUES
('Sencilla', 'Habitacion con una cama individual', 1),
('Doble', 'Habitacion con dos camas matrimoniales', 2),
('Suite', 'Habitacion de lujo con todas las amenidades', 4);
GO

INSERT INTO dbo.habitacion (idTipoHab, numeroHabitacion)
VALUES
(1, '101'), (1, '102'), (1, '103'),
(2, '201'), (2, '202'), (2, '203'),
(3, '301'), (3, '302');
GO

INSERT INTO dbo.recepcionista
(cedula, nombre, apellidos, telefono, correo)
VALUES
('504470975', 'Kelvin', 'Garcia Medrano', '8888-0001', 'kelvin@hotel.com'),
('112340001', 'Gerald', 'Araya Jimenez', '8888-0002', 'gerald@hotel.com'),
('223450002', 'Andy', 'Alvarado', '8888-0003', 'andy@hotel.com');
GO

INSERT INTO dbo.tarifa
(idTipoHabitacion, precioBase, nombreTarifa, fechaInicio, fechaFin, descripcion)
VALUES
(1, 35000, 'Temporada Baja Sencilla', '2026-01-01', '2026-06-30', 'Tarifa para habitacion sencilla en temporada baja'),
(1, 45000, 'Temporada Alta Sencilla', '2026-07-01', '2026-12-31', 'Tarifa para habitacion sencilla en temporada alta'),
(2, 55000, 'Temporada Baja Doble', '2026-01-01', '2026-06-30', 'Tarifa para habitacion doble en temporada baja'),
(2, 70000, 'Temporada Alta Doble', '2026-07-01', '2026-12-31', 'Tarifa para habitacion doble en temporada alta'),
(3, 75000, 'Temporada Baja Suite', '2026-01-01', '2026-06-30', 'Tarifa para suite en temporada baja'),
(3, 95000, 'Temporada Alta Suite', '2026-07-01', '2026-12-31', 'Tarifa para suite en temporada alta');
GO

/*
   Los usuarios de la aplicación NO se guardan en una tabla: son usuarios
   reales del motor (login_admin_hotel y login_recepcion_hotel), que se crean
   en la sección 14 junto con sus roles y permisos.
*/

/* ============================================================================
   5. VISTAS - DEFINICIONES REALES DEL BACKEND
   ============================================================================ */

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/views/tipoHabitacion.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_TipoHabitacion_Resumen
AS
SELECT
    th.idTipoHabitacion,
    th.nombreTipoHab,
    th.descripcion,
    th.capacidadMaxima,
    th.estado,
    COUNT(h.idHabitacion) AS cantidadHabitaciones
FROM dbo.tipohabitacion th
LEFT JOIN dbo.habitacion h
    ON h.idTipoHab = th.idTipoHabitacion
GROUP BY
    th.idTipoHabitacion,
    th.nombreTipoHab,
    th.descripcion,
    th.capacidadMaxima,
    th.estado;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/views/tipoCliente.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_TipoCliente_Resumen
AS
SELECT
    tc.idTipoCliente,
    tc.nombreTipoC,
    tc.descripcion,
    tc.descuentoBase,
    tc.estado,
    COUNT(c.cedula) AS cantidadClientes
FROM dbo.tipocliente tc
LEFT JOIN dbo.cliente c
    ON c.idTipoCliente = tc.idTipoCliente
GROUP BY
    tc.idTipoCliente,
    tc.nombreTipoC,
    tc.descripcion,
    tc.descuentoBase,
    tc.estado;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/views/recepcionista.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Recepcionista_Resumen
AS
SELECT
    r.cedula,
    r.nombre,
    r.apellidos,
    r.telefono,
    r.correo,
    r.estado,
    COUNT(re.idReserva) AS cantidadReservas,
    MAX(re.fechaReserva) AS ultimaReserva
FROM dbo.recepcionista r
LEFT JOIN dbo.reserva re
    ON re.idRecepcionista = r.cedula
GROUP BY
    r.cedula,
    r.nombre,
    r.apellidos,
    r.telefono,
    r.correo,
    r.estado;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/views/cliente.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Cliente_Detalle
AS
SELECT
    c.cedula,
    c.idTipoCliente,
    tc.nombreTipoC,
    c.nombre,
    c.apellidos,
    c.telefono,
    c.direccion,
    c.estado
FROM dbo.cliente AS c
INNER JOIN dbo.tipocliente AS tc
    ON tc.idTipoCliente = c.idTipoCliente;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/views/tarifa.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Tarifa_Detalle
AS
SELECT
    t.idTarifa,
    t.idTipoHabitacion,
    t.nombreTarifa,
    th.nombreTipoHab AS tipoHabitacion,
    t.precioBase,
    t.fechaInicio,
    t.fechaFin,
    t.descripcion,
    t.estado,
    t.desactivadaManual
FROM dbo.tarifa AS t
INNER JOIN dbo.tipohabitacion AS th
    ON th.idTipoHabitacion = t.idTipoHabitacion;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/views/habitacion.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Habitacion_Detalle
AS
SELECT
    h.idHabitacion,
    h.idTipoHab,
    th.nombreTipoHab,
    h.numeroHabitacion,
    h.estado
FROM dbo.habitacion AS h
INNER JOIN dbo.tipohabitacion AS th
    ON th.idTipoHabitacion = h.idTipoHab;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/views/reserva.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Reserva_Detalle
AS
SELECT
    r.idReserva,
    r.idRecepcionista,
    r.idCliente,

    CONCAT(c.nombre, ' ', c.apellidos)
        AS nombreCliente,

    CONCAT(re.nombre, ' ', re.apellidos)
        AS nombreRecepcionista,

    r.fechaReserva,
    r.estadoReserva,
    r.estado,
    r.iva,
    r.subTotal,
    r.total

FROM dbo.reserva AS r

INNER JOIN dbo.cliente AS c
    ON r.idCliente = c.cedula

INNER JOIN dbo.recepcionista AS re
    ON r.idRecepcionista = re.cedula;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/views/detalleReserva.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_DetalleReserva_Detalle
AS
SELECT
    dr.idDetalleReserva,
    dr.idHabitacion,
    dr.idReserva,
    dr.idTarifa,

    -- Habitación
    th.nombreTipoHab AS nombreTipoHabitacion,
    h.numeroHabitacion,

    -- Reserva
    CONCAT(rp.nombre, ' ', rp.apellidos)
        AS nombreRecepcionista,

    CONCAT(c.nombre, ' ', c.apellidos)
        AS nombreCliente,

    tc.nombreTipoC AS nombreTipoCliente,
    tc.descuentoBase,

    r.fechaReserva,
    r.estadoReserva,

    -- Tarifa
    t.nombreTarifa,

    -- Detalle
    dr.cantidadPersonas,
    dr.precioAplicado,
    dr.fechaEntrada,
    dr.fechaSalida,
    dr.iva,
    dr.subTotal,
    dr.total,
    dr.estado

FROM dbo.detallereserva AS dr

INNER JOIN dbo.habitacion AS h
    ON dr.idHabitacion = h.idHabitacion

INNER JOIN dbo.tipohabitacion AS th
    ON h.idTipoHab = th.idTipoHabitacion

INNER JOIN dbo.reserva AS r
    ON dr.idReserva = r.idReserva

INNER JOIN dbo.recepcionista AS rp
    ON r.idRecepcionista = rp.cedula

INNER JOIN dbo.cliente AS c
    ON r.idCliente = c.cedula

INNER JOIN dbo.tipocliente AS tc
    ON c.idTipoCliente = tc.idTipoCliente

INNER JOIN dbo.tarifa AS t
    ON dr.idTarifa = t.idTarifa;
GO


/* ============================================================================
   6. PROCEDIMIENTOS ALMACENADOS - DEFINICIONES REALES DEL BACKEND
   ============================================================================ */

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/procedures/tipoHabitacion.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

/* =========================================================
   1. LISTAR TIPOS DE HABITACIÓN
   @soloActivos:
       NULL = todos
       1    = activos
       0    = inactivos
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_Listar
    @soloActivos TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @soloActivos IS NOT NULL
           AND @soloActivos NOT IN (0, 1)
        BEGIN
            THROW 50001,
                'El parámetro soloActivos debe ser 0, 1 o NULL.',
                1;
        END;

        SELECT
            idTipoHabitacion,
            nombreTipoHab,
            descripcion,
            capacidadMaxima,
            estado
        FROM dbo.TipoHabitacion
        WHERE @soloActivos IS NULL
           OR estado = @soloActivos
        ORDER BY nombreTipoHab ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   2. OBTENER TIPO DE HABITACIÓN POR ID
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_ObtenerPorId
    @idTipoHabitacion INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @idTipoHabitacion IS NULL
           OR @idTipoHabitacion <= 0
        BEGIN
            THROW 50002,
                'El ID del tipo de habitación debe ser mayor que cero.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion
            WHERE idTipoHabitacion = @idTipoHabitacion
        )
        BEGIN
            THROW 50003,
                'El tipo de habitación solicitado no existe.',
                1;
        END;

        SELECT
            idTipoHabitacion,
            nombreTipoHab,
            descripcion,
            capacidadMaxima,
            estado
        FROM dbo.TipoHabitacion
        WHERE idTipoHabitacion = @idTipoHabitacion;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   3. CREAR TIPO DE HABITACIÓN
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_Crear
    @nombreTipoHab VARCHAR(45),
    @descripcion VARCHAR(100),
    @capacidadMaxima INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @nombreTipoHab = LTRIM(RTRIM(@nombreTipoHab));
        SET @descripcion = LTRIM(RTRIM(@descripcion));

        IF @nombreTipoHab IS NULL
           OR @nombreTipoHab = ''
        BEGIN
            THROW 50004,
                'El nombre del tipo de habitación es obligatorio.',
                1;
        END;

        IF @descripcion IS NULL
           OR @descripcion = ''
        BEGIN
            THROW 50005,
                'La descripción del tipo de habitación es obligatoria.',
                1;
        END;

        IF @capacidadMaxima IS NULL
           OR @capacidadMaxima <= 0
        BEGIN
            THROW 50006,
                'La capacidad máxima debe ser mayor que cero.',
                1;
        END;

        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTipoHab = @nombreTipoHab
        )
        BEGIN
            THROW 50007,
                'Ya existe un tipo de habitación con ese nombre.',
                1;
        END;

        INSERT INTO dbo.TipoHabitacion
        (
            nombreTipoHab,
            descripcion,
            capacidadMaxima,
            estado
        )
        VALUES
        (
            @nombreTipoHab,
            @descripcion,
            @capacidadMaxima,
            1
        );

        DECLARE @nuevoId INT;

        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idTipoHabitacion,
            'Tipo de habitación registrado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

/* =========================================================
   4. ACTUALIZAR TIPO DE HABITACIÓN
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_Actualizar
    @idTipoHabitacion INT,
    @nombreTipoHab VARCHAR(45),
    @descripcion VARCHAR(100),
    @capacidadMaxima INT,
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @nombreTipoHab = LTRIM(RTRIM(@nombreTipoHab));
        SET @descripcion = LTRIM(RTRIM(@descripcion));

        IF @idTipoHabitacion IS NULL
           OR @idTipoHabitacion <= 0
        BEGIN
            THROW 50008,
                'El ID del tipo de habitación debe ser mayor que cero.',
                1;
        END;

        IF @nombreTipoHab IS NULL
           OR @nombreTipoHab = ''
        BEGIN
            THROW 50009,
                'El nombre del tipo de habitación es obligatorio.',
                1;
        END;

        IF @descripcion IS NULL
           OR @descripcion = ''
        BEGIN
            THROW 50010,
                'La descripción del tipo de habitación es obligatoria.',
                1;
        END;

        IF @capacidadMaxima IS NULL
           OR @capacidadMaxima <= 0
        BEGIN
            THROW 50011,
                'La capacidad máxima debe ser mayor que cero.',
                1;
        END;

        IF @estado IS NULL
           OR @estado NOT IN (0, 1)
        BEGIN
            THROW 50012,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE idTipoHabitacion = @idTipoHabitacion
        )
        BEGIN
            THROW 50013,
                'El tipo de habitación que intenta actualizar no existe.',
                1;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTipoHab = @nombreTipoHab
              AND idTipoHabitacion <> @idTipoHabitacion
        )
        BEGIN
            THROW 50014,
                'Ya existe otro tipo de habitación con ese nombre.',
                1;
        END;

        UPDATE dbo.TipoHabitacion
        SET
            nombreTipoHab = @nombreTipoHab,
            descripcion = @descripcion,
            capacidadMaxima = @capacidadMaxima,
            estado = @estado
        WHERE idTipoHabitacion = @idTipoHabitacion;

        DECLARE @filasAfectadas INT;

        SET @filasAfectadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTipoHabitacion AS idTipoHabitacion,
            @filasAfectadas AS filasAfectadas,
            'Tipo de habitación actualizado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

/* =========================================================
   5. ELIMINAR LÓGICAMENTE UN TIPO DE HABITACIÓN
   No borra el registro: cambia estado a 0
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_Eliminar
    @idTipoHabitacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @idTipoHabitacion IS NULL
           OR @idTipoHabitacion <= 0
        BEGIN
            THROW 50015,
                'El ID del tipo de habitación debe ser mayor que cero.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE idTipoHabitacion = @idTipoHabitacion
        )
        BEGIN
            THROW 50016,
                'El tipo de habitación que intenta eliminar no existe.',
                1;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.TipoHabitacion
            WHERE idTipoHabitacion = @idTipoHabitacion
              AND estado = 0
        )
        BEGIN
            THROW 50017,
                'El tipo de habitación ya se encuentra inactivo.',
                1;
        END;

        UPDATE dbo.TipoHabitacion
        SET estado = 0
        WHERE idTipoHabitacion = @idTipoHabitacion;

        DECLARE @filasAfectadas INT;

        SET @filasAfectadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTipoHabitacion AS idTipoHabitacion,
            @filasAfectadas AS filasAfectadas,
            'Tipo de habitación eliminado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/procedures/tipoCliente.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO


/* =========================================================
   1. LISTAR TIPOS DE CLIENTE
   @soloActivos:
       NULL = todos
       1    = activos
       0    = inactivos
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Listar
    @soloActivos TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF @soloActivos IS NOT NULL
           AND @soloActivos NOT IN (0, 1)
        BEGIN
            THROW 50101,
                'El parámetro soloActivos debe ser 0, 1 o NULL.',
                1;
        END;

        SELECT
            idTipoCliente,
            nombreTipoC,
            descripcion,
            descuentoBase,
            estado
        FROM dbo.tipocliente
        WHERE @soloActivos IS NULL
           OR estado = @soloActivos
        ORDER BY nombreTipoC ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO


/* =========================================================
   2. OBTENER TIPO DE CLIENTE POR ID
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_ObtenerPorId
    @idTipoCliente INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF @idTipoCliente IS NULL
           OR @idTipoCliente <= 0
        BEGIN
            THROW 50102,
                'El ID del tipo de cliente debe ser mayor que cero.',
                1;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50103,
                'El tipo de cliente solicitado no existe.',
                1;
        END;

        SELECT
            idTipoCliente,
            nombreTipoC,
            descripcion,
            descuentoBase,
            estado
        FROM dbo.tipocliente
        WHERE idTipoCliente = @idTipoCliente;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO


/* =========================================================
   3. CREAR TIPO DE CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Crear
    @nombreTipoC VARCHAR(45),
    @descripcion VARCHAR(100),
    @descuentoBase DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @nombreTipoC = LTRIM(RTRIM(@nombreTipoC));
        SET @descripcion = LTRIM(RTRIM(@descripcion));

        IF @nombreTipoC IS NULL
           OR @nombreTipoC = ''
        BEGIN
            THROW 50104,
                'El nombre del tipo de cliente es obligatorio.',
                1;
        END;

        IF @descuentoBase IS NULL
           OR @descuentoBase < 0
        BEGIN
            THROW 50105,
                'El descuento base no puede ser negativo.',
                1;
        END;

        BEGIN TRANSACTION;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTipoC = @nombreTipoC
        )
        BEGIN
            THROW 50106,
                'Ya existe un tipo de cliente con ese nombre.',
                1;
        END;

        INSERT INTO dbo.tipocliente
        (
            nombreTipoC,
            descripcion,
            descuentoBase,
            estado
        )
        VALUES
        (
            @nombreTipoC,
            @descripcion,
            @descuentoBase,
            1
        );

        DECLARE @nuevoId INT;

        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idTipoCliente,
            'Tipo de cliente registrado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   4. ACTUALIZAR TIPO DE CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Actualizar
    @idTipoCliente INT,
    @nombreTipoC VARCHAR(45),
    @descripcion VARCHAR(100),
    @descuentoBase DECIMAL(10,2),
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @nombreTipoC = LTRIM(RTRIM(@nombreTipoC));
        SET @descripcion = LTRIM(RTRIM(@descripcion));

        IF @idTipoCliente IS NULL
           OR @idTipoCliente <= 0
        BEGIN
            THROW 50107,
                'El ID del tipo de cliente debe ser mayor que cero.',
                1;
        END;

        IF @nombreTipoC IS NULL
           OR @nombreTipoC = ''
        BEGIN
            THROW 50108,
                'El nombre del tipo de cliente es obligatorio.',
                1;
        END;

        IF @descuentoBase IS NULL
           OR @descuentoBase < 0
        BEGIN
            THROW 50109,
                'El descuento base no puede ser negativo.',
                1;
        END;

        IF @estado IS NULL
           OR @estado NOT IN (0, 1)
        BEGIN
            THROW 50110,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50111,
                'El tipo de cliente que intenta actualizar no existe.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTipoC = @nombreTipoC
              AND idTipoCliente <> @idTipoCliente
        )
        BEGIN
            THROW 50112,
                'Ya existe otro tipo de cliente con ese nombre.',
                1;
        END;

        UPDATE dbo.tipocliente
        SET
            nombreTipoC = @nombreTipoC,
            descripcion = @descripcion,
            descuentoBase = @descuentoBase,
            estado = @estado
        WHERE idTipoCliente = @idTipoCliente;

        DECLARE @filasAfectadas INT;

        SET @filasAfectadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTipoCliente AS idTipoCliente,
            @filasAfectadas AS filasAfectadas,
            'Tipo de cliente actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   5. ELIMINAR LÓGICAMENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Eliminar
    @idTipoCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF @idTipoCliente IS NULL
           OR @idTipoCliente <= 0
        BEGIN
            THROW 50113,
                'El ID del tipo de cliente debe ser mayor que cero.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente WITH (UPDLOCK, HOLDLOCK)
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50114,
                'El tipo de cliente que intenta eliminar no existe.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
              AND estado = 0
        )
        BEGIN
            THROW 50115,
                'El tipo de cliente ya se encuentra inactivo.',
                1;
        END;

        UPDATE dbo.tipocliente
        SET estado = 0
        WHERE idTipoCliente = @idTipoCliente;

        DECLARE @filasAfectadas INT;

        SET @filasAfectadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTipoCliente AS idTipoCliente,
            @filasAfectadas AS filasAfectadas,
            'Tipo de cliente eliminado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   6. ACTIVAR / DESACTIVAR
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_ToggleEstado
    @idTipoCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50116,
                'El tipo de cliente no existe.',
                1;
        END;

        UPDATE dbo.tipocliente
        SET estado =
            CASE
                WHEN estado = 1 THEN 0
                ELSE 1
            END
        WHERE idTipoCliente = @idTipoCliente;

        SELECT
            idTipoCliente,
            estado,
            'Estado actualizado exitosamente.' AS mensaje
        FROM dbo.tipocliente
        WHERE idTipoCliente = @idTipoCliente;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO


/* =========================================================
   7. BUSCAR TIPOS DE CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Buscar
    @busqueda VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        idTipoCliente,
        nombreTipoC,
        descripcion,
        descuentoBase,
        estado
    FROM dbo.tipocliente
    WHERE
        CAST(idTipoCliente AS VARCHAR(20)) LIKE @busqueda + '%'
        OR nombreTipoC LIKE @busqueda + '%'
        OR descripcion LIKE @busqueda + '%'
    ORDER BY nombreTipoC;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/procedures/recepcionista.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

/* ============================================
   1. LISTAR RECEPCIONISTAS
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Listar
    @soloActivos TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @soloActivos IS NOT NULL
       AND @soloActivos NOT IN (0, 1)
    BEGIN
        THROW 50201,
            'El parámetro soloActivos debe ser 0, 1 o NULL.',
            1;
    END;

    SELECT
        cedula,
        nombre,
        apellidos,
        telefono,
        correo,
        estado
    FROM dbo.recepcionista
    WHERE @soloActivos IS NULL
       OR estado = @soloActivos
    ORDER BY nombre, apellidos;
END;
GO


/* ============================================
   2. OBTENER POR CÉDULA
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_ObtenerPorCedula
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SET @cedula = LTRIM(RTRIM(@cedula));

    IF @cedula IS NULL OR @cedula = ''
    BEGIN
        THROW 50202,
            'La cédula es obligatoria.',
            1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.recepcionista
        WHERE cedula = @cedula
    )
    BEGIN
        THROW 50203,
            'El recepcionista solicitado no existe.',
            1;
    END;

    SELECT
        cedula,
        nombre,
        apellidos,
        telefono,
        correo,
        estado
    FROM dbo.recepcionista
    WHERE cedula = @cedula;
END;
GO


/* ============================================
   3. CREAR RECEPCIONISTA
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Crear
    @cedula VARCHAR(20),
    @nombre VARCHAR(45),
    @apellidos VARCHAR(45),
    @telefono VARCHAR(20),
    @correo VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @cedula = LTRIM(RTRIM(@cedula));
        SET @nombre = LTRIM(RTRIM(@nombre));
        SET @apellidos = LTRIM(RTRIM(@apellidos));
        SET @telefono = LTRIM(RTRIM(@telefono));
        SET @correo = LTRIM(RTRIM(@correo));

        IF @cedula IS NULL OR @cedula = ''
            THROW 50204, 'La cédula es obligatoria.', 1;

        IF @nombre IS NULL OR @nombre = ''
            THROW 50205, 'El nombre es obligatorio.', 1;

        IF @apellidos IS NULL OR @apellidos = ''
            THROW 50206, 'Los apellidos son obligatorios.', 1;

        IF @telefono IS NULL OR @telefono = ''
            THROW 50207, 'El teléfono es obligatorio.', 1;

        IF @correo IS NULL OR @correo = ''
            THROW 50208, 'El correo es obligatorio.', 1;

        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1
            FROM dbo.recepcionista WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50209,
                'Ya existe un recepcionista con esa cédula.',
                1;
        END;

        INSERT INTO dbo.recepcionista
        (
            cedula,
            nombre,
            apellidos,
            telefono,
            correo,
            estado
        )
        VALUES
        (
            @cedula,
            @nombre,
            @apellidos,
            @telefono,
            @correo,
            1
        );

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            'Recepcionista registrado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* ============================================
   4. ACTUALIZAR
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Actualizar
    @cedula VARCHAR(20),
    @nombre VARCHAR(45),
    @apellidos VARCHAR(45),
    @telefono VARCHAR(20),
    @correo VARCHAR(100),
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @cedula = LTRIM(RTRIM(@cedula));
        SET @nombre = LTRIM(RTRIM(@nombre));
        SET @apellidos = LTRIM(RTRIM(@apellidos));
        SET @telefono = LTRIM(RTRIM(@telefono));
        SET @correo = LTRIM(RTRIM(@correo));

        IF @estado NOT IN (0, 1)
        BEGIN
            THROW 50210,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.recepcionista WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50211,
                'El recepcionista que intenta actualizar no existe.',
                1;
        END;

        UPDATE dbo.recepcionista
        SET
            nombre = @nombre,
            apellidos = @apellidos,
            telefono = @telefono,
            correo = @correo,
            estado = @estado
        WHERE cedula = @cedula;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @filasAfectadas AS filasAfectadas,
            'Recepcionista actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* ============================================
   5. ELIMINAR LÓGICAMENTE
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Eliminar
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.recepcionista WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50212,
                'El recepcionista no existe.',
                1;
        END;

        IF EXISTS (
            SELECT 1
            FROM dbo.recepcionista
            WHERE cedula = @cedula
              AND estado = 0
        )
        BEGIN
            THROW 50213,
                'El recepcionista ya se encuentra inactivo.',
                1;
        END;

        UPDATE dbo.recepcionista
        SET estado = 0
        WHERE cedula = @cedula;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @filasAfectadas AS filasAfectadas,
            'Recepcionista desactivado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* ============================================
   6. ACTIVAR / DESACTIVAR
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_ToggleEstado
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.recepcionista
        WHERE cedula = @cedula
    )
    BEGIN
        THROW 50214,
            'El recepcionista no existe.',
            1;
    END;

    UPDATE dbo.recepcionista
    SET estado =
        CASE
            WHEN estado = 1 THEN 0
            ELSE 1
        END
    WHERE cedula = @cedula;

    SELECT
        cedula,
        estado,
        'Estado actualizado exitosamente.' AS mensaje
    FROM dbo.recepcionista
    WHERE cedula = @cedula;
END;
GO


/* ============================================
   7. BUSCAR
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Buscar
    @busqueda VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SET @busqueda = LTRIM(RTRIM(@busqueda));

    SELECT
        cedula,
        nombre,
        apellidos,
        telefono,
        correo,
        estado
    FROM dbo.recepcionista
    WHERE
        cedula LIKE @busqueda + '%'
        OR nombre LIKE @busqueda + '%'
        OR apellidos LIKE @busqueda + '%'
        OR telefono LIKE @busqueda + '%'
        OR correo LIKE @busqueda + '%'
    ORDER BY nombre, apellidos;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/procedures/cliente.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO


/* =========================================================
   1. CREAR CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Cliente_Crear
    @cedula VARCHAR(20),
    @idTipoCliente INT,
    @nombre VARCHAR(45),
    @apellidos VARCHAR(45),
    @telefono VARCHAR(20),
    @direccion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @cedula = LTRIM(RTRIM(@cedula));
        SET @nombre = LTRIM(RTRIM(@nombre));
        SET @apellidos = LTRIM(RTRIM(@apellidos));
        SET @telefono = LTRIM(RTRIM(@telefono));
        SET @direccion = LTRIM(RTRIM(@direccion));

        IF @cedula IS NULL OR @cedula = ''
            THROW 50301, 'La cédula es obligatoria.', 1;

        IF @nombre IS NULL OR @nombre = ''
            THROW 50302, 'El nombre es obligatorio.', 1;

        IF @apellidos IS NULL OR @apellidos = ''
            THROW 50303, 'Los apellidos son obligatorios.', 1;

        IF @telefono IS NULL OR @telefono = ''
            THROW 50304, 'El teléfono es obligatorio.', 1;

        IF @direccion IS NULL OR @direccion = ''
            THROW 50305, 'La dirección es obligatoria.', 1;

        BEGIN TRANSACTION;

        -- Verificar que no exista la cédula
        IF EXISTS (
            SELECT 1
            FROM dbo.cliente WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50306,
                'Ya existe un cliente con esa cédula.',
                1;
        END;

        -- Verificar que exista el tipo de cliente
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50307,
                'El tipo de cliente indicado no existe.',
                1;
        END;

        INSERT INTO dbo.cliente
        (
            cedula,
            idTipoCliente,
            nombre,
            apellidos,
            telefono,
            direccion,
            estado
        )
        VALUES
        (
            @cedula,
            @idTipoCliente,
            @nombre,
            @apellidos,
            @telefono,
            @direccion,
            1
        );

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            'Cliente registrado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   2. ACTUALIZAR CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Cliente_Actualizar
    @cedula VARCHAR(20),
    @idTipoCliente INT,
    @nombre VARCHAR(45),
    @apellidos VARCHAR(45),
    @telefono VARCHAR(20),
    @direccion VARCHAR(100),
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @cedula = LTRIM(RTRIM(@cedula));
        SET @nombre = LTRIM(RTRIM(@nombre));
        SET @apellidos = LTRIM(RTRIM(@apellidos));
        SET @telefono = LTRIM(RTRIM(@telefono));
        SET @direccion = LTRIM(RTRIM(@direccion));

        IF @estado NOT IN (0, 1)
        BEGIN
            THROW 50308,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        -- Comprobar cliente
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.cliente WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50309,
                'El cliente que intenta actualizar no existe.',
                1;
        END;

        -- Comprobar tipo de cliente
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tipocliente
            WHERE idTipoCliente = @idTipoCliente
        )
        BEGIN
            THROW 50310,
                'El tipo de cliente indicado no existe.',
                1;
        END;

        UPDATE dbo.cliente
        SET
            idTipoCliente = @idTipoCliente,
            nombre = @nombre,
            apellidos = @apellidos,
            telefono = @telefono,
            direccion = @direccion,
            estado = @estado
        WHERE cedula = @cedula;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @filasAfectadas AS filasAfectadas,
            'Cliente actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   3. CAMBIAR ESTADO

   @nuevoEstado:
       0 = desactivar
       1 = activar
       NULL = invertir estado actual (toggle)
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Cliente_CambiarEstado
    @cedula VARCHAR(20),
    @nuevoEstado TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @cedula = LTRIM(RTRIM(@cedula));

        IF @nuevoEstado IS NOT NULL
           AND @nuevoEstado NOT IN (0, 1)
        BEGIN
            THROW 50311,
                'El nuevo estado debe ser 0, 1 o NULL.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.cliente WITH (UPDLOCK, HOLDLOCK)
            WHERE cedula = @cedula
        )
        BEGIN
            THROW 50312,
                'El cliente no existe.',
                1;
        END;

        UPDATE dbo.cliente
        SET estado =
            CASE
                WHEN @nuevoEstado IS NULL THEN
                    CASE
                        WHEN estado = 1 THEN 0
                        ELSE 1
                    END
                ELSE @nuevoEstado
            END
        WHERE cedula = @cedula;

        DECLARE @estadoActual TINYINT;

        SELECT @estadoActual = estado
        FROM dbo.cliente
        WHERE cedula = @cedula;

        COMMIT TRANSACTION;

        SELECT
            @cedula AS cedula,
            @estadoActual AS estado,
            'Estado del cliente actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/procedures/tarifa.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO


/* =========================================================
   1. CREAR TARIFA
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_Crear
    @idTipoHabitacion INT,
    @precioBase DECIMAL(10,2),
    @nombreTarifa VARCHAR(45),
    @fechaInicio DATE = NULL,
    @fechaFin DATE = NULL,
    @descripcion NVARCHAR(MAX) = NULL,
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @nombreTarifa = LTRIM(RTRIM(@nombreTarifa));

        IF @nombreTarifa IS NULL OR @nombreTarifa = ''
            THROW 50401, 'El nombre de la tarifa es obligatorio.', 1;

        IF @precioBase IS NULL OR @precioBase < 0
            THROW 50402, 'El precio base no puede ser negativo.', 1;

        IF @estado NOT IN (0, 1)
            THROW 50403, 'El estado debe ser 0 o 1.', 1;

        IF @fechaInicio IS NOT NULL
           AND @fechaFin IS NOT NULL
           AND @fechaFin < @fechaInicio
        BEGIN
            THROW 50404,
                'La fecha final no puede ser anterior a la fecha inicial.',
                1;
        END;

        BEGIN TRANSACTION;

        -- El tipo de habitación debe existir
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipohabitacion
            WHERE idTipoHabitacion = @idTipoHabitacion
        )
        BEGIN
            THROW 50405,
                'El tipo de habitación indicado no existe.',
                1;
        END;

        -- El API busca tarifas por nombre, por eso evitamos
        -- nombres duplicados que producirían ambigüedad.
        IF EXISTS
        (
            SELECT 1
            FROM dbo.tarifa WITH (UPDLOCK, HOLDLOCK)
            WHERE nombreTarifa = @nombreTarifa
        )
        BEGIN
            THROW 50406,
                'Ya existe una tarifa con ese nombre.',
                1;
        END;

        INSERT INTO dbo.tarifa
        (
            idTipoHabitacion,
            precioBase,
            nombreTarifa,
            fechaInicio,
            fechaFin,
            descripcion,
            desactivadaManual,
            estado
        )
        VALUES
        (
            @idTipoHabitacion,
            @precioBase,
            @nombreTarifa,
            @fechaInicio,
            @fechaFin,
            @descripcion,
            0,
            @estado
        );

        DECLARE @nuevoId INT;
        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idTarifa,
            'Tarifa creada correctamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   2. ACTUALIZAR TARIFA

   Los parámetros NULL significan:
   "conservar el valor que ya tiene".
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_Actualizar
    @idTarifa INT,
    @idTipoHabitacion INT = NULL,
    @precioBase DECIMAL(10,2) = NULL,
    @nombreTarifa VARCHAR(45) = NULL,
    @fechaInicio DATE = NULL,
    @fechaFin DATE = NULL,
    @descripcion NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF @idTarifa IS NULL OR @idTarifa <= 0
            THROW 50407, 'El ID de la tarifa no es válido.', 1;

        IF @precioBase IS NOT NULL AND @precioBase < 0
            THROW 50408, 'El precio base no puede ser negativo.', 1;

        IF @nombreTarifa IS NOT NULL
        BEGIN
            SET @nombreTarifa = LTRIM(RTRIM(@nombreTarifa));

            IF @nombreTarifa = ''
                THROW 50409, 'El nombre de la tarifa no puede estar vacío.', 1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tarifa WITH (UPDLOCK, HOLDLOCK)
            WHERE idTarifa = @idTarifa
        )
        BEGIN
            THROW 50410,
                'La tarifa que intenta actualizar no existe.',
                1;
        END;

        IF @idTipoHabitacion IS NOT NULL
           AND NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipohabitacion
            WHERE idTipoHabitacion = @idTipoHabitacion
        )
        BEGIN
            THROW 50411,
                'El tipo de habitación indicado no existe.',
                1;
        END;

        IF @nombreTarifa IS NOT NULL
           AND EXISTS
        (
            SELECT 1
            FROM dbo.tarifa
            WHERE nombreTarifa = @nombreTarifa
              AND idTarifa <> @idTarifa
        )
        BEGIN
            THROW 50412,
                'Ya existe otra tarifa con ese nombre.',
                1;
        END;

        -- Calculamos cómo quedarían finalmente las fechas
        -- antes de ejecutar el UPDATE.
        DECLARE @fechaInicioFinal DATE;
        DECLARE @fechaFinFinal DATE;

        SELECT
            @fechaInicioFinal =
                COALESCE(@fechaInicio, fechaInicio),
            @fechaFinFinal =
                COALESCE(@fechaFin, fechaFin)
        FROM dbo.tarifa
        WHERE idTarifa = @idTarifa;

        IF @fechaInicioFinal IS NOT NULL
           AND @fechaFinFinal IS NOT NULL
           AND @fechaFinFinal < @fechaInicioFinal
        BEGIN
            THROW 50413,
                'La fecha final no puede ser anterior a la fecha inicial.',
                1;
        END;

        UPDATE dbo.tarifa
        SET
            idTipoHabitacion =
                COALESCE(@idTipoHabitacion, idTipoHabitacion),

            precioBase =
                COALESCE(@precioBase, precioBase),

            nombreTarifa =
                COALESCE(@nombreTarifa, nombreTarifa),

            fechaInicio =
                COALESCE(@fechaInicio, fechaInicio),

            fechaFin =
                COALESCE(@fechaFin, fechaFin),

            descripcion =
                @descripcion -- Se permite poner NULL explícitamente

        WHERE idTarifa = @idTarifa;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idTarifa AS idTarifa,
            @filasAfectadas AS filasAfectadas,
            'Tarifa actualizada correctamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   3. ACTIVAR / DESACTIVAR TARIFA

   @activar:
       1 = activar
       0 = desactivar manualmente
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_CambiarEstado
    @idTarifa INT,
    @activar TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF @activar NOT IN (0, 1)
            THROW 50414, 'El parámetro activar debe ser 0 o 1.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tarifa WITH (UPDLOCK, HOLDLOCK)
            WHERE idTarifa = @idTarifa
        )
        BEGIN
            THROW 50415, 'La tarifa indicada no existe.', 1;
        END;

        -- ACTIVAR
        IF @activar = 1
        BEGIN

            -- Se conserva la regla que ya tenía el backend:
            -- solo puede activarse dentro del rango de vigencia.
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.tarifa
                WHERE idTarifa = @idTarifa
                  AND fechaInicio <= CAST(GETDATE() AS DATE)
                  AND fechaFin >= CAST(GETDATE() AS DATE)
            )
            BEGIN
                THROW 50416,
                    'La tarifa solo puede activarse si la fecha actual está dentro del rango de vigencia.',
                    1;
            END;

            UPDATE dbo.tarifa
            SET
                estado = 1,
                desactivadaManual = 0
            WHERE idTarifa = @idTarifa;

        END
        ELSE
        BEGIN

            -- DESACTIVACIÓN MANUAL
            UPDATE dbo.tarifa
            SET
                estado = 0,
                desactivadaManual = 1
            WHERE idTarifa = @idTarifa;

        END;

        DECLARE @estadoActual TINYINT;
        DECLARE @manualActual TINYINT;

        SELECT
            @estadoActual = estado,
            @manualActual = desactivadaManual
        FROM dbo.tarifa
        WHERE idTarifa = @idTarifa;

        COMMIT TRANSACTION;

        SELECT
            @idTarifa AS idTarifa,
            @estadoActual AS estado,
            @manualActual AS desactivadaManual,
            CASE
                WHEN @activar = 1
                    THEN 'Tarifa activada correctamente.'
                ELSE
                    'Tarifa desactivada correctamente.'
            END AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   4. SINCRONIZAR VIGENCIA AUTOMÁTICAMENTE

   Reemplaza:
   - UpdateTarifasVencidasAutomatico
   - ActivarTarifasVigentesAutomatico
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_SincronizarVigencia
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        DECLARE @hoy DATE = CAST(GETDATE() AS DATE);
        DECLARE @vencidas INT;
        DECLARE @activadas INT;

        BEGIN TRANSACTION;

        -- Tarifas cuya vigencia terminó
        UPDATE dbo.tarifa
        SET
            estado = 0,
            desactivadaManual = 0
        WHERE fechaFin IS NOT NULL
          AND fechaFin < @hoy;

        SET @vencidas = @@ROWCOUNT;

        -- Reactivar únicamente las que no fueron
        -- desactivadas manualmente.
        UPDATE dbo.tarifa
        SET estado = 1
        WHERE estado = 0
          AND desactivadaManual = 0
          AND fechaInicio IS NOT NULL
          AND fechaFin IS NOT NULL
          AND fechaInicio <= @hoy
          AND fechaFin >= @hoy;

        SET @activadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @vencidas AS tarifasVencidas,
            @activadas AS tarifasActivadas;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/procedures/habitacion.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO


/* =========================================================
   1. CREAR HABITACIÓN
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Habitacion_Crear
    @idTipoHab INT,
    @numeroHabitacion VARCHAR(45)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @numeroHabitacion = LTRIM(RTRIM(@numeroHabitacion));

        IF @numeroHabitacion IS NULL OR @numeroHabitacion = ''
        BEGIN
            THROW 50501,
                'El número de habitación es obligatorio.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipohabitacion
            WHERE idTipoHabitacion = @idTipoHab
        )
        BEGIN
            THROW 50502,
                'El tipo de habitación indicado no existe.',
                1;
        END;

        -- El backend original ya impedía crear
        -- habitaciones con el mismo número.
        IF EXISTS
        (
            SELECT 1
            FROM dbo.habitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE numeroHabitacion = @numeroHabitacion
        )
        BEGIN
            THROW 50503,
                'Ya existe una habitación con ese número.',
                1;
        END;

        INSERT INTO dbo.habitacion
        (
            idTipoHab,
            numeroHabitacion,
            estado
        )
        VALUES
        (
            @idTipoHab,
            @numeroHabitacion,
            1
        );

        DECLARE @nuevoId INT;

        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idHabitacion,
            'Habitación creada exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   2. ACTUALIZAR HABITACIÓN
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Habitacion_Actualizar
    @idHabitacion INT,
    @idTipoHab INT,
    @numeroHabitacion VARCHAR(45),
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        SET @numeroHabitacion = LTRIM(RTRIM(@numeroHabitacion));

        IF @idHabitacion IS NULL OR @idHabitacion <= 0
        BEGIN
            THROW 50504,
                'El ID de la habitación debe ser mayor que cero.',
                1;
        END;

        IF @numeroHabitacion IS NULL OR @numeroHabitacion = ''
        BEGIN
            THROW 50505,
                'El número de habitación es obligatorio.',
                1;
        END;

        IF @estado NOT IN (0, 1)
        BEGIN
            THROW 50506,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.habitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE idHabitacion = @idHabitacion
        )
        BEGIN
            THROW 50507,
                'La habitación que intenta actualizar no existe.',
                1;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tipohabitacion
            WHERE idTipoHabitacion = @idTipoHab
        )
        BEGIN
            THROW 50508,
                'El tipo de habitación indicado no existe.',
                1;
        END;

        UPDATE dbo.habitacion
        SET
            idTipoHab = @idTipoHab,
            numeroHabitacion = @numeroHabitacion,
            estado = @estado
        WHERE idHabitacion = @idHabitacion;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idHabitacion AS idHabitacion,
            @filasAfectadas AS filasAfectadas,
            'Habitación actualizada exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   3. CAMBIAR ESTADO

   Lo utilizaremos para el DELETE lógico.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Habitacion_CambiarEstado
    @idHabitacion INT,
    @nuevoEstado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF @nuevoEstado NOT IN (0, 1)
        BEGIN
            THROW 50509,
                'El estado debe ser 0 o 1.',
                1;
        END;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.habitacion WITH (UPDLOCK, HOLDLOCK)
            WHERE idHabitacion = @idHabitacion
        )
        BEGIN
            THROW 50510,
                'La habitación no existe.',
                1;
        END;

        UPDATE dbo.habitacion
        SET estado = @nuevoEstado
        WHERE idHabitacion = @idHabitacion;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idHabitacion AS idHabitacion,
            @nuevoEstado AS estado,
            @filasAfectadas AS filasAfectadas,
            CASE
                WHEN @nuevoEstado = 1
                    THEN 'Habitación activada exitosamente.'
                ELSE
                    'Habitación eliminada exitosamente.'
            END AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/procedures/reserva.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO


/* =========================================================
   1. CREAR RESERVA
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Reserva_Crear
    @idRecepcionista VARCHAR(20),
    @idCliente VARCHAR(20),
    @fechaReserva DATETIME,
    @estadoReserva VARCHAR(25),
    @iva DECIMAL(10,2),
    @subTotal DECIMAL(10,2),
    @total DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Mantenemos las mismas relaciones que ya exige la FK.
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.recepcionista
            WHERE cedula = @idRecepcionista
        )
        BEGIN
            THROW 50701,
                'El recepcionista indicado no existe.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.cliente
            WHERE cedula = @idCliente
        )
        BEGIN
            THROW 50702,
                'El cliente indicado no existe.',
                1;
        END;

        INSERT INTO dbo.reserva
        (
            idRecepcionista,
            idCliente,
            fechaReserva,
            estadoReserva,
            iva,
            subTotal,
            total
        )
        VALUES
        (
            @idRecepcionista,
            @idCliente,
            @fechaReserva,
            @estadoReserva,
            @iva,
            @subTotal,
            @total
        );

        DECLARE @nuevoId INT;
        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idReserva,
            'Reserva creada exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   2. ACTUALIZAR RESERVA

   Se mantienen todos los campos del UPDATE original,
   incluidos iva, subtotal y total.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Reserva_Actualizar
    @idReserva INT,
    @idRecepcionista VARCHAR(20),
    @idCliente VARCHAR(20),
    @fechaReserva DATETIME,
    @estadoReserva VARCHAR(25),
    @estado TINYINT,
    @iva DECIMAL(10,2),
    @subTotal DECIMAL(10,2),
    @total DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.reserva WITH (UPDLOCK, HOLDLOCK)
            WHERE idReserva = @idReserva
        )
        BEGIN
            THROW 50703,
                'La reserva indicada no existe.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.recepcionista
            WHERE cedula = @idRecepcionista
        )
        BEGIN
            THROW 50704,
                'El recepcionista indicado no existe.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.cliente
            WHERE cedula = @idCliente
        )
        BEGIN
            THROW 50705,
                'El cliente indicado no existe.',
                1;
        END;

        UPDATE dbo.reserva
        SET
            idRecepcionista = @idRecepcionista,
            idCliente = @idCliente,
            fechaReserva = @fechaReserva,
            estadoReserva = @estadoReserva,
            estado = @estado,
            iva = @iva,
            subTotal = @subTotal,
            total = @total
        WHERE idReserva = @idReserva;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idReserva AS idReserva,
            @filasAfectadas AS filasAfectadas,
            'Reserva actualizada exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   3. TOGGLE DEL ESTADO GENERAL

   Equivale al antiguo:
       SET estado = NOT estado

   Importante:
   NO modifica los detalles de la reserva.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Reserva_ToggleEstado
    @idReserva INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.reserva WITH (UPDLOCK, HOLDLOCK)
            WHERE idReserva = @idReserva
        )
        BEGIN
            THROW 50706,
                'La reserva indicada no existe.',
                1;
        END;

        UPDATE dbo.reserva
        SET estado =
            CASE
                WHEN estado = 0 THEN 1
                ELSE 0
            END
        WHERE idReserva = @idReserva;

        DECLARE @nuevoEstado TINYINT;

        SELECT @nuevoEstado = estado
        FROM dbo.reserva
        WHERE idReserva = @idReserva;

        COMMIT TRANSACTION;

        SELECT
            @idReserva AS idReserva,
            @nuevoEstado AS estado,
            'Estado actualizado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   4. CAMBIAR ESTADO DE LA RESERVA

   Este es estadoReserva:
   Pendiente, Confirmada, Cancelada, etc.

   NO es el campo estado (0/1).
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Reserva_ActualizarEstadoReserva
    @idReserva INT,
    @estadoReserva VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.reserva
    SET estadoReserva = @estadoReserva
    WHERE idReserva = @idReserva;

    DECLARE @filasAfectadas INT = @@ROWCOUNT;

    SELECT
        @idReserva AS idReserva,
        @filasAfectadas AS filasAfectadas,
        'Estado de reserva actualizado.' AS mensaje;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/procedures/detalleReserva.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO


/* =========================================================
   1. CREAR DETALLE DE RESERVA

   Los cálculos de:
   - precio aplicado
   - subtotal
   - IVA
   - total

   siguen realizándose en Go, igual que en el backend original.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_DetalleReserva_Crear
    @idHabitacion INT,
    @idReserva INT,
    @idTarifa INT,
    @cantidadPersonas INT,
    @precioAplicado DECIMAL(10,2),
    @fechaEntrada DATETIME,
    @fechaSalida DATETIME,
    @iva DECIMAL(10,2),
    @subTotal DECIMAL(10,2),
    @total DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.habitacion
            WHERE idHabitacion = @idHabitacion
        )
        BEGIN
            THROW 50801,
                'La habitación indicada no existe.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.reserva
            WHERE idReserva = @idReserva
        )
        BEGIN
            THROW 50802,
                'La reserva indicada no existe.',
                1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tarifa
            WHERE idTarifa = @idTarifa
        )
        BEGIN
            THROW 50803,
                'La tarifa indicada no existe.',
                1;
        END;

        INSERT INTO dbo.detallereserva
        (
            idHabitacion,
            idReserva,
            idTarifa,
            cantidadPersonas,
            precioAplicado,
            fechaEntrada,
            fechaSalida,
            iva,
            subTotal,
            total
        )
        VALUES
        (
            @idHabitacion,
            @idReserva,
            @idTarifa,
            @cantidadPersonas,
            @precioAplicado,
            @fechaEntrada,
            @fechaSalida,
            @iva,
            @subTotal,
            @total
        );

        DECLARE @nuevoId INT;
        SET @nuevoId = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT
            @nuevoId AS idDetalleReserva,
            'Detalle de reserva creado exitosamente.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   2. ACTUALIZAR DETALLE

   fechaEntrada y fechaSalida son opcionales.

   Si las fechas llegan en NULL, se conservan los valores existentes.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_DetalleReserva_Actualizar
    @idDetalleReserva INT,
    @idHabitacion INT,
    @idTarifa INT,
    @cantidadPersonas INT,
    @precioAplicado DECIMAL(10,2),
    @fechaEntrada DATETIME = NULL,
    @fechaSalida DATETIME = NULL,
    @iva DECIMAL(10,2),
    @subTotal DECIMAL(10,2),
    @total DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.detallereserva
        SET
            idHabitacion = @idHabitacion,
            idTarifa = @idTarifa,
            cantidadPersonas = @cantidadPersonas,
            precioAplicado = @precioAplicado,

            fechaEntrada =
                COALESCE(@fechaEntrada, fechaEntrada),

            fechaSalida =
                COALESCE(@fechaSalida, fechaSalida),

            iva = @iva,
            subTotal = @subTotal,
            total = @total

        WHERE idDetalleReserva = @idDetalleReserva;

        DECLARE @filasAfectadas INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @idDetalleReserva AS idDetalleReserva,
            @filasAfectadas AS filasAfectadas,
            'Detalle de reserva actualizado.' AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* =========================================================
   3. ACTIVAR / DESACTIVAR DETALLE

   Igual al backend anterior:
       1 -> 0
       0 -> 1

   Al cambiar estado se ejecutará también:
       trg_actualizar_totales_reserva

   Y al reactivar se aplican los triggers de
   traslape y capacidad.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_DetalleReserva_ToggleEstado
    @idDetalleReserva INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.detallereserva WITH (UPDLOCK, HOLDLOCK)
            WHERE idDetalleReserva = @idDetalleReserva
        )
        BEGIN
            THROW 50804,
                'El detalle de reserva indicado no existe.',
                1;
        END;

        UPDATE dbo.detallereserva
        SET estado =
            CASE
                WHEN estado = 1 THEN 0
                ELSE 1
            END
        WHERE idDetalleReserva = @idDetalleReserva;

        DECLARE @nuevoEstado TINYINT;

        SELECT @nuevoEstado = estado
        FROM dbo.detallereserva
        WHERE idDetalleReserva = @idDetalleReserva;

        COMMIT TRANSACTION;

        SELECT
            @idDetalleReserva AS idDetalleReserva,
            @nuevoEstado AS estado,
            1 AS filasAfectadas;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


/* ============================================================================
   7. FUNCIONES - DEFINICIONES REALES DEL BACKEND
   ============================================================================ */

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/function/cliente.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

/* =========================================================
   FUNCIÓN: fn_HistorialReservasCliente

   Descripción:
   Devuelve el historial de reservas de un cliente junto con
   la habitación, tipo de habitación, tarifa, fechas y montos.

   Incluye el estado de la reserva y del detalle para que
   también puedan consultarse registros históricos que hayan
   sido cancelados o desactivados.

   Importancia:
   Centraliza la consulta del historial de un cliente y evita
   repetir los JOIN necesarios en reportes y consultas.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_HistorialReservasCliente
(
    @cedulaCliente VARCHAR(20)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        r.idReserva,
        r.fechaReserva,
        r.estadoReserva,
        r.estado AS estadoReservaRegistro,

        h.idHabitacion,
        h.numeroHabitacion,
        th.nombreTipoHab,

        t.idTarifa,
        t.nombreTarifa,

        dr.idDetalleReserva,
        dr.fechaEntrada,
        dr.fechaSalida,
        dr.precioAplicado,
        dr.subTotal,
        dr.iva,
        dr.total,
        dr.estado AS estadoDetalle

    FROM dbo.reserva AS r

    INNER JOIN dbo.detallereserva AS dr
        ON dr.idReserva = r.idReserva

    INNER JOIN dbo.habitacion AS h
        ON h.idHabitacion = dr.idHabitacion

    INNER JOIN dbo.tipohabitacion AS th
        ON th.idTipoHabitacion = h.idTipoHab

    INNER JOIN dbo.tarifa AS t
        ON t.idTarifa = dr.idTarifa

    WHERE r.idCliente = @cedulaCliente
);
GO

-- Ejemplo:
-- SELECT *
-- FROM dbo.fn_HistorialReservasCliente('10101010')
-- ORDER BY fechaReserva DESC;


/* =========================================================
   FUNCIÓN: fn_TotalReservasHuesped

   Descripción:
   Devuelve la cantidad de reservas activas y no canceladas
   asociadas a un cliente.

   Importancia:
   Puede utilizarse para identificar clientes frecuentes,
   generar estadísticas y apoyar futuras reglas comerciales.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_TotalReservasHuesped
(
    @cedula VARCHAR(20)
)
RETURNS INT
AS
BEGIN
    DECLARE @total INT;

    SELECT @total = COUNT(*)
    FROM dbo.reserva
    WHERE idCliente = @cedula
      AND estado = 1
      AND estadoReserva <> 'Cancelada';

    RETURN ISNULL(@total, 0);
END;
GO

-- Ejemplo:
-- SELECT
--     cedula,
--     dbo.fn_TotalReservasHuesped(cedula) AS totalReservas
-- FROM dbo.cliente;

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/function/habitacion.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

/* =========================================================
   FUNCIÓN: fn_HabitacionesDisponibles

   Descripción:
   Devuelve las habitaciones activas que se encuentran
   disponibles dentro de un rango de fechas determinado.

   Una habitación se considera disponible cuando no existe
   ningún detalle de reserva activo cuyo rango de fechas se
   cruce con las fechas solicitadas.

   También devuelve el tipo de habitación y su capacidad
   máxima para facilitar su selección desde la aplicación.

   Importancia:
   Centraliza la validación de disponibilidad y evita repetir
   la lógica de traslape en distintas consultas del sistema.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_HabitacionesDisponibles
(
    @fechaEntrada DATETIME,
    @fechaSalida  DATETIME
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        h.idHabitacion,
        h.idTipoHab,
        h.numeroHabitacion,
        th.nombreTipoHab,
        th.capacidadMaxima
    FROM dbo.habitacion AS h

    INNER JOIN dbo.tipohabitacion AS th
        ON th.idTipoHabitacion = h.idTipoHab

    WHERE h.estado = 1
      AND th.estado = 1

      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.detallereserva AS dr

          WHERE dr.idHabitacion = h.idHabitacion
            AND dr.estado = 1

            -- Existe traslape cuando:
            AND dr.fechaEntrada < @fechaSalida
            AND dr.fechaSalida  > @fechaEntrada
      )
);
GO

-- Ejemplo:
-- SELECT *
-- FROM dbo.fn_HabitacionesDisponibles(
--     '2026-10-10 14:00:00',
--     '2026-10-13 12:00:00'
-- );

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/function/tarifa.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

/* =========================================================
   FUNCIÓN: fn_TarifasVigentes

   Descripción:
   Devuelve las tarifas disponibles para una fecha específica,
   considerando su estado, desactivación manual, período de
   vigencia y estado del tipo de habitación.

   Importancia:
   Centraliza la lógica utilizada para determinar qué tarifa
   puede aplicarse según la fecha de una estadía.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_TarifasVigentes
(
    @fecha DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        t.idTarifa,
        t.nombreTarifa,
        t.idTipoHabitacion,
        th.nombreTipoHab,
        t.precioBase,
        t.fechaInicio,
        t.fechaFin

    FROM dbo.tarifa AS t

    INNER JOIN dbo.tipohabitacion AS th
        ON th.idTipoHabitacion = t.idTipoHabitacion

    WHERE @fecha IS NOT NULL
      AND t.estado = 1
      AND t.desactivadaManual = 0
      AND th.estado = 1

      AND (
            t.fechaInicio IS NULL
            OR t.fechaInicio <= @fecha
          )

      AND (
            t.fechaFin IS NULL
            OR t.fechaFin >= @fecha
          )
);
GO

-- Ejemplo:
-- SELECT *
-- FROM dbo.fn_TarifasVigentes('2026-12-24');

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/function/detalleReserva.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

/* =========================================================
   FUNCIÓN: fn_NochesEstancia

   Descripción:
   Calcula la cantidad de noches comprendidas entre una fecha
   de entrada y una fecha de salida.

   Ejemplo:
   09/10/2026 -> 12/10/2026 = 3 noches.

   Importancia:
   Permite reutilizar el cálculo de noches en consultas,
   reportes y cálculos relacionados con una estadía.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_NochesEstancia
(
    @fechaEntrada DATE,
    @fechaSalida DATE
)
RETURNS INT
AS
BEGIN
    IF @fechaEntrada IS NULL
       OR @fechaSalida IS NULL
       OR @fechaSalida <= @fechaEntrada
    BEGIN
        RETURN 0;
    END;

    RETURN DATEDIFF(
        DAY,
        @fechaEntrada,
        @fechaSalida
    );
END;
GO

-- Ejemplo:
-- SELECT
--     idDetalleReserva,
--     dbo.fn_NochesEstancia(fechaEntrada, fechaSalida) AS noches
-- FROM dbo.detallereserva;


/* ============================================================================
   8. TRIGGERS DE REGLAS DE NEGOCIO BASE
   Fuente exacta: db/reservasdbV2.sql
   ============================================================================ */
USE reservasdbV2;
GO

/* Trigger base: trg_evitar_reserva_habitacion_ocupada */
CREATE TRIGGER trg_evitar_reserva_habitacion_ocupada
ON detallereserva
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN detallereserva d
            ON d.idHabitacion = i.idHabitacion
            AND d.idDetalleReserva <> i.idDetalleReserva
            AND d.estado = 1
            AND i.estado = 1

            -- Cruce de fechas
            AND i.fechaEntrada < d.fechaSalida
            AND i.fechaSalida > d.fechaEntrada
    )
    BEGIN
        RAISERROR(
            'La habitación ya se encuentra reservada en esas fechas.',
            16,
            1
        );

        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* Trigger base: trg_validar_capacidad_habitacion */
CREATE TRIGGER trg_validar_capacidad_habitacion
ON detallereserva
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i

        INNER JOIN habitacion h
            ON h.idHabitacion = i.idHabitacion

        INNER JOIN tipohabitacion th
            ON th.idTipoHabitacion = h.idTipoHab

        WHERE
            i.cantidadPersonas > th.capacidadMaxima
            OR i.cantidadPersonas <= 0
    )
    BEGIN
        RAISERROR(
            'La cantidad de personas no es válida o supera la capacidad máxima de la habitación.',
            16,
            1
        );

        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* Trigger base: trg_actualizar_totales_reserva */
CREATE TRIGGER trg_actualizar_totales_reserva
ON detallereserva
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualizar únicamente las reservas afectadas
    UPDATE r
    SET
        r.subTotal = ISNULL(t.subTotal, 0),
        r.iva = ISNULL(t.iva, 0),
        r.total = ISNULL(t.total, 0)
    FROM reserva r

    INNER JOIN
    (
        SELECT
            ids.idReserva,

            SUM(
                CASE
                    WHEN d.estado = 1
                    THEN d.subTotal
                    ELSE 0
                END
            ) AS subTotal,

            SUM(
                CASE
                    WHEN d.estado = 1
                    THEN d.iva
                    ELSE 0
                END
            ) AS iva,

            SUM(
                CASE
                    WHEN d.estado = 1
                    THEN d.total
                    ELSE 0
                END
            ) AS total

        FROM
        (
            SELECT idReserva
            FROM inserted

            UNION

            SELECT idReserva
            FROM deleted
        ) ids

        LEFT JOIN detallereserva d
            ON d.idReserva = ids.idReserva

        GROUP BY ids.idReserva

    ) t
        ON r.idReserva = t.idReserva;
END;
GO


/* ============================================================================
   9. TRIGGERS MODULARES Y AUDITORÍA - DEFINICIONES REALES DEL BACKEND
   ============================================================================ */

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/triggers/tipoCliente.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_TipoCliente_EvitarDeleteFisico
ON dbo.tipocliente
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50120,
        'No se permite eliminar físicamente un tipo de cliente. Utilice eliminación lógica.',
        1;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/triggers/cliente.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_Cliente_EvitarDeleteFisico
ON dbo.cliente
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50320,
        'No se permite eliminar físicamente un cliente. Utilice eliminación lógica.',
        1;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/triggers/recepcionista.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_Recepcionista_EvitarDeleteFisico
ON dbo.recepcionista
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50220,
        'No se permite eliminar físicamente un recepcionista. Utilice eliminación lógica.',
        1;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/triggers/habitacion.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_Habitacion_EvitarDeleteFisico
ON dbo.habitacion
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50520,
        'No se permite eliminar físicamente una habitación. Utilice eliminación lógica.',
        1;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/triggers/tarifa.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_Tarifa_EvitarDeleteFisico
ON dbo.tarifa
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50420,
        'No se permite eliminar físicamente una tarifa. Utilice la desactivación.',
        1;
END;
GO

/* ----------------------------------------------------------------------------
   FUENTE EXACTA: db/triggers/tipoHabitacion.sql
   ---------------------------------------------------------------------------- */
USE reservasdbV2;
GO

/* =========================================================
   TABLA DE AUDITORÍA PARA TIPO HABITACIÓN
   ========================================================= */

IF OBJECT_ID('dbo.auditoriaTipoHabitacion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.auditoriaTipoHabitacion
    (
        idAuditoria INT IDENTITY(1,1) PRIMARY KEY,
        idTipoHabitacion INT NOT NULL,
        accion VARCHAR(20) NOT NULL,
        nombreAnterior VARCHAR(45) NULL,
        nombreNuevo VARCHAR(45) NULL,
        descripcionAnterior VARCHAR(100) NULL,
        descripcionNueva VARCHAR(100) NULL,
        capacidadAnterior INT NULL,
        capacidadNueva INT NULL,
        estadoAnterior TINYINT NULL,
        estadoNuevo TINYINT NULL,
        fechaCambio DATETIME NOT NULL DEFAULT GETDATE()
    );
END;
GO


/* =========================================================
   TRIGGER 1
   AUDITORÍA DE INSERT Y UPDATE
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_TipoHabitacion_Auditoria
ON dbo.tipohabitacion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* INSERT */
    INSERT INTO dbo.auditoriaTipoHabitacion
    (
        idTipoHabitacion,
        accion,
        nombreAnterior,
        nombreNuevo,
        descripcionAnterior,
        descripcionNueva,
        capacidadAnterior,
        capacidadNueva,
        estadoAnterior,
        estadoNuevo
    )
    SELECT
        i.idTipoHabitacion,
        'INSERT',
        NULL,
        i.nombreTipoHab,
        NULL,
        i.descripcion,
        NULL,
        i.capacidadMaxima,
        NULL,
        i.estado
    FROM inserted i
    LEFT JOIN deleted d
        ON i.idTipoHabitacion = d.idTipoHabitacion
    WHERE d.idTipoHabitacion IS NULL;


    /* UPDATE */
    INSERT INTO dbo.auditoriaTipoHabitacion
    (
        idTipoHabitacion,
        accion,
        nombreAnterior,
        nombreNuevo,
        descripcionAnterior,
        descripcionNueva,
        capacidadAnterior,
        capacidadNueva,
        estadoAnterior,
        estadoNuevo
    )
    SELECT
        i.idTipoHabitacion,
        'UPDATE',
        d.nombreTipoHab,
        i.nombreTipoHab,
        d.descripcion,
        i.descripcion,
        d.capacidadMaxima,
        i.capacidadMaxima,
        d.estado,
        i.estado
    FROM inserted i
    INNER JOIN deleted d
        ON i.idTipoHabitacion = d.idTipoHabitacion;
END;
GO


/* =========================================================
   TRIGGER 2
   EVITAR ELIMINACIÓN FÍSICA
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_TipoHabitacion_EvitarDeleteFisico
ON dbo.tipohabitacion
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    THROW 50020,
        'No se permite eliminar físicamente un tipo de habitación. Utilice eliminación lógica.',
        1;
END;
GO

/* ============================================================================
   10. ÍNDICES Y OPTIMIZACIÓN
   ----------------------------------------------------------------------------
   Las PK y UNIQUE ya crean índices. Aquí se agregan índices NO agrupados sobre:
   - Llaves foráneas (acelera JOINs y las validaciones de integridad).
   - Columnas de búsqueda, filtros por fecha y detección de cruces de fechas.
   - Columnas INCLUDE para que las consultas frecuentes (vistas, funciones y
     triggers) se resuelvan solo con el índice, sin ir a la tabla (covering).
   ============================================================================ */
USE reservasdbV2;
GO

/* cliente: se consulta por tipo de cliente (vista vw_Cliente_Detalle) */
CREATE NONCLUSTERED INDEX ix_cliente_tipocliente
    ON dbo.cliente (idTipoCliente)
    INCLUDE (nombre, apellidos, estado);
GO

/* habitacion: se filtra por tipo y estado (fn_HabitacionesDisponibles).
   El número de habitación no debe repetirse (integridad + búsqueda rápida). */
CREATE NONCLUSTERED INDEX ix_habitacion_tipo
    ON dbo.habitacion (idTipoHab)
    INCLUDE (numeroHabitacion, estado);
GO
CREATE UNIQUE NONCLUSTERED INDEX ux_habitacion_numero
    ON dbo.habitacion (numeroHabitacion);
GO

/* reserva: historial por cliente (fn_HistorialReservasCliente,
   fn_TotalReservasHuesped), por recepcionista y por fecha. */
CREATE NONCLUSTERED INDEX ix_reserva_cliente_fecha
    ON dbo.reserva (idCliente, fechaReserva DESC)
    INCLUDE (estadoReserva, total, estado);
GO
CREATE NONCLUSTERED INDEX ix_reserva_recepcionista
    ON dbo.reserva (idRecepcionista)
    INCLUDE (fechaReserva, estadoReserva);
GO
CREATE NONCLUSTERED INDEX ix_reserva_fecha
    ON dbo.reserva (fechaReserva)
    INCLUDE (estadoReserva, total);
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
CREATE NONCLUSTERED INDEX ix_detalle_habitacion_fechas
    ON dbo.detallereserva (idHabitacion, fechaEntrada, fechaSalida)
    INCLUDE (estado);
GO
CREATE NONCLUSTERED INDEX ix_detalle_tarifa
    ON dbo.detallereserva (idTarifa);
GO

/* tarifa: búsqueda de la tarifa vigente por tipo y rango de fechas
   (fn_TarifasVigentes, pa_Tarifa_SincronizarVigencia). */
CREATE NONCLUSTERED INDEX ix_tarifa_tipo_vigencia
    ON dbo.tarifa (idTipoHabitacion, fechaInicio, fechaFin)
    INCLUDE (precioBase, estado, desactivadaManual);
GO

/* ============================================================================
   11. AUDITORÍA
   ----------------------------------------------------------------------------
   Se audita solo lo crítico (no todo):
   1) auditoriaTipoHabitacion (ya existía): cambios del catálogo de habitaciones.
   2) auditoriaSesion    : quién entró o salió del sistema y cuándo.
   3) auditoriaReserva   : creación, cambio de estado, cambio de monto y
                           eliminación de reservas (operación principal y
                           con dinero).
   4) auditoriaTarifa    : cambios de precios y vigencias (afecta ingresos).
   5) auditoriaRespaldo  : respaldos y restauraciones de la base de datos.
   Cada registro guarda el login real del motor (ORIGINAL_LOGIN) y la fecha.
   ============================================================================ */
USE reservasdbV2;
GO

/* ---------- 11.1 Auditoría de sesiones ---------- */
CREATE TABLE dbo.auditoriaSesion
(
    idAuditoriaSesion INT IDENTITY(1,1) NOT NULL,
    loginBD           SYSNAME      NOT NULL
        CONSTRAINT df_audses_login DEFAULT (ORIGINAL_LOGIN()),
    rolBD             VARCHAR(30)  NULL,
    accion            VARCHAR(20)  NOT NULL,
    usuarioApp        VARCHAR(150) NULL,
    ipOrigen          VARCHAR(45)  NULL,
    detalle           VARCHAR(200) NULL,
    fechaHora         DATETIME     NOT NULL
        CONSTRAINT df_audses_fecha DEFAULT (GETDATE()),

    CONSTRAINT pk_auditoriaSesion PRIMARY KEY (idAuditoriaSesion),
    CONSTRAINT chk_audses_accion CHECK (accion IN ('LOGIN','LOGOUT','LOGIN_FALLIDO'))
);
GO
CREATE NONCLUSTERED INDEX ix_audses_fecha ON dbo.auditoriaSesion (fechaHora DESC);
GO

/* ---------- 11.2 Auditoría de reservas ---------- */
CREATE TABLE dbo.auditoriaReserva
(
    idAuditoria              INT IDENTITY(1,1) NOT NULL,
    idReserva                INT          NOT NULL,
    accion                   VARCHAR(10)  NOT NULL,
    idClienteAnterior        VARCHAR(20)  NULL,
    idClienteNuevo           VARCHAR(20)  NULL,
    idRecepcionistaAnterior  VARCHAR(20)  NULL,
    idRecepcionistaNuevo     VARCHAR(20)  NULL,
    estadoReservaAnterior    VARCHAR(25)  NULL,
    estadoReservaNuevo       VARCHAR(25)  NULL,
    estadoAnterior           TINYINT      NULL,
    estadoNuevo              TINYINT      NULL,
    totalAnterior            DECIMAL(10,2) NULL,
    totalNuevo               DECIMAL(10,2) NULL,
    usuarioBD                SYSNAME      NOT NULL
        CONSTRAINT df_audres_usuario DEFAULT (ORIGINAL_LOGIN()),
    fechaCambio              DATETIME     NOT NULL
        CONSTRAINT df_audres_fecha DEFAULT (GETDATE()),

    CONSTRAINT pk_auditoriaReserva PRIMARY KEY (idAuditoria),
    CONSTRAINT chk_audres_accion CHECK (accion IN ('INSERT','UPDATE','DELETE'))
);
GO
CREATE NONCLUSTERED INDEX ix_audres_reserva ON dbo.auditoriaReserva (idReserva, fechaCambio DESC);
GO

/* ---------- 11.3 Auditoría de tarifas ---------- */
CREATE TABLE dbo.auditoriaTarifa
(
    idAuditoria            INT IDENTITY(1,1) NOT NULL,
    idTarifa               INT          NOT NULL,
    accion                 VARCHAR(10)  NOT NULL,
    precioBaseAnterior     DECIMAL(10,2) NULL,
    precioBaseNuevo        DECIMAL(10,2) NULL,
    fechaInicioAnterior    DATE         NULL,
    fechaInicioNueva       DATE         NULL,
    fechaFinAnterior       DATE         NULL,
    fechaFinNueva          DATE         NULL,
    estadoAnterior         TINYINT      NULL,
    estadoNuevo            TINYINT      NULL,
    usuarioBD              SYSNAME      NOT NULL
        CONSTRAINT df_audtar_usuario DEFAULT (ORIGINAL_LOGIN()),
    fechaCambio            DATETIME     NOT NULL
        CONSTRAINT df_audtar_fecha DEFAULT (GETDATE()),

    CONSTRAINT pk_auditoriaTarifa PRIMARY KEY (idAuditoria),
    CONSTRAINT chk_audtar_accion CHECK (accion IN ('INSERT','UPDATE'))
);
GO
CREATE NONCLUSTERED INDEX ix_audtar_tarifa ON dbo.auditoriaTarifa (idTarifa, fechaCambio DESC);
GO

/* ---------- 11.4 Auditoría de respaldos y restauraciones ---------- */
CREATE TABLE dbo.auditoriaRespaldo
(
    idAuditoria    INT IDENTITY(1,1) NOT NULL,
    tipoOperacion  VARCHAR(10)   NOT NULL,
    archivo        NVARCHAR(400) NULL,
    resultado      VARCHAR(10)   NOT NULL,
    mensaje        NVARCHAR(500) NULL,
    usuarioBD      SYSNAME       NOT NULL
        CONSTRAINT df_audresp_usuario DEFAULT (ORIGINAL_LOGIN()),
    fechaHora      DATETIME      NOT NULL
        CONSTRAINT df_audresp_fecha DEFAULT (GETDATE()),

    CONSTRAINT pk_auditoriaRespaldo PRIMARY KEY (idAuditoria),
    CONSTRAINT chk_audresp_tipo CHECK (tipoOperacion IN ('BACKUP','RESTORE')),
    CONSTRAINT chk_audresp_resultado CHECK (resultado IN ('OK','ERROR'))
);
GO
CREATE NONCLUSTERED INDEX ix_audresp_fecha ON dbo.auditoriaRespaldo (fechaHora DESC);
GO

/* ---------- 11.5 Trigger: auditoría de reservas ----------
   Registra INSERT, DELETE y UPDATE. En UPDATE solo se registra cuando cambia
   algún campo relevante (cliente, recepcionista, estado, estado lógico o
   total). Así el recálculo automático de totales no llena la tabla de ruido
   cuando el monto no cambió. */
CREATE OR ALTER TRIGGER dbo.trg_Reserva_Auditoria
ON dbo.reserva
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    /* INSERT: existe en inserted y no en deleted */
    INSERT INTO dbo.auditoriaReserva
        (idReserva, accion, idClienteNuevo, idRecepcionistaNuevo,
         estadoReservaNuevo, estadoNuevo, totalNuevo)
    SELECT i.idReserva, 'INSERT', i.idCliente, i.idRecepcionista,
           i.estadoReserva, i.estado, i.total
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.idReserva = i.idReserva
    WHERE d.idReserva IS NULL;

    /* UPDATE: existe en ambos y cambió algo relevante */
    INSERT INTO dbo.auditoriaReserva
        (idReserva, accion,
         idClienteAnterior, idClienteNuevo,
         idRecepcionistaAnterior, idRecepcionistaNuevo,
         estadoReservaAnterior, estadoReservaNuevo,
         estadoAnterior, estadoNuevo,
         totalAnterior, totalNuevo)
    SELECT i.idReserva, 'UPDATE',
           d.idCliente, i.idCliente,
           d.idRecepcionista, i.idRecepcionista,
           d.estadoReserva, i.estadoReserva,
           d.estado, i.estado,
           d.total, i.total
    FROM inserted AS i
    INNER JOIN deleted AS d ON d.idReserva = i.idReserva
    WHERE i.idCliente       <> d.idCliente
       OR i.idRecepcionista <> d.idRecepcionista
       OR i.estadoReserva   <> d.estadoReserva
       OR i.estado          <> d.estado
       OR i.total           <> d.total;

    /* DELETE: existe en deleted y no en inserted */
    INSERT INTO dbo.auditoriaReserva
        (idReserva, accion, idClienteAnterior, idRecepcionistaAnterior,
         estadoReservaAnterior, estadoAnterior, totalAnterior)
    SELECT d.idReserva, 'DELETE', d.idCliente, d.idRecepcionista,
           d.estadoReserva, d.estado, d.total
    FROM deleted AS d
    LEFT JOIN inserted AS i ON i.idReserva = d.idReserva
    WHERE i.idReserva IS NULL;
END;
GO

/* ---------- 11.6 Trigger: auditoría de tarifas ---------- */
CREATE OR ALTER TRIGGER dbo.trg_Tarifa_Auditoria
ON dbo.tarifa
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* INSERT */
    INSERT INTO dbo.auditoriaTarifa
        (idTarifa, accion, precioBaseNuevo, fechaInicioNueva, fechaFinNueva, estadoNuevo)
    SELECT i.idTarifa, 'INSERT', i.precioBase, i.fechaInicio, i.fechaFin, i.estado
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.idTarifa = i.idTarifa
    WHERE d.idTarifa IS NULL;

    /* UPDATE: solo si cambió precio, fechas o estado */
    INSERT INTO dbo.auditoriaTarifa
        (idTarifa, accion,
         precioBaseAnterior, precioBaseNuevo,
         fechaInicioAnterior, fechaInicioNueva,
         fechaFinAnterior, fechaFinNueva,
         estadoAnterior, estadoNuevo)
    SELECT i.idTarifa, 'UPDATE',
           d.precioBase, i.precioBase,
           d.fechaInicio, i.fechaInicio,
           d.fechaFin, i.fechaFin,
           d.estado, i.estado
    FROM inserted AS i
    INNER JOIN deleted AS d ON d.idTarifa = i.idTarifa
    WHERE i.precioBase <> d.precioBase
       OR ISNULL(i.fechaInicio, '19000101') <> ISNULL(d.fechaInicio, '19000101')
       OR ISNULL(i.fechaFin,    '19000101') <> ISNULL(d.fechaFin,    '19000101')
       OR i.estado <> d.estado;
END;
GO

/* ---------- 11.7 Procedimiento: registrar inicio/cierre de sesión ----------
   La aplicación lo llama después de conectarse con el login del motor
   (LOGIN) y al cerrar sesión (LOGOUT). El rol se detecta automáticamente. */
CREATE OR ALTER PROCEDURE dbo.pa_Auditoria_RegistrarSesion
    @accion     VARCHAR(20),
    @usuarioApp VARCHAR(150) = NULL,
    @ipOrigen   VARCHAR(45)  = NULL,
    @detalle    VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @accion NOT IN ('LOGIN','LOGOUT','LOGIN_FALLIDO')
        THROW 51101, 'Acción de sesión no válida. Use LOGIN, LOGOUT o LOGIN_FALLIDO.', 1;

    INSERT INTO dbo.auditoriaSesion (rolBD, accion, usuarioApp, ipOrigen, detalle)
    VALUES
    (
        CASE
            WHEN IS_MEMBER('rol_admin_hotel') = 1 THEN 'ADMIN'
            WHEN IS_MEMBER('rol_recepcion')   = 1 THEN 'RECEPCION'
            ELSE 'OTRO'
        END,
        @accion, @usuarioApp, @ipOrigen, @detalle
    );

    SELECT SCOPE_IDENTITY() AS idAuditoriaSesion, 'Sesión registrada.' AS mensaje;
END;
GO

/* ---------- 11.8 Vista de consulta de auditoría (solo administrador) ---------- */
CREATE OR ALTER VIEW dbo.vw_Auditoria_Reciente
AS
    SELECT 'SESION' AS origen, fechaHora AS fecha, loginBD AS usuario,
           accion AS accion, CONCAT('Rol: ', rolBD, ' | IP: ', ipOrigen) AS detalle
    FROM dbo.auditoriaSesion
    UNION ALL
    SELECT 'RESERVA', fechaCambio, usuarioBD, accion,
           CONCAT('Reserva ', idReserva, ' | ', estadoReservaAnterior, ' -> ', estadoReservaNuevo,
                  ' | total ', totalAnterior, ' -> ', totalNuevo)
    FROM dbo.auditoriaReserva
    UNION ALL
    SELECT 'TARIFA', fechaCambio, usuarioBD, accion,
           CONCAT('Tarifa ', idTarifa, ' | precio ', precioBaseAnterior, ' -> ', precioBaseNuevo)
    FROM dbo.auditoriaTarifa
    UNION ALL
    SELECT 'RESPALDO', fechaHora, usuarioBD, tipoOperacion,
           CONCAT(resultado, ' | ', archivo)
    FROM dbo.auditoriaRespaldo;
GO

/* ============================================================================
   12. RESPALDO Y RESTAURACIÓN DESDE EL SISTEMA
   ----------------------------------------------------------------------------
   La aplicación solo llama procedimientos almacenados:
   - dbo.pa_Respaldo_Crear     : BACKUP DATABASE completo (.bak).
   - dbo.pa_Respaldo_Listar    : lista los respaldos hechos con éxito.
   - master.dbo.pa_Restaurar_reservasdbV2 : RESTORE DATABASE de un respaldo.
   La restauración vive en master porque una base de datos no puede
   restaurarse a sí misma mientras está en uso.
   Requisitos: la carpeta de respaldo debe existir y la cuenta de servicio de
   SQL Server debe poder escribir en ella.
   ============================================================================ */
USE reservasdbV2;
GO

/* ---------- 12.1 Crear respaldo completo ---------- */
CREATE OR ALTER PROCEDURE dbo.pa_Respaldo_Crear
    @rutaCarpeta NVARCHAR(260) = NULL   -- NULL = carpeta de respaldos por defecto
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ruta NVARCHAR(260) =
        COALESCE(NULLIF(LTRIM(RTRIM(@rutaCarpeta)), N''),
                 CONVERT(NVARCHAR(260), SERVERPROPERTY('InstanceDefaultBackupPath')),
                 N'C:\SQLBackups\');

    IF RIGHT(@ruta, 1) NOT IN (N'\', N'/')
        SET @ruta = @ruta + CASE WHEN CHARINDEX(N'/', @ruta) > 0 THEN N'/' ELSE N'\' END;

    DECLARE @archivo NVARCHAR(400) =
        @ruta + N'reservasdbV2_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + N'.bak';

    DECLARE @sql NVARCHAR(MAX) =
        N'BACKUP DATABASE reservasdbV2 TO DISK = N''' + REPLACE(@archivo, N'''', N'''''') +
        N''' WITH INIT, CHECKSUM, STATS = 10, NAME = N''Respaldo completo reservasdbV2'';';

    BEGIN TRY
        EXEC sys.sp_executesql @sql;

        INSERT INTO dbo.auditoriaRespaldo (tipoOperacion, archivo, resultado, mensaje)
        VALUES ('BACKUP', @archivo, 'OK', N'Respaldo completo generado.');

        SELECT @archivo AS archivo, N'Respaldo completo generado correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.auditoriaRespaldo (tipoOperacion, archivo, resultado, mensaje)
        VALUES ('BACKUP', @archivo, 'ERROR', LEFT(ERROR_MESSAGE(), 500));

        THROW;
    END CATCH;
END;
GO

/* ---------- 12.2 Listar respaldos disponibles para restaurar ---------- */
CREATE OR ALTER PROCEDURE dbo.pa_Respaldo_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (50)
           idAuditoria, archivo, usuarioBD, fechaHora
    FROM dbo.auditoriaRespaldo
    WHERE tipoOperacion = 'BACKUP' AND resultado = 'OK'
    ORDER BY fechaHora DESC;
END;
GO

/* ---------- 12.3 Restaurar respaldo (se crea en master) ---------- */
USE master;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Restaurar_reservasdbV2
    @archivo NVARCHAR(400)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    IF DB_ID(N'reservasdbV2') IS NULL
        THROW 51201, 'La base de datos reservasdbV2 no existe en esta instancia.', 1;

    /* Seguridad: solo se restauran archivos que el propio sistema respaldó. */
    DECLARE @valido BIT = 0;
    EXEC sys.sp_executesql
        N'SELECT @v = CASE WHEN EXISTS (
              SELECT 1 FROM reservasdbV2.dbo.auditoriaRespaldo
              WHERE tipoOperacion = ''BACKUP'' AND resultado = ''OK'' AND archivo = @a
          ) THEN 1 ELSE 0 END;',
        N'@a NVARCHAR(400), @v BIT OUTPUT',
        @a = @archivo, @v = @valido OUTPUT;

    IF @valido = 0
        THROW 51202, 'El archivo indicado no está en la lista de respaldos válidos del sistema.', 1;

    DECLARE @usuario SYSNAME = ORIGINAL_LOGIN();
    DECLARE @sql NVARCHAR(MAX) =
        N'RESTORE DATABASE reservasdbV2 FROM DISK = N''' + REPLACE(@archivo, N'''', N'''''') +
        N''' WITH REPLACE, RECOVERY, CHECKSUM, STATS = 10;';

    BEGIN TRY
        ALTER DATABASE reservasdbV2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        EXEC sys.sp_executesql @sql;
        ALTER DATABASE reservasdbV2 SET MULTI_USER;

        /* Se deja constancia dentro de la base ya restaurada. */
        EXEC sys.sp_executesql
            N'INSERT INTO reservasdbV2.dbo.auditoriaRespaldo
                  (tipoOperacion, archivo, resultado, mensaje, usuarioBD)
              VALUES (''RESTORE'', @a, ''OK'', N''Restauración completada.'', @u);',
            N'@a NVARCHAR(400), @u SYSNAME', @a = @archivo, @u = @usuario;

        SELECT @archivo AS archivo, N'Base de datos restaurada correctamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        /* Si algo falla, nunca se deja la base bloqueada en modo SINGLE_USER. */
        IF EXISTS (SELECT 1 FROM sys.databases
                   WHERE name = N'reservasdbV2' AND state_desc = N'ONLINE')
            ALTER DATABASE reservasdbV2 SET MULTI_USER;
        THROW;
    END CATCH;
END;
GO

USE reservasdbV2;
GO

/* ============================================================================
   13. DATOS DE EJEMPLO: RESERVAS Y DETALLES
   ----------------------------------------------------------------------------
   Montos de ejemplo: subtotal = precio x noches x (1 - descuento del tipo de
   cliente); IVA = 13 % del subtotal; total = subtotal + IVA.
   Se insertan las reservas con total 0; el trigger trg_actualizar_totales_reserva
   calcula los totales a partir de los detalles. Se usa el formato de fecha
   YYYYMMDD porque no depende del idioma del servidor.
   ============================================================================ */

INSERT INTO dbo.reserva (idRecepcionista, idCliente, fechaReserva, estadoReserva)
VALUES
('504470975', '10101010', '20260920', 'Finalizada'),  -- idReserva 1
('112340001', '20202020', '20260928', 'Finalizada'),  -- idReserva 2
('223450002', '30303030', '20261002', 'Confirmada'),  -- idReserva 3
('504470975', '40404040', '20261005', 'Pendiente'),   -- idReserva 4
('112340001', '50505050', '20261006', 'Confirmada'),  -- idReserva 5
('223450002', '10101010', '20261007', 'Cancelada');   -- idReserva 6
GO

INSERT INTO dbo.detallereserva
(idHabitacion, idReserva, idTarifa, cantidadPersonas, precioAplicado,
 fechaEntrada, fechaSalida, iva, subTotal, total, estado)
VALUES
-- Reserva 1: Sencilla 101, 3 noches, cliente Regular (0 %)
(1, 1, 2, 1, 45000.00, '20260925', '20260928',  17550.00, 135000.00, 152550.00, 1),
-- Reserva 2: Doble 201, 3 noches, cliente VIP (15 %)
(4, 2, 4, 2, 70000.00, '20261001', '20261004',  23205.00, 178500.00, 201705.00, 1),
-- Reserva 3: Suite 301 (3 noches) y Suite 302 (2 noches), cliente Empresarial (10 %)
(7, 3, 6, 4, 95000.00, '20261012', '20261015',  33345.00, 256500.00, 289845.00, 1),
(8, 3, 6, 3, 95000.00, '20261012', '20261014',  22230.00, 171000.00, 193230.00, 1),
-- Reserva 4: Sencilla 102, 2 noches, cliente Regular (0 %)
(2, 4, 2, 1, 45000.00, '20261020', '20261022',  11700.00,  90000.00, 101700.00, 1),
-- Reserva 5: Doble 202, 4 noches, cliente VIP (15 %)
(5, 5, 4, 2, 70000.00, '20261101', '20261105',  30940.00, 238000.00, 268940.00, 1),
-- Reserva 6: cancelada, detalle desactivado (estado = 0)
(3, 6, 2, 1, 45000.00, '20261012', '20261014',  11700.00,  90000.00, 101700.00, 0);
GO

/* ============================================================================
   13.1 ASIGNACIÓN DEL USUARIO DEL MOTOR A SU RECEPCIONISTA
   ----------------------------------------------------------------------------
   Cada reserva queda a nombre de un recepcionista (llave foránea). Esta tabla
   relaciona el usuario del motor con el que inicia sesión una persona de
   recepción con su cédula. NO guarda usuarios ni contraseñas: solo el nombre
   del login del motor y la cédula del recepcionista.
   La función fn_RecepcionistaActual() devuelve la cédula del usuario conectado
   (NULL si no está asignado, por ejemplo el administrador).
   ============================================================================ */
CREATE TABLE dbo.recepcionistalogin
(
    loginBD         SYSNAME     NOT NULL,
    idRecepcionista VARCHAR(20) NOT NULL,

    CONSTRAINT pk_recepcionistalogin PRIMARY KEY (loginBD),
    CONSTRAINT fk_recepcionistalogin_recepcionista
        FOREIGN KEY (idRecepcionista) REFERENCES dbo.recepcionista (cedula)
);
GO

INSERT INTO dbo.recepcionistalogin (loginBD, idRecepcionista)
VALUES (N'login_recepcion_hotel', '504470975');
GO

CREATE OR ALTER FUNCTION dbo.fn_RecepcionistaActual()
RETURNS VARCHAR(20)
AS
BEGIN
    RETURN
    (
        SELECT TOP (1) idRecepcionista
        FROM dbo.recepcionistalogin
        WHERE loginBD = ORIGINAL_LOGIN()
    );
END;
GO

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

/* ============================================================================
   15. VERIFICACIÓN (solo lectura; útil para la demostración)
   ============================================================================ */

/* 15.1 Conteo de objetos creados */
SELECT
    (SELECT COUNT(*) FROM sys.tables     WHERE is_ms_shipped = 0)                AS tablas,
    (SELECT COUNT(*) FROM sys.views      WHERE is_ms_shipped = 0)                AS vistas,
    (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0)                AS procedimientos,
    (SELECT COUNT(*) FROM sys.objects    WHERE type IN ('FN','IF','TF'))         AS funciones,
    (SELECT COUNT(*) FROM sys.triggers   WHERE is_ms_shipped = 0)                AS triggers,
    (SELECT COUNT(*) FROM sys.indexes    WHERE name LIKE 'ix[_]%' OR name LIKE 'ux[_]%') AS indices;
GO

/* 15.2 Pertenencia a roles */
SELECT r.name AS rol, m.name AS usuario
FROM sys.database_role_members AS rm
INNER JOIN sys.database_principals AS r ON r.principal_id = rm.role_principal_id
INNER JOIN sys.database_principals AS m ON m.principal_id = rm.member_principal_id
WHERE r.name IN ('rol_admin_hotel', 'rol_recepcion');
GO

/* 15.3 Prueba de privilegios: debe dar 0 para recepción y 1 para admin */
EXECUTE AS USER = 'usr_recepcion_hotel';
SELECT USER_NAME() AS usuario,
       HAS_PERMS_BY_NAME('dbo.pa_Cliente_Crear',   'OBJECT', 'EXECUTE') AS puedeCrearClientes,
       HAS_PERMS_BY_NAME('dbo.pa_Recepcionista_Crear','OBJECT', 'EXECUTE') AS puedeCrearRecepcionistas,
       HAS_PERMS_BY_NAME('dbo.pa_Tarifa_Crear',    'OBJECT', 'EXECUTE') AS puedeCrearTarifas,
       HAS_PERMS_BY_NAME('dbo.pa_Respaldo_Crear',  'OBJECT', 'EXECUTE') AS puedeRespaldar,
       HAS_PERMS_BY_NAME('dbo.auditoriaReserva',   'OBJECT', 'SELECT')  AS puedeVerAuditoria;
REVERT;
GO
EXECUTE AS USER = 'usr_admin_hotel';
SELECT USER_NAME() AS usuario,
       HAS_PERMS_BY_NAME('dbo.pa_Cliente_Crear',   'OBJECT', 'EXECUTE') AS puedeCrearClientes,
       HAS_PERMS_BY_NAME('dbo.pa_Recepcionista_Crear','OBJECT', 'EXECUTE') AS puedeCrearRecepcionistas,
       HAS_PERMS_BY_NAME('dbo.pa_Tarifa_Crear',    'OBJECT', 'EXECUTE') AS puedeCrearTarifas,
       HAS_PERMS_BY_NAME('dbo.pa_Respaldo_Crear',  'OBJECT', 'EXECUTE') AS puedeRespaldar,
       HAS_PERMS_BY_NAME('dbo.auditoriaReserva',   'OBJECT', 'SELECT')  AS puedeVerAuditoria;
REVERT;
GO

/* 15.4 Reservas de ejemplo con sus totales calculados por el trigger */
SELECT idReserva, idCliente, estadoReserva, subTotal, iva, total
FROM dbo.reserva
ORDER BY idReserva;
GO

/* 15.5 Auditoría generada por los datos de ejemplo */
SELECT TOP (20) * FROM dbo.vw_Auditoria_Reciente ORDER BY fecha DESC;
GO

/* ============================================================================
   FIN DEL SCRIPT MAESTRO
   ============================================================================ */