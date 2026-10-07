/* ============================================================================
   PROYECTO FINAL - ADMINISTRACIÓN DE BASES DE DATOS AVANZADAS
   BASE DE DATOS: reservasdbV2
   MOTOR: Microsoft SQL Server
   SCRIPT MAESTRO - VERSIÓN BASE
   ---------------------------------------------------------------------------
   Incluye:
   - Creación física de la base de datos (DATA y LOG)
   - Tablas y restricciones
   - Datos iniciales de desarrollo
   - Vistas utilizadas por el backend
   - Procedimientos almacenados utilizados por el backend
   - Triggers actualmente utilizados por el sistema

   PENDIENTE PARA VERSIONES POSTERIORES DEL MISMO SCRIPT:
   - Índices finales y justificación de optimización
   - Usuarios/roles del motor SQL Server y privilegios
   - Tablas y triggers de auditoría requeridos por el proyecto
   - Procedimientos de respaldo y restauración

   IMPORTANTE:
   Este script RECREA la base de datos desde cero.
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

CREATE TABLE dbo.users
(
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(30) NULL
        CONSTRAINT df_users_role DEFAULT ('user'),
    email VARCHAR(150) NOT NULL,
    password VARCHAR(255) NOT NULL,
    estado TINYINT NOT NULL
        CONSTRAINT df_users_estado DEFAULT (1),
    image VARCHAR(255) NULL,
    cedula VARCHAR(20) NULL,
    created_at DATETIME NOT NULL
        CONSTRAINT df_users_created DEFAULT (GETDATE()),
    updated_at DATETIME NOT NULL
        CONSTRAINT df_users_updated DEFAULT (GETDATE()),

    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT fk_users_recepcionista
        FOREIGN KEY (cedula) REFERENCES dbo.recepcionista(cedula),
    CONSTRAINT chk_users_estado CHECK (estado IN (0,1))
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
   Los usuarios de aplicación se crean desde el backend utilizando bcrypt y
   las variables ADMIN_* del archivo de configuración. No se insertan aquí
   contraseñas en texto plano ni hashes ficticios.
*/

/* ============================================================================
   5. VISTAS
   ============================================================================ */

CREATE OR ALTER VIEW dbo.vw_TipoHabitacion_Resumen
AS
SELECT
    th.idTipoHabitacion,
    th.nombreTipoHab,
    th.descripcion,
    th.capacidadMaxima,
    th.estado,
    COUNT(h.idHabitacion) AS cantidadHabitaciones
FROM dbo.tipohabitacion AS th
LEFT JOIN dbo.habitacion AS h
    ON h.idTipoHab = th.idTipoHabitacion
GROUP BY
    th.idTipoHabitacion,
    th.nombreTipoHab,
    th.descripcion,
    th.capacidadMaxima,
    th.estado;
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
FROM dbo.tipocliente AS tc
LEFT JOIN dbo.cliente AS c
    ON c.idTipoCliente = tc.idTipoCliente
GROUP BY
    tc.idTipoCliente,
    tc.nombreTipoC,
    tc.descripcion,
    tc.descuentoBase,
    tc.estado;
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
    COUNT(rv.idReserva) AS cantidadReservas,
    MAX(rv.fechaReserva) AS ultimaReserva
FROM dbo.recepcionista AS r
LEFT JOIN dbo.reserva AS rv
    ON rv.idRecepcionista = r.cedula
GROUP BY
    r.cedula,
    r.nombre,
    r.apellidos,
    r.telefono,
    r.correo,
    r.estado;
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

CREATE OR ALTER VIEW dbo.vw_Usuario_Detalle
AS
SELECT
    u.id,
    u.name,
    u.role,
    u.email,
    u.image,
    u.cedula,
    u.created_at,
    u.updated_at,
    u.estado,
    CASE
        WHEN r.cedula IS NULL THEN NULL
        ELSE CONCAT(r.nombre, ' ', r.apellidos)
    END AS nombreRecepcionista
FROM dbo.users AS u
LEFT JOIN dbo.recepcionista AS r
    ON r.cedula = u.cedula;
GO

CREATE OR ALTER VIEW dbo.vw_Reserva_Detalle
AS
SELECT
    r.idReserva,
    r.idRecepcionista,
    r.idCliente,
    CONCAT(c.nombre, ' ', c.apellidos) AS nombreCliente,
    CONCAT(re.nombre, ' ', re.apellidos) AS nombreRecepcionista,
    r.fechaReserva,
    r.estadoReserva,
    r.estado,
    r.iva,
    r.subTotal,
    r.total
FROM dbo.reserva AS r
INNER JOIN dbo.cliente AS c
    ON c.cedula = r.idCliente
INNER JOIN dbo.recepcionista AS re
    ON re.cedula = r.idRecepcionista;
GO

CREATE OR ALTER VIEW dbo.vw_DetalleReserva_Detalle
AS
SELECT
    dr.idDetalleReserva,
    dr.idHabitacion,
    dr.idReserva,
    dr.idTarifa,
    th.nombreTipoHab AS nombreTipoHabitacion,
    h.numeroHabitacion,
    CONCAT(rp.nombre, ' ', rp.apellidos) AS nombreRecepcionista,
    CONCAT(c.nombre, ' ', c.apellidos) AS nombreCliente,
    tc.nombreTipoC AS nombreTipoCliente,
    tc.descuentoBase,
    r.fechaReserva,
    r.estadoReserva,
    t.nombreTarifa,
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
    ON h.idHabitacion = dr.idHabitacion
INNER JOIN dbo.tipohabitacion AS th
    ON th.idTipoHabitacion = h.idTipoHab
INNER JOIN dbo.reserva AS r
    ON r.idReserva = dr.idReserva
