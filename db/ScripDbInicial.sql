-- =========================
-- BASE DE DATOS
-- =========================
DROP DATABASE IF EXISTS reservasdb;
CREATE DATABASE reservasdb;
USE reservasdb;
CREATE TABLE tipocliente(
	idTipoCliente		INT AUTO_INCREMENT NOT NULL,
    nombreTipoC			VARCHAR(45) NOT NULL,
    descripcion			VARCHAR(100) NOT NULL,
    descuentoBase		DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    estado				TINYINT NOT NULL DEFAULT 1,
    
    CONSTRAINT pk_tipocliente 
    PRIMARY KEY(idTipoCliente)

)ENGINE=INNODB;


CREATE TABLE cliente(
	cedula				VARCHAR(20) NOT NULL,
    idTipoCliente		INT NOT NULL,
    nombre				VARCHAR(45) NOT NULL,
    apellidos			VARCHAR(45) NOT NULL,
    telefono			VARCHAR(20) NOT NULL,
    direccion			VARCHAR(100) NOT NULL,
    estado				TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_cliente 
    PRIMARY KEY(cedula),

    CONSTRAINT fk_cliente_tipocliente 
    FOREIGN KEY(idTipoCliente) 
    REFERENCES tipocliente(idTipoCliente)

)ENGINE=INNODB;


CREATE TABLE tipohabitacion(
	idTipoHabitacion	INT AUTO_INCREMENT NOT NULL,
    nombreTipoHab		VARCHAR(45) NOT NULL,
    descripcion			VARCHAR(100) NOT NULL,
    capacidadMaxima		INT NOT NULL,
    estado				TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_tipohabitacion 
    PRIMARY KEY(idTipoHabitacion)

)ENGINE=INNODB;


CREATE TABLE habitacion(
	idHabitacion		INT AUTO_INCREMENT NOT NULL,
    idTipoHab			INT NOT NULL,
    numeroHabitacion	VARCHAR(45) NOT NULL,
    estado				TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_habitacion 
    PRIMARY KEY(idHabitacion),

    CONSTRAINT fk_habitacion_tipohabitacion 
    FOREIGN KEY(idTipoHab) 
    REFERENCES tipohabitacion(idTipoHabitacion)

)ENGINE=INNODB;


CREATE TABLE recepcionista(
	cedula				VARCHAR(20) NOT NULL,
    nombre				VARCHAR(45) NOT NULL,
    apellidos			VARCHAR(45) NOT NULL,
    telefono			VARCHAR(20) NOT NULL,
    correo				VARCHAR(100) NOT NULL,
    estado				TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_recepcionista 
    PRIMARY KEY(cedula)

)ENGINE=INNODB;


CREATE TABLE reserva(
	idReserva			INT AUTO_INCREMENT NOT NULL,
    idRecepcionista		VARCHAR(20) NOT NULL,
    idCliente			VARCHAR(20) NOT NULL,
    fechaReserva		DATETIME NOT NULL,
    estadoReserva		VARCHAR(25) NOT NULL,
    estado				TINYINT NOT NULL DEFAULT 1,
    iva                 decimal(10,2) NOT NULL,
    subTotal            decimal(10,2) NOT NULL,
    total               decimal(10,2) NOT NULL,

    CONSTRAINT pk_reserva 
    PRIMARY KEY(idReserva),

    CONSTRAINT fk_reserva_recepcionista 
    FOREIGN KEY(idRecepcionista) 
    REFERENCES recepcionista(cedula),

    CONSTRAINT fk_reserva_cliente 
    FOREIGN KEY(idCliente) 
    REFERENCES cliente(cedula)

)ENGINE=INNODB;


