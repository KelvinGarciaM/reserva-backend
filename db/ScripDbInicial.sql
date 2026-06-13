-- =========================
-- BASE DE DATOS
-- =========================
DROP DATABASE IF EXISTS reservasdb;
CREATE DATABASE reservasdb;
USE reservasdb;

-- =========================
-- TIPO CLIENTE
-- =========================
CREATE TABLE tipocliente(
    idTipoCliente   INT AUTO_INCREMENT NOT NULL,
    nombreTipoC     VARCHAR(45) NOT NULL,
    descripcion     VARCHAR(100) NOT NULL,
    descuentoBase   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    estado          TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_tipocliente 
    PRIMARY KEY(idTipoCliente)
)ENGINE=INNODB;

-- =========================
-- CLIENTE
-- =========================
CREATE TABLE cliente(
    cedula          VARCHAR(20) NOT NULL,
    idTipoCliente   INT NOT NULL,
    nombre          VARCHAR(45) NOT NULL,
    apellidos       VARCHAR(45) NOT NULL,
    telefono        VARCHAR(20) NOT NULL,
    direccion       VARCHAR(100) NOT NULL,
    estado          TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_cliente 
    PRIMARY KEY(cedula),

    CONSTRAINT fk_cliente_tipocliente 
    FOREIGN KEY(idTipoCliente) 
    REFERENCES tipocliente(idTipoCliente)
)ENGINE=INNODB;

-- =========================
-- TIPO HABITACION
-- =========================
CREATE TABLE tipohabitacion(
    idTipoHabitacion    INT AUTO_INCREMENT NOT NULL,
    nombreTipoHab       VARCHAR(45) NOT NULL,
    descripcion         VARCHAR(100) NOT NULL,
    capacidadMaxima     INT NOT NULL,
    estado              TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_tipohabitacion 
    PRIMARY KEY(idTipoHabitacion)
)ENGINE=INNODB;

-- =========================
-- HABITACION
-- =========================
CREATE TABLE habitacion(
    idHabitacion        INT AUTO_INCREMENT NOT NULL,
    idTipoHab           INT NOT NULL,
    numeroHabitacion    VARCHAR(45) NOT NULL,
    estado              TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_habitacion 
    PRIMARY KEY(idHabitacion),

    CONSTRAINT fk_habitacion_tipohabitacion 
    FOREIGN KEY(idTipoHab) 
    REFERENCES tipohabitacion(idTipoHabitacion)
)ENGINE=INNODB;

-- =========================
-- RECEPCIONISTA
-- =========================
CREATE TABLE recepcionista(
    cedula      VARCHAR(20) NOT NULL,
    nombre      VARCHAR(45) NOT NULL,
    apellidos   VARCHAR(45) NOT NULL,
    telefono    VARCHAR(20) NOT NULL,
    correo      VARCHAR(100) NOT NULL,
    estado      TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_recepcionista 
    PRIMARY KEY(cedula)
)ENGINE=INNODB;

-- =========================
-- RESERVA
-- =========================
CREATE TABLE reserva(
    idReserva       INT AUTO_INCREMENT NOT NULL,
    idRecepcionista VARCHAR(20) NOT NULL,
    idCliente       VARCHAR(20) NOT NULL,
    fechaReserva    DATETIME NOT NULL,
    estadoReserva   VARCHAR(25) NOT NULL,
    estado          TINYINT NOT NULL DEFAULT 1,
    iva             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    subTotal        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total           DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT pk_reserva 
    PRIMARY KEY(idReserva),

    CONSTRAINT fk_reserva_recepcionista 
    FOREIGN KEY(idRecepcionista) 
    REFERENCES recepcionista(cedula),

    CONSTRAINT fk_reserva_cliente 
    FOREIGN KEY(idCliente) 
    REFERENCES cliente(cedula)
)ENGINE=INNODB;