INNER JOIN dbo.recepcionista AS rp
    ON rp.cedula = r.idRecepcionista
INNER JOIN dbo.cliente AS c
    ON c.cedula = r.idCliente
INNER JOIN dbo.tipocliente AS tc
    ON tc.idTipoCliente = c.idTipoCliente
INNER JOIN dbo.tarifa AS t
    ON t.idTarifa = dr.idTarifa;
GO

/* ============================================================================
   6. PROCEDIMIENTOS ALMACENADOS - TIPO HABITACIÓN
   ============================================================================ */

CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_Listar
    @soloActivos TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @soloActivos IS NOT NULL AND @soloActivos NOT IN (0,1)
        THROW 50001, 'El parámetro soloActivos debe ser 0, 1 o NULL.', 1;

    SELECT idTipoHabitacion, nombreTipoHab, descripcion, capacidadMaxima, estado
    FROM dbo.tipohabitacion
    WHERE @soloActivos IS NULL OR estado = @soloActivos
    ORDER BY nombreTipoHab;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_ObtenerPorId
    @idTipoHabitacion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF @idTipoHabitacion IS NULL OR @idTipoHabitacion <= 0
        THROW 50002, 'El ID del tipo de habitación debe ser mayor que cero.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.tipohabitacion WHERE idTipoHabitacion = @idTipoHabitacion)
        THROW 50003, 'El tipo de habitación solicitado no existe.', 1;

    SELECT idTipoHabitacion, nombreTipoHab, descripcion, capacidadMaxima, estado
    FROM dbo.tipohabitacion
    WHERE idTipoHabitacion = @idTipoHabitacion;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_Crear
    @nombreTipoHab VARCHAR(45),
    @descripcion VARCHAR(100),
    @capacidadMaxima INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @nombreTipoHab = LTRIM(RTRIM(@nombreTipoHab));
    SET @descripcion = LTRIM(RTRIM(@descripcion));

    IF @nombreTipoHab IS NULL OR @nombreTipoHab = ''
        THROW 50004, 'El nombre del tipo de habitación es obligatorio.', 1;
    IF @descripcion IS NULL OR @descripcion = ''
        THROW 50005, 'La descripción del tipo de habitación es obligatoria.', 1;
    IF @capacidadMaxima IS NULL OR @capacidadMaxima <= 0
        THROW 50006, 'La capacidad máxima debe ser mayor que cero.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.tipohabitacion WITH (UPDLOCK,HOLDLOCK) WHERE nombreTipoHab = @nombreTipoHab)
            THROW 50007, 'Ya existe un tipo de habitación con ese nombre.', 1;

        INSERT INTO dbo.tipohabitacion(nombreTipoHab, descripcion, capacidadMaxima, estado)
        VALUES(@nombreTipoHab, @descripcion, @capacidadMaxima, 1);

        DECLARE @nuevoId INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @nuevoId AS idTipoHabitacion,
               'Tipo de habitación registrado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

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
    SET @nombreTipoHab = LTRIM(RTRIM(@nombreTipoHab));
    SET @descripcion = LTRIM(RTRIM(@descripcion));

    IF @idTipoHabitacion IS NULL OR @idTipoHabitacion <= 0
        THROW 50008, 'El ID del tipo de habitación debe ser mayor que cero.', 1;
    IF @nombreTipoHab IS NULL OR @nombreTipoHab = ''
        THROW 50009, 'El nombre del tipo de habitación es obligatorio.', 1;
    IF @descripcion IS NULL OR @descripcion = ''
        THROW 50010, 'La descripción del tipo de habitación es obligatoria.', 1;
    IF @capacidadMaxima IS NULL OR @capacidadMaxima <= 0
        THROW 50011, 'La capacidad máxima debe ser mayor que cero.', 1;
    IF @estado IS NULL OR @estado NOT IN (0,1)
        THROW 50012, 'El estado debe ser 0 o 1.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.tipohabitacion WITH (UPDLOCK,HOLDLOCK) WHERE idTipoHabitacion = @idTipoHabitacion)
            THROW 50013, 'El tipo de habitación que intenta actualizar no existe.', 1;
        IF EXISTS (SELECT 1 FROM dbo.tipohabitacion WHERE nombreTipoHab = @nombreTipoHab AND idTipoHabitacion <> @idTipoHabitacion)
            THROW 50014, 'Ya existe otro tipo de habitación con ese nombre.', 1;

        UPDATE dbo.tipohabitacion
        SET nombreTipoHab = @nombreTipoHab,
            descripcion = @descripcion,
            capacidadMaxima = @capacidadMaxima,
            estado = @estado
        WHERE idTipoHabitacion = @idTipoHabitacion;

        DECLARE @filas INT = @@ROWCOUNT;
        COMMIT TRANSACTION;
        SELECT @idTipoHabitacion AS idTipoHabitacion,
               @filas AS filasAfectadas,
               'Tipo de habitación actualizado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_TipoHabitacion_Eliminar
    @idTipoHabitacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.tipohabitacion WITH (UPDLOCK,HOLDLOCK) WHERE idTipoHabitacion = @idTipoHabitacion)
            THROW 50016, 'El tipo de habitación que intenta eliminar no existe.', 1;
        UPDATE dbo.tipohabitacion SET estado = 0 WHERE idTipoHabitacion = @idTipoHabitacion;
        DECLARE @filas INT = @@ROWCOUNT;
        COMMIT TRANSACTION;
        SELECT @idTipoHabitacion AS idTipoHabitacion,
               @filas AS filasAfectadas,
               'Tipo de habitación eliminado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* ============================================================================
   7. PROCEDIMIENTOS ALMACENADOS - TIPO CLIENTE
   ============================================================================ */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Listar
    @soloActivos TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idTipoCliente, nombreTipoC, descripcion, descuentoBase, estado
    FROM dbo.tipocliente
    WHERE @soloActivos IS NULL OR estado = @soloActivos
    ORDER BY nombreTipoC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_ObtenerPorId
    @idTipoCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.tipocliente WHERE idTipoCliente = @idTipoCliente)
        THROW 50103, 'El tipo de cliente solicitado no existe.', 1;
    SELECT idTipoCliente, nombreTipoC, descripcion, descuentoBase, estado
    FROM dbo.tipocliente WHERE idTipoCliente = @idTipoCliente;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Crear
    @nombreTipoC VARCHAR(45),
    @descripcion VARCHAR(100),
    @descuentoBase DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @nombreTipoC = LTRIM(RTRIM(@nombreTipoC));
    SET @descripcion = LTRIM(RTRIM(@descripcion));
    IF @nombreTipoC IS NULL OR @nombreTipoC = '' THROW 50104, 'El nombre del tipo de cliente es obligatorio.', 1;
    IF @descripcion IS NULL OR @descripcion = '' THROW 50105, 'La descripción es obligatoria.', 1;
    IF @descuentoBase < 0 OR @descuentoBase > 100 THROW 50106, 'El descuento debe estar entre 0 y 100.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.tipocliente WITH (UPDLOCK,HOLDLOCK) WHERE nombreTipoC = @nombreTipoC)
            THROW 50107, 'Ya existe un tipo de cliente con ese nombre.', 1;
        INSERT INTO dbo.tipocliente(nombreTipoC, descripcion, descuentoBase, estado)
        VALUES(@nombreTipoC, @descripcion, @descuentoBase, 1);
        DECLARE @id INT = CONVERT(INT,SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @id AS idTipoCliente, 'Tipo de cliente creado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

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
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.tipocliente WITH (UPDLOCK,HOLDLOCK) WHERE idTipoCliente = @idTipoCliente)
            THROW 50111, 'El tipo de cliente que intenta actualizar no existe.', 1;
        IF EXISTS (SELECT 1 FROM dbo.tipocliente WHERE nombreTipoC = @nombreTipoC AND idTipoCliente <> @idTipoCliente)
            THROW 50112, 'Ya existe otro tipo de cliente con ese nombre.', 1;
        UPDATE dbo.tipocliente
        SET nombreTipoC = LTRIM(RTRIM(@nombreTipoC)),
            descripcion = LTRIM(RTRIM(@descripcion)),
            descuentoBase = @descuentoBase,
            estado = @estado
        WHERE idTipoCliente = @idTipoCliente;
        DECLARE @filas INT = @@ROWCOUNT;
        COMMIT TRANSACTION;
        SELECT @idTipoCliente AS idTipoCliente, @filas AS filasAfectadas,
               'Tipo de cliente actualizado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Eliminar
    @idTipoCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.tipocliente WHERE idTipoCliente = @idTipoCliente)
        THROW 50114, 'El tipo de cliente que intenta eliminar no existe.', 1;
    UPDATE dbo.tipocliente SET estado = 0 WHERE idTipoCliente = @idTipoCliente;
    SELECT @idTipoCliente AS idTipoCliente, @@ROWCOUNT AS filasAfectadas,
           'Tipo de cliente eliminado exitosamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_ToggleEstado
    @idTipoCliente INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.tipocliente WHERE idTipoCliente = @idTipoCliente)
        THROW 50116, 'El tipo de cliente no existe.', 1;
    UPDATE dbo.tipocliente
    SET estado = CASE WHEN estado = 1 THEN 0 ELSE 1 END
    WHERE idTipoCliente = @idTipoCliente;
    SELECT idTipoCliente, estado, 'Estado actualizado exitosamente.' AS mensaje
    FROM dbo.tipocliente WHERE idTipoCliente = @idTipoCliente;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Buscar
    @texto VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET @texto = LTRIM(RTRIM(ISNULL(@texto,'')));
    SELECT idTipoCliente, nombreTipoC, descripcion, descuentoBase, estado
    FROM dbo.tipocliente
    WHERE nombreTipoC LIKE '%' + @texto + '%'
       OR descripcion LIKE '%' + @texto + '%'
    ORDER BY nombreTipoC;