CREATE TABLE tarifa(
	idTarifa			INT AUTO_INCREMENT NOT NULL,
    idTipoHabitacion	INT NOT NULL,
    precioBase			DECIMAL(10,2) NOT NULL,
    nombreTarifa		VARCHAR(45) NOT NULL,
    fechaInicio			DATE,
    fechaFin			DATE,
    descripcion         TEXT,
    desactivadaManual   TINYINT NOT NULL DEFAULT 0,
    estado				TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_tarifa 
    PRIMARY KEY(idTarifa),

    CONSTRAINT fk_tarifa_tipohabitacion 
    FOREIGN KEY(idTipoHabitacion) 
    REFERENCES tipohabitacion(idTipoHabitacion)

)ENGINE=INNODB;


CREATE TABLE detallereserva(
	idDetalleReserva	INT AUTO_INCREMENT NOT NULL,
    idHabitacion		INT NOT NULL,
    idReserva			INT NOT NULL,
    idTarifa			INT NOT NULL,
    cantidadPersonas	INT NOT NULL,
    precioAplicado		DECIMAL(10,2) NOT NULL,
    fechaEntrada		DATETIME NOT NULL,
    fechaSalida			DATETIME NOT NULL,
    iva					DECIMAL(10,2) NOT NULL,
    subTotal			DECIMAL(10,2) NOT NULL,
    total				DECIMAL(10,2) NOT NULL,
    estado				TINYINT NOT NULL DEFAULT 1,

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

CREATE TABLE users(
    id              INT AUTO_INCREMENT NOT NULL,
    name            VARCHAR(100) NOT NULL,
    role            VARCHAR(30) DEFAULT 'user',
    email           VARCHAR(150) NOT NULL,
    password        VARCHAR(255) NOT NULL,
    estado          TINYINT NOT NULL DEFAULT 1,
    image           VARCHAR(255),
    cedula          VARCHAR(20) NULL,

    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
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
-- INSERTS DE PRUEBA
-- =========================

INSERT INTO tipocliente(nombreTipoC, descripcion, descuentoBase, estado) VALUES
('Regular', 'Cliente sin descuento especial', 0.00, 1),
('Frecuente', 'Cliente con descuento por visitas recurrentes', 5.00, 1),
('Corporativo', 'Cliente empresarial con tarifa preferencial', 10.00, 1),
('VIP', 'Cliente con beneficios especiales', 15.00, 1);

INSERT INTO cliente(cedula, idTipoCliente, nombre, apellidos, telefono, direccion, estado) VALUES
('101110111', 1, 'Andy', 'Alvarado', '85151145', 'Heredia, Costa Rica', 1),
('202220222', 2, 'Melissa', 'Tijerino', '612458973', 'San José, Costa Rica', 1),
('303330333', 3, 'Gustavo', 'Moya', '74821930', 'Alajuela, Costa Rica', 1),
('404440444', 4, 'Kelvin', 'García', '3055554821', 'Cartago, Costa Rica', 1);

INSERT INTO tipohabitacion(nombreTipoHab, descripcion, capacidadMaxima, estado) VALUES
('Simple', 'Habitación para una persona', 1, 1),
('Doble', 'Habitación para dos personas', 2, 1),
('Familiar', 'Habitación amplia para familia', 4, 1),
('Suite', 'Habitación premium con mayor comodidad', 3, 1),
('Ejecutiva', 'Habitación para viajes de negocio', 2, 1);

INSERT INTO habitacion(idTipoHab, numeroHabitacion, estado) VALUES
(1, '101', 1),
(1, '102', 1),
(2, '201', 1),
(2, '202', 1),
(3, '301', 1),
(4, '401', 1),
(5, '501', 1);

INSERT INTO recepcionista(cedula, nombre, apellidos, telefono, correo, estado) VALUES
('504470975', 'Kelvin', 'Garcia Medrano', '88880001', 'kelvin@hotel.com', 1),
('112340001', 'Gerald', 'Araya Jimenez', '88880002', 'gerald@hotel.com', 1),
('223450002', 'Andy', 'Alvarado', '85151145', 'andy@hotel.com', 1);

INSERT INTO tarifa(
    idTipoHabitacion,
    precioBase,
    nombreTarifa,
    fechaInicio,
    fechaFin,
    descripcion,
    desactivadaManual,
    estado
) VALUES
(3, 65000.00, 'Tarifa Familiar', '2026-01-01', '2026-12-31', 'Tarifa para habitaciones familiares', 0, 1),
(4, 85000.00, 'Tarifa Suite Premium', '2026-01-01', '2026-12-31', 'Tarifa especial para suite premium', 0, 1),
(5, 55000.00, 'Tarifa Ejecutiva', '2026-01-01', '2026-12-31', 'Tarifa para habitación ejecutiva', 0, 1),
-- Tarifas futuras
(2, 35000.00, 'Tarifa Temporada Baja', '2026-09-01', '2026-10-31', 'Tarifa promocional para temporada baja', 0, 2),
(4, 95000.00, 'Tarifa Navideña', '2026-12-01', '2026-12-31', 'Tarifa especial para temporada navideña', 0, 2),
-- Tarifas permanentes (sin fechas)
(1, 22000.00, 'Tarifa Base Permanente Simple', NULL, NULL, 'Tarifa permanente para habitación simple', 0, 1),
(2, 38000.00, 'Tarifa Base Permanente Doble', NULL, NULL, 'Tarifa permanente para habitación doble', 0, 1);

INSERT INTO reserva(idRecepcionista, idCliente, fechaReserva, estadoReserva, estado, iva, subTotal, total) VALUES
('504470975', '101110111', '2026-06-14 09:30:00', 'Confirmada', 1, 5200.00, 40000.00, 45200.00),
('112340001', '202220222', '2026-06-14 10:15:00', 'Pendiente', 1, 8450.00, 65000.00, 73450.00),
('223450002', '303330333', '2026-06-14 11:00:00', 'Confirmada', 1, 11050.00, 85000.00, 96050.00),
('504470975', '404440444', '2026-06-14 12:20:00', 'Cancelada', 0, 3250.00, 25000.00, 28250.00);

INSERT INTO detallereserva(
    idHabitacion,
    idReserva,
    idTarifa,
    cantidadPersonas,
    precioAplicado,
    fechaEntrada,
    fechaSalida,
    iva,
    subTotal,
    total,
    estado
) VALUES
(3, 1, 2, 2, 40000.00, '2026-06-20 14:00:00', '2026-06-21 11:00:00', 5200.00, 40000.00, 45200.00, 1),
(5, 2, 3, 4, 65000.00, '2026-06-22 14:00:00', '2026-06-23 11:00:00', 8450.00, 65000.00, 73450.00, 1),
(6, 3, 4, 3, 85000.00, '2026-06-25 14:00:00', '2026-06-26 11:00:00', 11050.00, 85000.00, 96050.00, 1),
(1, 4, 1, 1, 25000.00, '2026-06-28 14:00:00', '2026-06-29 11:00:00', 3250.00, 25000.00, 28250.00, 0);

-- USERS
INSERT INTO users(name, role, email, password, cedula,image)
VALUES
('Kelvin Garcia Medrano', 'Administrador',          'kelvin@hotel.com',   '', '504470975', '82cd4330-57c6-4ad7-97e7-0dd1d0f3db46_kelvinperfil.jpg'),
('Melissa Tijerino',      'Administrador',          'melissa@hotel.com',  '', NULL, '10febf7d-34f9-4613-91ea-b5dfd46711e6_Melissa.png'),
('Gerald Araya Jimenez',  'Recepcionista',  'gerald@hotel.com',   '', '112340001', '643e8b36-2515-4635-ad4b-e98e26cc8653_Gerald.png'),
('Andy Alvarado',         'Recepcionista',  'andy@hotel.com',     '', '223450002', '6a85f430-85dd-43c2-873e-e7550c764d39_Andy.png');