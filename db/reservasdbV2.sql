-- =========================================================
-- BASE DE DATOS: reservasdbV2
-- =========================================================

USE master;
GO

IF DB_ID('reservasdbV2') IS NOT NULL
BEGIN
    ALTER DATABASE reservasdbV2
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE reservasdbV2;
END;
GO

CREATE DATABASE reservasdbV2;
GO

-- =========================================================
-- ESTRUCTURA FÍSICA
-- =========================================================

ALTER DATABASE reservasdbV2
MODIFY FILE
(
    NAME = reservasdbV2,
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 25MB
);
GO

ALTER DATABASE reservasdbV2
MODIFY FILE
(
    NAME = reservasdbV2_log,
    SIZE = 15MB,
    MAXSIZE = 80MB,
    FILEGROWTH = 15%
);
GO

USE reservasdbV2;
GO


-- =========================================================
-- TIPO CLIENTE
-- =========================================================

CREATE TABLE tipocliente
(
    idTipoCliente INT IDENTITY(1,1) NOT NULL,
    nombreTipoC VARCHAR(45) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    descuentoBase DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_tipocliente
    PRIMARY KEY(idTipoCliente)
);
GO


-- =========================================================
-- CLIENTE
-- =========================================================

CREATE TABLE cliente
(
    cedula VARCHAR(20) NOT NULL,
    idTipoCliente INT NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    apellidos VARCHAR(45) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_cliente
    PRIMARY KEY(cedula),

    CONSTRAINT fk_cliente_tipocliente
    FOREIGN KEY(idTipoCliente)
    REFERENCES tipocliente(idTipoCliente)
);
GO


-- =========================================================
-- TIPO HABITACIÓN
-- =========================================================

CREATE TABLE tipohabitacion
(
    idTipoHabitacion INT IDENTITY(1,1) NOT NULL,
    nombreTipoHab VARCHAR(45) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    capacidadMaxima INT NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_tipohabitacion
    PRIMARY KEY(idTipoHabitacion)
);
GO


-- =========================================================
-- HABITACIÓN
-- =========================================================

CREATE TABLE habitacion
(
    idHabitacion INT IDENTITY(1,1) NOT NULL,
    idTipoHab INT NOT NULL,
    numeroHabitacion VARCHAR(45) NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_habitacion
    PRIMARY KEY(idHabitacion),

    CONSTRAINT fk_habitacion_tipohabitacion
    FOREIGN KEY(idTipoHab)
    REFERENCES tipohabitacion(idTipoHabitacion)
);
GO


-- =========================================================
-- RECEPCIONISTA
-- =========================================================

CREATE TABLE recepcionista
(
    cedula VARCHAR(20) NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    apellidos VARCHAR(45) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_recepcionista
    PRIMARY KEY(cedula)
);
GO


-- =========================================================
-- RESERVA
-- =========================================================

CREATE TABLE reserva
(
    idReserva INT IDENTITY(1,1) NOT NULL,
    idRecepcionista VARCHAR(20) NOT NULL,
    idCliente VARCHAR(20) NOT NULL,
    fechaReserva DATETIME NOT NULL,
    estadoReserva VARCHAR(25) NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1,
    iva DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    subTotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT pk_reserva
    PRIMARY KEY(idReserva),

    CONSTRAINT fk_reserva_recepcionista
    FOREIGN KEY(idRecepcionista)
    REFERENCES recepcionista(cedula),

    CONSTRAINT fk_reserva_cliente
    FOREIGN KEY(idCliente)
    REFERENCES cliente(cedula)
);
GO


-- =========================================================
-- TARIFA
-- =========================================================

CREATE TABLE tarifa
(
    idTarifa INT IDENTITY(1,1) NOT NULL,
    idTipoHabitacion INT NOT NULL,
    precioBase DECIMAL(10,2) NOT NULL,
    nombreTarifa VARCHAR(45) NOT NULL,
    fechaInicio DATE NULL,
    fechaFin DATE NULL,
    descripcion NVARCHAR(MAX) NULL,
    desactivadaManual TINYINT DEFAULT 0,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_tarifa
    PRIMARY KEY(idTarifa),

    CONSTRAINT fk_tarifa_tipohabitacion
    FOREIGN KEY(idTipoHabitacion)
    REFERENCES tipohabitacion(idTipoHabitacion)
);
GO


-- =========================================================
-- DETALLE RESERVA
-- =========================================================