END;
GO

/* ============================================================================
   8. PROCEDIMIENTOS ALMACENADOS - RECEPCIONISTA
   ============================================================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT cedula, nombre, apellidos, telefono, correo, estado
    FROM dbo.recepcionista ORDER BY nombre, apellidos;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_ObtenerPorCedula
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.recepcionista WHERE cedula = @cedula)
        THROW 50203, 'El recepcionista no existe.', 1;
    SELECT cedula, nombre, apellidos, telefono, correo, estado
    FROM dbo.recepcionista WHERE cedula = @cedula;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Crear
    @cedula VARCHAR(20), @nombre VARCHAR(45), @apellidos VARCHAR(45),
    @telefono VARCHAR(20), @correo VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.recepcionista WITH (UPDLOCK,HOLDLOCK) WHERE cedula = @cedula)
            THROW 50206, 'Ya existe un recepcionista con esa cédula.', 1;
        INSERT INTO dbo.recepcionista(cedula,nombre,apellidos,telefono,correo,estado)
        VALUES(@cedula,LTRIM(RTRIM(@nombre)),LTRIM(RTRIM(@apellidos)),@telefono,@correo,1);
        COMMIT TRANSACTION;
        SELECT @cedula AS cedula, 'Recepcionista creado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Actualizar
    @cedula VARCHAR(20), @nombre VARCHAR(45), @apellidos VARCHAR(45),
    @telefono VARCHAR(20), @correo VARCHAR(100), @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.recepcionista WHERE cedula = @cedula)
        THROW 50211, 'El recepcionista que intenta actualizar no existe.', 1;
    UPDATE dbo.recepcionista
    SET nombre=@nombre, apellidos=@apellidos, telefono=@telefono, correo=@correo, estado=@estado
    WHERE cedula=@cedula;
    SELECT @cedula AS cedula, @@ROWCOUNT AS filasAfectadas,
           'Recepcionista actualizado exitosamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Eliminar
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.recepcionista WHERE cedula = @cedula)
        THROW 50212, 'El recepcionista que intenta eliminar no existe.', 1;
    UPDATE dbo.recepcionista SET estado=0 WHERE cedula=@cedula;
    SELECT @cedula AS cedula, @@ROWCOUNT AS filasAfectadas,
           'Recepcionista eliminado exitosamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_ToggleEstado
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.recepcionista WHERE cedula = @cedula)
        THROW 50214, 'El recepcionista no existe.', 1;
    UPDATE dbo.recepcionista
    SET estado=CASE WHEN estado=1 THEN 0 ELSE 1 END
    WHERE cedula=@cedula;
    SELECT cedula, estado, 'Estado actualizado exitosamente.' AS mensaje
    FROM dbo.recepcionista WHERE cedula=@cedula;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Buscar
    @texto VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET @texto = LTRIM(RTRIM(ISNULL(@texto,'')));
    SELECT cedula,nombre,apellidos,telefono,correo,estado
    FROM dbo.recepcionista
    WHERE cedula LIKE '%' + @texto + '%'
       OR nombre LIKE '%' + @texto + '%'
       OR apellidos LIKE '%' + @texto + '%'
       OR correo LIKE '%' + @texto + '%'
    ORDER BY nombre, apellidos;
END;
GO

/* ============================================================================
   9. PROCEDIMIENTOS ALMACENADOS - CLIENTE
   ============================================================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Cliente_Crear
    @cedula VARCHAR(20), @idTipoCliente INT, @nombre VARCHAR(45),
    @apellidos VARCHAR(45), @telefono VARCHAR(20), @direccion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.cliente WITH (UPDLOCK,HOLDLOCK) WHERE cedula=@cedula)
            THROW 50301, 'Ya existe un cliente con esa cédula.', 1;
        IF NOT EXISTS (SELECT 1 FROM dbo.tipocliente WHERE idTipoCliente=@idTipoCliente)
            THROW 50302, 'El tipo de cliente indicado no existe.', 1;
        INSERT INTO dbo.cliente(cedula,idTipoCliente,nombre,apellidos,telefono,direccion,estado)
        VALUES(@cedula,@idTipoCliente,@nombre,@apellidos,@telefono,@direccion,1);
        COMMIT TRANSACTION;
        SELECT @cedula AS cedula, 'Cliente creado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Cliente_Actualizar
    @cedula VARCHAR(20), @idTipoCliente INT, @nombre VARCHAR(45),
    @apellidos VARCHAR(45), @telefono VARCHAR(20), @direccion VARCHAR(100), @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.cliente WHERE cedula=@cedula)
        THROW 50309, 'El cliente que intenta actualizar no existe.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.tipocliente WHERE idTipoCliente=@idTipoCliente)
        THROW 50310, 'El tipo de cliente indicado no existe.', 1;
    UPDATE dbo.cliente
    SET idTipoCliente=@idTipoCliente,nombre=@nombre,apellidos=@apellidos,
        telefono=@telefono,direccion=@direccion,estado=@estado
    WHERE cedula=@cedula;
    SELECT @cedula AS cedula, @@ROWCOUNT AS filasAfectadas,
           'Cliente actualizado exitosamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Cliente_CambiarEstado
    @cedula VARCHAR(20),
    @nuevoEstado TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.cliente WHERE cedula=@cedula)
        THROW 50312, 'El cliente no existe.', 1;
    IF @nuevoEstado IS NOT NULL AND @nuevoEstado NOT IN (0,1)
        THROW 50313, 'El estado debe ser 0, 1 o NULL.', 1;
    UPDATE dbo.cliente
    SET estado = CASE WHEN @nuevoEstado IS NULL
                      THEN CASE WHEN estado=1 THEN 0 ELSE 1 END
                      ELSE @nuevoEstado END
    WHERE cedula=@cedula;
    SELECT cedula, estado, 'Estado actualizado exitosamente.' AS mensaje
    FROM dbo.cliente WHERE cedula=@cedula;
END;
GO

/* ============================================================================
   10. PROCEDIMIENTOS ALMACENADOS - TARIFA
   ============================================================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_Crear
    @idTipoHabitacion INT,
    @precioBase DECIMAL(10,2),
    @nombreTarifa VARCHAR(45),
    @fechaInicio DATE = NULL,
    @fechaFin DATE = NULL,
    @descripcion NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.tipohabitacion WHERE idTipoHabitacion=@idTipoHabitacion)
        THROW 50401, 'El tipo de habitación indicado no existe.', 1;
    INSERT INTO dbo.tarifa(idTipoHabitacion,precioBase,nombreTarifa,fechaInicio,fechaFin,descripcion,desactivadaManual,estado)
    VALUES(@idTipoHabitacion,@precioBase,@nombreTarifa,@fechaInicio,@fechaFin,@descripcion,0,1);
    DECLARE @id INT=CONVERT(INT,SCOPE_IDENTITY());
    SELECT @id AS idTarifa, 'Tarifa creada exitosamente.' AS mensaje;
END;
GO

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
    IF NOT EXISTS (SELECT 1 FROM dbo.tarifa WHERE idTarifa=@idTarifa)
        THROW 50410, 'La tarifa indicada no existe.', 1;
    IF @idTipoHabitacion IS NOT NULL AND NOT EXISTS
       (SELECT 1 FROM dbo.tipohabitacion WHERE idTipoHabitacion=@idTipoHabitacion)
        THROW 50411, 'El tipo de habitación indicado no existe.', 1;

    UPDATE dbo.tarifa
    SET idTipoHabitacion=COALESCE(@idTipoHabitacion,idTipoHabitacion),
        precioBase=COALESCE(@precioBase,precioBase),
        nombreTarifa=COALESCE(@nombreTarifa,nombreTarifa),
        fechaInicio=COALESCE(@fechaInicio,fechaInicio),
        fechaFin=COALESCE(@fechaFin,fechaFin),
        descripcion=@descripcion
    WHERE idTarifa=@idTarifa;

    SELECT @idTarifa AS idTarifa, @@ROWCOUNT AS filasAfectadas,
           'Tarifa actualizada exitosamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_CambiarEstado
    @idTarifa INT,
    @activar TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.tarifa WHERE idTarifa=@idTarifa)
        THROW 50415, 'La tarifa indicada no existe.', 1;
    IF @activar NOT IN (0,1)
        THROW 50416, 'El parámetro activar debe ser 0 o 1.', 1;

    IF @activar=1
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1 FROM dbo.tarifa
            WHERE idTarifa=@idTarifa
              AND (fechaInicio IS NULL OR CAST(GETDATE() AS DATE)>=fechaInicio)
              AND (fechaFin IS NULL OR CAST(GETDATE() AS DATE)<=fechaFin)
        )
            THROW 50417, 'La tarifa no puede activarse fuera de su período de vigencia.', 1;

        UPDATE dbo.tarifa
        SET estado=1,
            desactivadaManual=0
        WHERE idTarifa=@idTarifa;
    END
    ELSE
    BEGIN
        UPDATE dbo.tarifa
        SET estado=0,
            desactivadaManual=1
        WHERE idTarifa=@idTarifa;
    END;

    SELECT idTarifa,estado,desactivadaManual,'Estado actualizado exitosamente.' AS mensaje
    FROM dbo.tarifa WHERE idTarifa=@idTarifa;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_SincronizarVigencia
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @hoy DATE=CAST(GETDATE() AS DATE);

    UPDATE dbo.tarifa
    SET estado=0,
        desactivadaManual=0
    WHERE estado=1
      AND fechaFin IS NOT NULL
      AND fechaFin<@hoy;

    UPDATE dbo.tarifa
    SET estado=1
    WHERE desactivadaManual=0
      AND estado=0
      AND (fechaInicio IS NULL OR fechaInicio<=@hoy)
      AND (fechaFin IS NULL OR fechaFin>=@hoy);
END;
GO

/* ============================================================================
   11. PROCEDIMIENTOS ALMACENADOS - HABITACIÓN
   ============================================================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Habitacion_Crear
    @idTipoHab INT,
    @numeroHabitacion VARCHAR(45)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @numeroHabitacion=LTRIM(RTRIM(@numeroHabitacion));
    IF @numeroHabitacion IS NULL OR @numeroHabitacion=''
        THROW 50501, 'El número de habitación es obligatorio.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM dbo.tipohabitacion WHERE idTipoHabitacion=@idTipoHab)
            THROW 50502, 'El tipo de habitación indicado no existe.', 1;
        IF EXISTS (SELECT 1 FROM dbo.habitacion WITH (UPDLOCK,HOLDLOCK) WHERE numeroHabitacion=@numeroHabitacion)
            THROW 50503, 'Ya existe una habitación con ese número.', 1;
        INSERT INTO dbo.habitacion(idTipoHab,numeroHabitacion,estado)
        VALUES(@idTipoHab,@numeroHabitacion,1);
        DECLARE @id INT=CONVERT(INT,SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @id AS idHabitacion,'Habitación creada exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Habitacion_Actualizar
    @idHabitacion INT,
    @idTipoHab INT,
    @numeroHabitacion VARCHAR(45),
    @estado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET @numeroHabitacion=LTRIM(RTRIM(@numeroHabitacion));
    IF NOT EXISTS (SELECT 1 FROM dbo.habitacion WHERE idHabitacion=@idHabitacion)
        THROW 50507, 'La habitación indicada no existe.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.tipohabitacion WHERE idTipoHabitacion=@idTipoHab)
        THROW 50508, 'El tipo de habitación indicado no existe.', 1;
    IF @estado NOT IN (0,1)
        THROW 50509, 'El estado debe ser 0 o 1.', 1;

    UPDATE dbo.habitacion
    SET idTipoHab=@idTipoHab, numeroHabitacion=@numeroHabitacion, estado=@estado
    WHERE idHabitacion=@idHabitacion;
    SELECT @idHabitacion AS idHabitacion,@@ROWCOUNT AS filasAfectadas,
           'Habitación actualizada exitosamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Habitacion_CambiarEstado
    @idHabitacion INT,
    @nuevoEstado TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.habitacion WHERE idHabitacion=@idHabitacion)
        THROW 50510, 'La habitación indicada no existe.', 1;
    IF @nuevoEstado NOT IN (0,1)
        THROW 50511, 'El estado debe ser 0 o 1.', 1;
    UPDATE dbo.habitacion SET estado=@nuevoEstado WHERE idHabitacion=@idHabitacion;
    SELECT idHabitacion,estado,@@ROWCOUNT AS filasAfectadas,
           'Estado actualizado exitosamente.' AS mensaje
    FROM dbo.habitacion WHERE idHabitacion=@idHabitacion;
END;
GO

/* ============================================================================
   12. PROCEDIMIENTOS ALMACENADOS - USERS
   ============================================================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Usuario_Crear
    @name VARCHAR(100),
    @email VARCHAR(150),
    @password VARCHAR(255),
    @role VARCHAR(30)=NULL,
    @image VARCHAR(255)=NULL,
    @cedula VARCHAR(20)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @name=LTRIM(RTRIM(@name));
    SET @email=LTRIM(RTRIM(@email));
    IF @cedula IS NOT NULL SET @cedula=NULLIF(LTRIM(RTRIM(@cedula)),'');
    IF @role IS NOT NULL SET @role=NULLIF(LTRIM(RTRIM(@role)),'');
    IF @image IS NOT NULL SET @image=NULLIF(LTRIM(RTRIM(@image)),'');

    IF @name IS NULL OR @name='' THROW 50601,'El nombre es obligatorio.',1;
    IF @email IS NULL OR @email='' THROW 50602,'El correo electrónico es obligatorio.',1;
    IF @password IS NULL OR @password='' THROW 50603,'La contraseña es obligatoria.',1;

    BEGIN TRY
        BEGIN TRANSACTION;
        IF EXISTS (SELECT 1 FROM dbo.users WITH (UPDLOCK,HOLDLOCK) WHERE LOWER(email)=LOWER(@email))
            THROW 50604,'El correo electrónico ya está registrado.',1;
        IF @cedula IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.recepcionista WHERE cedula=@cedula)
            THROW 50605,'El recepcionista asociado no existe.',1;
        INSERT INTO dbo.users(name,email,password,role,image,cedula,estado)
        VALUES(@name,@email,@password,@role,@image,@cedula,1);
        DECLARE @id INT=CONVERT(INT,SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @id AS id,'Usuario creado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Usuario_Actualizar
    @id INT,
    @name VARCHAR(100),
    @email VARCHAR(150),
    @role VARCHAR(30)=NULL,
    @image VARCHAR(255)=NULL,
    @cedula VARCHAR(20)=NULL,
    @password VARCHAR(255)=NULL,
    @estado TINYINT=NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE id=@id)
        THROW 50608,'El usuario que intenta actualizar no existe.',1;
    IF EXISTS (SELECT 1 FROM dbo.users WHERE LOWER(email)=LOWER(@email) AND id<>@id)
        THROW 50609,'El correo electrónico ya está registrado por otro usuario.',1;
    IF @cedula IS NOT NULL AND NULLIF(LTRIM(RTRIM(@cedula)),'') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.recepcionista WHERE cedula=@cedula)
        THROW 50610,'El recepcionista asociado no existe.',1;

    UPDATE dbo.users
    SET name=@name, role=NULLIF(@role,''), email=@email,
        password=COALESCE(@password,password), image=NULLIF(@image,''),
        cedula=NULLIF(@cedula,''), estado=COALESCE(@estado,estado)
    WHERE id=@id;

    SELECT @id AS id,@@ROWCOUNT AS filasAfectadas,
           'Usuario actualizado exitosamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Usuario_ToggleEstado
    @id INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE id=@id)
        THROW 50611,'El usuario no existe.',1;
    UPDATE dbo.users SET estado=CASE WHEN estado=1 THEN 0 ELSE 1 END WHERE id=@id;
    SELECT id,estado,'Estado del usuario actualizado exitosamente.' AS mensaje
    FROM dbo.users WHERE id=@id;
END;
GO

/* ============================================================================
   13. PROCEDIMIENTOS ALMACENADOS - RESERVA
   ============================================================================ */

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
        IF NOT EXISTS (SELECT 1 FROM dbo.recepcionista WHERE cedula=@idRecepcionista)
            THROW 50701,'El recepcionista indicado no existe.',1;
        IF NOT EXISTS (SELECT 1 FROM dbo.cliente WHERE cedula=@idCliente)
            THROW 50702,'El cliente indicado no existe.',1;
        INSERT INTO dbo.reserva(idRecepcionista,idCliente,fechaReserva,estadoReserva,iva,subTotal,total)
        VALUES(@idRecepcionista,@idCliente,@fechaReserva,@estadoReserva,@iva,@subTotal,@total);
        DECLARE @id INT=CONVERT(INT,SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @id AS idReserva,'Reserva creada exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

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
    IF NOT EXISTS (SELECT 1 FROM dbo.reserva WHERE idReserva=@idReserva)
        THROW 50703,'La reserva indicada no existe.',1;
    IF NOT EXISTS (SELECT 1 FROM dbo.recepcionista WHERE cedula=@idRecepcionista)
        THROW 50704,'El recepcionista indicado no existe.',1;
    IF NOT EXISTS (SELECT 1 FROM dbo.cliente WHERE cedula=@idCliente)
        THROW 50705,'El cliente indicado no existe.',1;
    UPDATE dbo.reserva
    SET idRecepcionista=@idRecepcionista,idCliente=@idCliente,fechaReserva=@fechaReserva,
        estadoReserva=@estadoReserva,estado=@estado,iva=@iva,subTotal=@subTotal,total=@total
    WHERE idReserva=@idReserva;
    SELECT @idReserva AS idReserva,@@ROWCOUNT AS filasAfectadas,
           'Reserva actualizada exitosamente.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Reserva_ToggleEstado
    @idReserva INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.reserva WHERE idReserva=@idReserva)
        THROW 50706,'La reserva indicada no existe.',1;
    UPDATE dbo.reserva SET estado=CASE WHEN estado=1 THEN 0 ELSE 1 END WHERE idReserva=@idReserva;
    SELECT idReserva,estado,'Estado actualizado exitosamente.' AS mensaje
    FROM dbo.reserva WHERE idReserva=@idReserva;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_Reserva_ActualizarEstadoReserva
    @idReserva INT,
    @estadoReserva VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.reserva SET estadoReserva=@estadoReserva WHERE idReserva=@idReserva;
    SELECT @idReserva AS idReserva,@@ROWCOUNT AS filasAfectadas,
           'Estado de reserva actualizado.' AS mensaje;