-- =========================
-- TARIFA
-- =========================
CREATE TABLE tarifa(
    idTarifa            INT AUTO_INCREMENT NOT NULL,
    idTipoHabitacion    INT NOT NULL,
    precioBase          DECIMAL(10,2) NOT NULL,
    nombreTarifa        VARCHAR(45) NOT NULL,
    fechaInicio         DATE,
    fechaFin            DATE,
    descripcion         TEXT,
    desactivadaManual   TINYINT DEFAULT 0,
    estado              TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_tarifa 
    PRIMARY KEY(idTarifa),

    CONSTRAINT fk_tarifa_tipohabitacion 
    FOREIGN KEY(idTipoHabitacion) 
    REFERENCES tipohabitacion(idTipoHabitacion)
)ENGINE=INNODB;

-- =========================
-- DETALLE RESERVA
-- =========================
CREATE TABLE detallereserva(
    idDetalleReserva    INT AUTO_INCREMENT NOT NULL,
    idHabitacion        INT NOT NULL,
    idReserva           INT NOT NULL,
    idTarifa            INT NOT NULL,
    cantidadPersonas    INT NOT NULL,
    precioAplicado      DECIMAL(10,2) NOT NULL,
    fechaEntrada        DATETIME NOT NULL,
    fechaSalida         DATETIME NOT NULL,
    iva                 DECIMAL(10,2) NOT NULL,
    subTotal            DECIMAL(10,2) NOT NULL,
    total               DECIMAL(10,2) NOT NULL,
    estado              TINYINT NOT NULL DEFAULT 1,

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
)ENGINE=INNODB;

-- =========================
-- USERS
-- =========================
CREATE TABLE users(
    id          INT AUTO_INCREMENT NOT NULL,
    name        VARCHAR(100) NOT NULL,
    role        VARCHAR(30) DEFAULT 'user',
    email       VARCHAR(150) NOT NULL,
    password    VARCHAR(255) NOT NULL,
    estado      TINYINT NOT NULL DEFAULT 1,
    image       VARCHAR(255),
    cedula      VARCHAR(20) NULL,

    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
                ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_users 
    PRIMARY KEY(id),

    CONSTRAINT uq_users_email 
    UNIQUE(email),

    CONSTRAINT fk_users_recepcionista
    FOREIGN KEY(cedula) 
    REFERENCES recepcionista(cedula)
)ENGINE=INNODB;


-- =========================
-- INSERTS
-- =========================

-- TIPO CLIENTE
INSERT INTO tipocliente(nombreTipoC, descripcion, descuentoBase)
VALUES
('Regular',     'Cliente regular sin descuento',     0.00),
('VIP',         'Cliente VIP con descuento especial', 15.00),
('Empresarial', 'Cliente corporativo',               10.00);

-- CLIENTE
INSERT INTO cliente(cedula, idTipoCliente, nombre, apellidos, telefono, direccion)
VALUES
('10101010', 1, 'Juan',   'Perez Mora',    '8888-1111', 'San Jose, Costa Rica'),
('20202020', 2, 'Maria',  'Lopez Salas',   '8888-2222', 'Heredia, Costa Rica'),
('30303030', 3,'Carlos', 'Ramirez Vega',  '8888-3333', 'Alajuela, Costa Rica'),
('40404040', 1, 'Laura',  'Jimenez Soto',  '8888-4444', 'Cartago, Costa Rica'),
('50505050', 2, 'Pedro',  'Castro Nunez',  '8888-5555', 'Limon, Costa Rica');

-- TIPO HABITACION
INSERT INTO tipohabitacion(nombreTipoHab, descripcion, capacidadMaxima)
VALUES
('Sencilla', 'Habitacion con una cama individual',       1),
('Doble',    'Habitacion con dos camas matrimoniales',   2),
('Suite',    'Habitacion de lujo con todas las amenidades', 4);

-- HABITACION
INSERT INTO habitacion(idTipoHab, numeroHabitacion)
VALUES
(1, '101'),
(1, '102'),
(1, '103'),
(2, '201'),
(2, '202'),
(2, '203'),
(3, '301'),
(3, '302');