CREATE TABLE detallereserva
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
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_detallereserva
    PRIMARY KEY(idDetalleReserva),

    CONSTRAINT fk_detallereserva_habitacion
    FOREIGN KEY(idHabitacion)
    REFERENCES habitacion(idHabitacion),

    CONSTRAINT fk_detallereserva_reserva
    FOREIGN KEY(idReserva)
    REFERENCES reserva(idReserva),

    CONSTRAINT fk_detallereserva_tarifa
    FOREIGN KEY(idTarifa)
    REFERENCES tarifa(idTarifa)
);
GO


-- =========================================================
-- USERS
-- =========================================================

CREATE TABLE users
(
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(30) DEFAULT 'user',
    email VARCHAR(150) NOT NULL,
    password VARCHAR(255) NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1,
    image VARCHAR(255) NULL,
    cedula VARCHAR(20) NULL,

    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),

    CONSTRAINT pk_users
    PRIMARY KEY(id),

    CONSTRAINT uq_users_email
    UNIQUE(email),

    CONSTRAINT fk_users_recepcionista
    FOREIGN KEY(cedula)
    REFERENCES recepcionista(cedula)
);
GO


-- =========================================================
-- TRIGGER USERS
-- =========================================================
-- =========================================================
-- TRIGGER 1
-- ACTUALIZAR updated_at DE USERS
-- =========================================================

CREATE TRIGGER trg_users_updated_at
ON users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE u
    SET updated_at = GETDATE()
    FROM users u
    INNER JOIN inserted i
        ON u.id = i.id;
END;
GO


-- =========================================================
-- TRIGGER 2
-- EVITAR DOBLE RESERVA DE UNA HABITACIÓN
-- =========================================================

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


-- =========================================================
-- TRIGGER 3
-- VALIDAR CAPACIDAD MÁXIMA DE LA HABITACIÓN
-- =========================================================

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


-- =========================================================
-- TRIGGER 4
-- ACTUALIZAR AUTOMÁTICAMENTE LOS TOTALES DE LA RESERVA
-- =========================================================

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


-- =========================================================
-- INSERTS: TIPO CLIENTE
-- =========================================================

INSERT INTO tipocliente
(
    nombreTipoC,
    descripcion,
    descuentoBase
)
VALUES
('Regular', 'Cliente regular sin descuento', 0.00),
('VIP', 'Cliente VIP con descuento especial', 15.00),
('Empresarial', 'Cliente corporativo', 10.00);
GO


-- =========================================================
-- INSERTS: CLIENTE
-- =========================================================

INSERT INTO cliente
(
    cedula,
    idTipoCliente,
    nombre,
    apellidos,
    telefono,
    direccion
)
VALUES
('10101010', 1, 'Juan', 'Perez Mora', '8888-1111', 'San Jose, Costa Rica'),
('20202020', 2, 'Maria', 'Lopez Salas', '8888-2222', 'Heredia, Costa Rica'),
('30303030', 3, 'Carlos', 'Ramirez Vega', '8888-3333', 'Alajuela, Costa Rica'),
('40404040', 1, 'Laura', 'Jimenez Soto', '8888-4444', 'Cartago, Costa Rica'),
('50505050', 2, 'Pedro', 'Castro Nunez', '8888-5555', 'Limon, Costa Rica');
GO


-- =========================================================
-- INSERTS: TIPO HABITACIÓN
-- =========================================================

INSERT INTO tipohabitacion
(
    nombreTipoHab,
    descripcion,
    capacidadMaxima
)
VALUES
('Sencilla', 'Habitacion con una cama individual', 1),
('Doble', 'Habitacion con dos camas matrimoniales', 2),
('Suite', 'Habitacion de lujo con todas las amenidades', 4);
GO


-- =========================================================
-- INSERTS: HABITACIÓN
-- =========================================================

INSERT INTO habitacion
(
    idTipoHab,
    numeroHabitacion
)
VALUES
(1, '101'),
(1, '102'),
(1, '103'),
(2, '201'),
(2, '202'),
(2, '203'),
(3, '301'),
(3, '302');
GO


-- =========================================================
-- INSERTS: RECEPCIONISTA
-- =========================================================

INSERT INTO recepcionista
(
    cedula,
    nombre,
    apellidos,
    telefono,
    correo
)
VALUES
('504470975', 'Kelvin', 'Garcia Medrano', '8888-0001', 'kelvin@hotel.com'),
('112340001', 'Gerald', 'Araya Jimenez', '8888-0002', 'gerald@hotel.com'),
('223450002', 'Andy', 'Alvarado', '8888-0003', 'andy@hotel.com');
GO


-- =========================================================
-- INSERTS: USERS
-- =========================================================