END;
GO

/* ============================================================================
   14. PROCEDIMIENTOS ALMACENADOS - DETALLE RESERVA
   ============================================================================ */

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
        IF NOT EXISTS (SELECT 1 FROM dbo.habitacion WHERE idHabitacion=@idHabitacion)
            THROW 50801,'La habitación indicada no existe.',1;
        IF NOT EXISTS (SELECT 1 FROM dbo.reserva WHERE idReserva=@idReserva)
            THROW 50802,'La reserva indicada no existe.',1;
        IF NOT EXISTS (SELECT 1 FROM dbo.tarifa WHERE idTarifa=@idTarifa)
            THROW 50803,'La tarifa indicada no existe.',1;

        INSERT INTO dbo.detallereserva
        (idHabitacion,idReserva,idTarifa,cantidadPersonas,precioAplicado,fechaEntrada,fechaSalida,iva,subTotal,total)
        VALUES
        (@idHabitacion,@idReserva,@idTarifa,@cantidadPersonas,@precioAplicado,@fechaEntrada,@fechaSalida,@iva,@subTotal,@total);

        DECLARE @id INT=CONVERT(INT,SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @id AS idDetalleReserva,'Detalle de reserva creado exitosamente.' AS mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_DetalleReserva_Actualizar
    @idDetalleReserva INT,
    @idHabitacion INT,
    @idTarifa INT,
    @cantidadPersonas INT,
    @precioAplicado DECIMAL(10,2),
    @fechaEntrada DATETIME=NULL,
    @fechaSalida DATETIME=NULL,
    @iva DECIMAL(10,2),
    @subTotal DECIMAL(10,2),
    @total DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.detallereserva
    SET idHabitacion=@idHabitacion,idTarifa=@idTarifa,cantidadPersonas=@cantidadPersonas,
        precioAplicado=@precioAplicado,
        fechaEntrada=COALESCE(@fechaEntrada,fechaEntrada),
        fechaSalida=COALESCE(@fechaSalida,fechaSalida),
        iva=@iva,subTotal=@subTotal,total=@total
    WHERE idDetalleReserva=@idDetalleReserva;
    SELECT @idDetalleReserva AS idDetalleReserva,@@ROWCOUNT AS filasAfectadas,
           'Detalle de reserva actualizado.' AS mensaje;
END;
GO

CREATE OR ALTER PROCEDURE dbo.pa_DetalleReserva_ToggleEstado
    @idDetalleReserva INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.detallereserva WHERE idDetalleReserva=@idDetalleReserva)
        THROW 50804,'El detalle de reserva indicado no existe.',1;
    UPDATE dbo.detallereserva
    SET estado=CASE WHEN estado=1 THEN 0 ELSE 1 END
    WHERE idDetalleReserva=@idDetalleReserva;
    SELECT idDetalleReserva,estado,1 AS filasAfectadas
    FROM dbo.detallereserva WHERE idDetalleReserva=@idDetalleReserva;
