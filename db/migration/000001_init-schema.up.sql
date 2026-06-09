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


-- CREATE TABLE users(
-- 	id				INT AUTO_INCREMENT NOT NULL,
--     name			VARCHAR(100) NOT NULL,
--     role			VARCHAR(30) DEFAULT 'user',
--     email			VARCHAR(150) NOT NULL,
--     password		VARCHAR(255) NOT NULL,
--     estado			TINYINT NOT NULL DEFAULT 1,
--     image			VARCHAR(255),

--     created_at		TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     updated_at		TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
--     				ON UPDATE CURRENT_TIMESTAMP,

--     CONSTRAINT pk_users 
--     PRIMARY KEY(id),

--     CONSTRAINT uq_users_email 
--     UNIQUE(email)

-- )ENGINE=INNODB;




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