INSERT INTO users
(
    name,
    role,
    email,
    password,
    cedula,
    image
)
VALUES
(
    'Kelvin Garcia Medrano',
    'Administrador',
    'kelvin@hotel.com',
    '',
    '504470975',
    '82cd4330-57c6-4ad7-97e7-0dd1d0f3db46_kelvinperfil.jpg'
),
(
    'Melissa Tijerino',
    'Administrador',
    'melissa@hotel.com',
    '',
    NULL,
    '10febf7d-34f9-4613-91ea-b5dfd46711e6_Melissa.png'
),
(
    'Gerald Araya Jimenez',
    'Recepcionista',
    'gerald@hotel.com',
    '',
    '112340001',
    '643e8b36-2515-4635-ad4b-e98e26cc8653_Gerald.png'
),
(
    'Andy Alvarado',
    'Recepcionista',
    'andy@hotel.com',
    '',
    '223450002',
    '6a85f430-85dd-43c2-873e-e7550c764d39_Andy.png'
);
GO


-- =========================================================
-- INSERTS: TARIFAS
-- =========================================================

INSERT INTO tarifa
(
    idTipoHabitacion,
    precioBase,
    nombreTarifa,
    fechaInicio,
    fechaFin,
    descripcion
)
VALUES
(
    1,
    35000,
    'Temporada Baja Sencilla',
    '2026-01-01',
    '2026-06-30',
    'Tarifa para habitacion sencilla en temporada baja'
),
(
    1,
    45000,
    'Temporada Alta Sencilla',
    '2026-07-01',
    '2026-12-31',
    'Tarifa para habitacion sencilla en temporada alta'
),
(
    2,
    55000,
    'Temporada Baja Doble',
    '2026-01-01',
    '2026-06-30',
    'Tarifa para habitacion doble en temporada baja'
),
(
    2,
    70000,
    'Temporada Alta Doble',
    '2026-07-01',
    '2026-12-31',
    'Tarifa para habitacion doble en temporada alta'
),
(
    3,
    75000,
    'Temporada Baja Suite',
    '2026-01-01',
    '2026-06-30',
    'Tarifa para suite en temporada baja'
),
(
    3,
    95000,
    'Temporada Alta Suite',
    '2026-07-01',
    '2026-12-31',
    'Tarifa para suite en temporada alta'
);
GO


-- =========================================================
-- INSERTS: RESERVAS
-- =========================================================

INSERT INTO reserva
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
    '504470975',
    '10101010',
    GETDATE(),
    'Confirmada',
    4550.00,
    35000.00,
    39550.00
),
(
    '112340001',
    '20202020',
    GETDATE(),
    'Pendiente',
    7150.00,
    55000.00,
    62150.00
),
(
    '223450002',
    '30303030',
    GETDATE(),
    'Confirmada',
    9750.00,
    75000.00,
    84750.00
),
(
    '504470975',
    '40404040',
    GETDATE(),
    'Cancelada',
    5850.00,
    45000.00,
    50850.00
),
(
    '112340001',
    '50505050',
    GETDATE(),
    'Confirmada',
    9100.00,
    70000.00,
    79100.00
);
GO


-- =========================================================
-- INSERTS: DETALLE RESERVA
-- =========================================================

INSERT INTO detallereserva
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
    1,
    1,
    1,
    1,
    35000.00,
    '2026-05-10 14:00:00',
    '2026-05-12 12:00:00',
    4550.00,
    35000.00,
    39550.00
),
(
    4,
    2,
    3,
    2,
    55000.00,
    '2026-06-01 14:00:00',
    '2026-06-05 12:00:00',
    7150.00,
    55000.00,
    62150.00
),
(
    7,
    3,
    5,
    3,
    75000.00,
    '2026-07-15 14:00:00',
    '2026-07-18 12:00:00',
    9750.00,
    75000.00,
    84750.00
),
(
    2,
    4,
    2,
    1,
    45000.00,
    '2026-08-01 14:00:00',
    '2026-08-03 12:00:00',
    5850.00,
    45000.00,
    50850.00
),
(
    5,
    5,
    4,
    2,
    70000.00,
    '2026-09-10 14:00:00',
    '2026-09-13 12:00:00',
    9100.00,
    70000.00,
    79100.00
);
GO

-- =========================================================
-- VALIDACIONES ADICIONALES
-- =========================================================

ALTER TABLE detallereserva
ADD CONSTRAINT chk_cantidad_personas
CHECK (cantidadPersonas > 0);
GO


ALTER TABLE detallereserva
ADD CONSTRAINT chk_fechas_reserva
CHECK (fechaSalida > fechaEntrada);
GO


ALTER TABLE tarifa
ADD CONSTRAINT chk_precio_tarifa
CHECK (precioBase >= 0);
GO


ALTER TABLE tipohabitacion
ADD CONSTRAINT chk_capacidad_maxima
CHECK (capacidadMaxima > 0);
GO