END;
GO

/* ============================================================================
   15. TRIGGERS DE PROTECCIÓN DE ELIMINACIÓN FÍSICA
   ============================================================================ */

CREATE OR ALTER TRIGGER dbo.trg_TipoHabitacion_EvitarDeleteFisico
ON dbo.tipohabitacion
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50020,'No se permite eliminar físicamente un tipo de habitación. Utilice eliminación lógica.',1;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_TipoCliente_EvitarDeleteFisico
ON dbo.tipocliente
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50120,'No se permite eliminar físicamente un tipo de cliente. Utilice eliminación lógica.',1;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Recepcionista_EvitarDeleteFisico
ON dbo.recepcionista
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50220,'No se permite eliminar físicamente un recepcionista. Utilice eliminación lógica.',1;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Cliente_EvitarDeleteFisico
ON dbo.cliente
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50320,'No se permite eliminar físicamente un cliente. Utilice eliminación lógica.',1;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Tarifa_EvitarDeleteFisico
ON dbo.tarifa
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50420,'No se permite eliminar físicamente una tarifa. Utilice eliminación lógica.',1;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Habitacion_EvitarDeleteFisico
ON dbo.habitacion
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50520,'No se permite eliminar físicamente una habitación. Utilice eliminación lógica.',1;
END;
GO