-- RECEPCIONISTA
INSERT INTO recepcionista(cedula, nombre, apellidos, telefono, correo)
VALUES
('504470975', 'Kelvin',  'Garcia Medrano', '8888-0001', 'kelvin@hotel.com'),
('112340001', 'Gerald',  'Araya Jimenez',  '8888-0002', 'gerald@hotel.com'),
('223450002', 'Andy',    'Alvarado',       '8888-0003', 'andy@hotel.com');

-- USERS
INSERT INTO users(name, role, email, password, cedula,image)
VALUES
('Kelvin Garcia Medrano', 'Administrador',          'kelvin@hotel.com',   '', '504470975', '82cd4330-57c6-4ad7-97e7-0dd1d0f3db46_kelvinperfil.jpg'),
('Melissa Tijerino',      'Administrador',          'melissa@hotel.com',  '', NULL, '10febf7d-34f9-4613-91ea-b5dfd46711e6_Melissa.png'),
('Gerald Araya Jimenez',  'Recepcionista',  'gerald@hotel.com',   '', '112340001', '643e8b36-2515-4635-ad4b-e98e26cc8653_Gerald.png'),
('Andy Alvarado',         'Recepcionista',  'andy@hotel.com',     '', '223450002', '6a85f430-85dd-43c2-873e-e7550c764d39_Andy.png');


-- TARIFA
INSERT INTO tarifa(idTipoHabitacion, precioBase, nombreTarifa, fechaInicio, fechaFin, descripcion)
VALUES
(1, 35000, 'Temporada Baja Sencilla',  '2026-01-01', '2026-06-30', 'Tarifa para habitacion sencilla en temporada baja'),
(1, 45000, 'Temporada Alta Sencilla',  '2026-07-01', '2026-12-31', 'Tarifa para habitacion sencilla en temporada alta'),
(2, 55000, 'Temporada Baja Doble',     '2026-01-01', '2026-06-30', 'Tarifa para habitacion doble en temporada baja'),
(2, 70000, 'Temporada Alta Doble',     '2026-07-01', '2026-12-31', 'Tarifa para habitacion doble en temporada alta'),
(3, 75000, 'Temporada Baja Suite',     '2026-01-01', '2026-06-30', 'Tarifa para suite en temporada baja'),
(3, 95000, 'Temporada Alta Suite',     '2026-07-01', '2026-12-31', 'Tarifa para suite en temporada alta');

-- RESERVA
INSERT INTO reserva(idRecepcionista, idCliente, fechaReserva, estadoReserva, iva, subTotal, total)
VALUES
('504470975', '10101010', NOW(), 'Confirmada', 4550.00,  35000.00, 39550.00),
('112340001', '20202020', NOW(), 'Pendiente',  7150.00,  55000.00, 62150.00),
('223450002', '30303030', NOW(), 'Confirmada', 9750.00,  75000.00, 84750.00),
('504470975', '40404040', NOW(), 'Cancelada',  5850.00,  45000.00, 50850.00),
('112340001', '50505050', NOW(), 'Confirmada', 9100.00,  70000.00, 79100.00);

-- DETALLE RESERVA
INSERT INTO detallereserva(idHabitacion, idReserva, idTarifa, cantidadPersonas, precioAplicado, fechaEntrada, fechaSalida, iva, subTotal, total)
VALUES
(1, 1, 1, 1, 35000.00, '2026-05-10 14:00:00', '2026-05-12 12:00:00', 4550.00,  35000.00, 39550.00),
(4, 2, 3, 2, 55000.00, '2026-06-01 14:00:00', '2026-06-05 12:00:00', 7150.00,  55000.00, 62150.00),
(7, 3, 5, 3, 75000.00, '2026-07-15 14:00:00', '2026-07-18 12:00:00', 9750.00,  75000.00, 84750.00),
(2, 4, 2, 1, 45000.00, '2026-08-01 14:00:00', '2026-08-03 12:00:00', 5850.00,  45000.00, 50850.00),
(5, 5, 4, 2, 70000.00, '2026-09-10 14:00:00', '2026-09-13 12:00:00', 9100.00,  70000.00, 79100.00);