CREATE DATABASE hotel_reservas;
USE hotel_reservas;

-- =========================
-- TIPO CLIENTE
-- =========================
CREATE TABLE tipocliente(
	idTipoCliente		INT AUTO_INCREMENT NOT NULL,
    nombreTipoC			VARCHAR(45) NOT NULL,
    descripcion			VARCHAR(100) NOT NULL,
    descuentoBase		DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    estado				TINYINT NOT NULL DEFAULT 1,
    
    CONSTRAINT pk_tipocliente 
    PRIMARY KEY(idTipoCliente)

)ENGINE=INNODB;

-- =========================
-- CLIENTE
-- =========================
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

-- =========================
-- TIPO HABITACION
-- =========================
CREATE TABLE tipohabitacion(
	idTipoHabitacion	INT AUTO_INCREMENT NOT NULL,
    nombreTipoHab		VARCHAR(45) NOT NULL,
    descripcion			VARCHAR(100) NOT NULL,
    capacidadMaxima		INT NOT NULL,
    estado				TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT pk_tipohabitacion 
    PRIMARY KEY(idTipoHabitacion)

)ENGINE=INNODB;

-- =========================
-- HABITACION
-- =========================
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

-- =========================
-- RECEPCIONISTA
-- =========================
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

-- =========================
-- RESERVA
-- =========================
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

-- =========================
-- TARIFA
-- =========================
CREATE TABLE tarifa(
	idTarifa			INT AUTO_INCREMENT NOT NULL,
    idTipoHabitacion	INT NOT NULL,
    precioBase			DECIMAL(10,2) NOT NULL,
    nombreTarifa		VARCHAR(45) NOT NULL,
    fechaInicio			DATE,
    fechaFin			DATE,
    descripcion         TEXT,
    desactivadaManual   TINYINT DEFAULT 0,
    estado				TINYINT NOT NULL DEFAULT 1,

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

-- =========================
-- USERS
-- =========================
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
-- INSERTS
-- =========================

-- TIPO CLIENTE
INSERT INTO tipocliente(nombreTipoC, descripcion, descuentoBase)
VALUES
('Regular', 'Cliente regular', 0.00),
('VIP', 'Cliente VIP', 15.00),
('Empresarial', 'Cliente corporativo', 10.00);

-- CLIENTE
INSERT INTO cliente(
    cedula,
    idTipoCliente,
    nombre,
    apellidos,
    telefono,
    direccion
)
VALUES
('10101010', 1, 'Juan', 'Perez', '8888-1111', 'San Jose'),
('20202020', 2, 'Maria', 'Lopez', '8888-2222', 'Heredia'),
('30303030', 3, 'Carlos', 'Ramirez', '8888-3333', 'Alajuela');

-- TIPO HABITACION
INSERT INTO tipohabitacion(
    nombreTipoHab,
    descripcion,
    capacidadMaxima
)
VALUES
('Sencilla', 'Una cama individual', 1),
('Doble', 'Dos camas matrimoniales', 2),
('Suite', 'Habitacion de lujo', 4);

-- HABITACION
INSERT INTO habitacion(
    idTipoHab,
    numeroHabitacion
)
VALUES
(1, '101'),
(1, '102'),
(2, '201'),
(2, '202'),
(3, '301');

-- RECEPCIONISTA
INSERT INTO recepcionista(
    cedula,
    nombre,
    apellidos,
    telefono,
    correo
)
VALUES
('11111111', 'Ana', 'Gomez', '8888-4444', 'ana@hotel.com'),
('22222222', 'Luis', 'Mora', '8888-5555', 'luis@hotel.com');

-- RESERVA
INSERT INTO reserva(
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
    '11111111',
    '10101010',
    NOW(),
    'Activa',
    4550.00,
    35000.00,
    39550.00
),
(
    '22222222',
    '20202020',
    NOW(),
    'Pendiente',
    7150.00,
    55000.00,
    62150.00
);

-- TARIFA
INSERT INTO tarifa(
    idTipoHabitacion,
    precioBase,
    nombreTarifa,
    fechaInicio,
    fechaFin
)
VALUES
(1, 35000, 'Temporada Baja', '2026-01-01', '2026-06-30'),
(2, 55000, 'Temporada Baja', '2026-01-01', '2026-06-30'),
(3, 95000, 'Temporada Alta', '2026-07-01', '2026-12-31');

-- DETALLE RESERVA
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
    total
)
VALUES
(
    1,
    1,
    1,
    1,
    35000,
    '2026-05-10 14:00:00',
    '2026-05-12 12:00:00',
    4550,
    35000,
    39550
),
(
    3,
    2,
    2,
    2,
    55000,
    '2026-06-01 14:00:00',
    '2026-06-05 12:00:00',
    7150,
    55000,
    62150
);