/* ============================================================================
   16. TRIGGERS DE REGLAS DE NEGOCIO
   ============================================================================ */

CREATE OR ALTER TRIGGER dbo.trg_users_updated_at
ON dbo.users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE u
    SET updated_at=GETDATE()
    FROM dbo.users AS u
    INNER JOIN inserted AS i ON i.id=u.id;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_evitar_reserva_habitacion_ocupada
ON dbo.detallereserva
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.detallereserva AS d
            ON d.idHabitacion=i.idHabitacion
           AND d.idDetalleReserva<>i.idDetalleReserva
           AND d.estado=1
           AND i.estado=1
           AND i.fechaEntrada<d.fechaSalida
           AND i.fechaSalida>d.fechaEntrada
    )
    BEGIN
        THROW 50820,'La habitación ya se encuentra reservada en esas fechas.',1;
    END;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_validar_capacidad_habitacion
ON dbo.detallereserva
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS
    (
        SELECT 1
        FROM inserted AS i
        INNER JOIN dbo.habitacion AS h ON h.idHabitacion=i.idHabitacion
        INNER JOIN dbo.tipohabitacion AS th ON th.idTipoHabitacion=h.idTipoHab
        WHERE i.cantidadPersonas>th.capacidadMaxima OR i.cantidadPersonas<=0
    )
    BEGIN
        THROW 50821,'La cantidad de personas no es válida o supera la capacidad máxima de la habitación.',1;
    END;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_actualizar_totales_reserva
ON dbo.detallereserva
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ReservasAfectadas AS
    (
        SELECT idReserva FROM inserted
        UNION
        SELECT idReserva FROM deleted
    ),
    Totales AS
    (
        SELECT
            ra.idReserva,
            SUM(CASE WHEN d.estado=1 THEN d.subTotal ELSE 0 END) AS subTotal,
            SUM(CASE WHEN d.estado=1 THEN d.iva ELSE 0 END) AS iva,
            SUM(CASE WHEN d.estado=1 THEN d.total ELSE 0 END) AS total
        FROM ReservasAfectadas AS ra
        LEFT JOIN dbo.detallereserva AS d
            ON d.idReserva=ra.idReserva
        GROUP BY ra.idReserva
    )
    UPDATE r
    SET r.subTotal=ISNULL(t.subTotal,0),
        r.iva=ISNULL(t.iva,0),
        r.total=ISNULL(t.total,0)
    FROM dbo.reserva AS r
    INNER JOIN Totales AS t ON t.idReserva=r.idReserva;
END;
GO

/* ============================================================================
   17. SECCIONES PENDIENTES DEL PROYECTO FINAL
   ============================================================================ */

/* ---------------------------------------------------------------------------
   17.1 ÍNDICES Y OPTIMIZACIÓN
   PENDIENTE: se definirán después de revisar planes de ejecución y consultas
   reales del backend para justificar cada índice.
   --------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   17.2 FUNCIONES
   PENDIENTE: se incorporarán únicamente funciones con utilidad real dentro
   del sistema.
   --------------------------------------------------------------------------- */
/* ============================================================================
   FUNCIONES - HABITACIÓN
   ============================================================================ */

/* ---------------------------------------------------------------------------
   fn_HabitacionesDisponibles

   Devuelve las habitaciones activas disponibles dentro de un rango de fechas.
   Una habitación se considera disponible cuando no existe ningún detalle de
   reserva activo cuyo rango de fechas se cruce con el período solicitado.

   También devuelve el tipo de habitación y su capacidad máxima.

   Importancia:
   Centraliza la lógica de disponibilidad y evita repetir las condiciones de
   traslape en diferentes consultas del sistema.
   --------------------------------------------------------------------------- */

CREATE OR ALTER FUNCTION dbo.fn_HabitacionesDisponibles
(
    @fechaEntrada DATETIME,
    @fechaSalida DATETIME
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
            AND dr.fechaEntrada < @fechaSalida
            AND dr.fechaSalida > @fechaEntrada
      )
);
GO


/* ============================================================================
   FUNCIONES - CLIENTE
   ============================================================================ */

/* ---------------------------------------------------------------------------
   fn_HistorialReservasCliente

   Devuelve el historial de reservas de un cliente incluyendo habitación,
   tipo de habitación, tarifa, fechas, montos y estados de los registros.

   Importancia:
   Centraliza una consulta que requiere relacionar múltiples tablas y permite
   reutilizarla en atención al cliente, reportes e historial de reservas.
   --------------------------------------------------------------------------- */

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


/* ---------------------------------------------------------------------------
   fn_TotalReservasHuesped

   Devuelve la cantidad de reservas activas y no canceladas asociadas
   a un cliente.

   Importancia:
   Puede utilizarse para estadísticas, identificación de clientes frecuentes
   y futuras reglas comerciales o de fidelización.
   --------------------------------------------------------------------------- */

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


/* ============================================================================
   FUNCIONES - TARIFA
   ============================================================================ */

/* ---------------------------------------------------------------------------
   fn_TarifasVigentes

   Devuelve las tarifas disponibles para una fecha específica tomando en
   cuenta su estado, desactivación manual, vigencia y el estado del tipo
   de habitación.

   Importancia:
   Centraliza la lógica necesaria para determinar qué tarifa puede aplicarse
   a una estadía según la fecha seleccionada.
   --------------------------------------------------------------------------- */

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
      AND
      (
          t.fechaInicio IS NULL
          OR t.fechaInicio <= @fecha
      )
      AND
      (
          t.fechaFin IS NULL
          OR t.fechaFin >= @fecha
      )
);
GO


/* ============================================================================
   FUNCIONES - DETALLE RESERVA
   ============================================================================ */

/* ---------------------------------------------------------------------------
   fn_NochesEstancia

   Calcula la cantidad de noches comprendidas entre una fecha de entrada
   y una fecha de salida.

   Importancia:
   Permite reutilizar el cálculo de noches en consultas, reportes y procesos
   relacionados con el cálculo del precio de una estadía.
   --------------------------------------------------------------------------- */

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

    RETURN DATEDIFF(DAY, @fechaEntrada, @fechaSalida);
END;
GO

/* ---------------------------------------------------------------------------
   17.3 USUARIOS Y ROLES DEL MOTOR SQL SERVER
   PENDIENTE: crear al menos dos usuarios de BD con distintos privilegios y
   conectar el control de acceso de la aplicación con dichos usuarios.
   --------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   17.4 AUDITORÍA
   PENDIENTE: mínimo tres tablas de auditoría enfocadas en operaciones críticas.
   --------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   17.5 RESPALDO Y RESTAURACIÓN
   PENDIENTE: procedimientos almacenados y módulo de aplicación para ejecutar
   BACKUP y RESTORE desde el sistema.
   --------------------------------------------------------------------------- */

/* ============================================================================
   FIN DEL SCRIPT MAESTRO - VERSIÓN BASE
   ============================================================================ */
