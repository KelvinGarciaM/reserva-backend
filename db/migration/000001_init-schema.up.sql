CREATE TABLE tipoCliente (
    idTipoCliente INT AUTO_INCREMENT PRIMARY KEY,
    nombreTipoC VARCHAR(45) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    descuentoBase DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    estado TINYINT NOT NULL DEFAULT 1
) ENGINE = InnoDB;

CREATE TABLE Cliente (
    cedula INT PRIMARY KEY,
    idTipoCliente INT NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    apellidos VARCHAR(45) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT FK_Cliente_tipoCliente
        FOREIGN KEY (idTipoCliente)
        REFERENCES tipoCliente(idTipoCliente)
) ENGINE = InnoDB;

CREATE TABLE Recepcionista (
    cedula INT PRIMARY KEY,
    nombre VARCHAR(45) NOT NULL,
    apellidos VARCHAR(45) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1
) ENGINE = InnoDB;

CREATE TABLE Reserva (
    idReserva INT AUTO_INCREMENT PRIMARY KEY,
    idRecepcionista INT NOT NULL,
    idCliente INT NOT NULL,
    fechaReserva DATETIME NOT NULL,
    fechaEntrada DATE NOT NULL,
    fechaSalida DATE NOT NULL,
    cantidadNoches INT NOT NULL,
    horaCheckIn TIME NOT NULL,
    horaCheckOut TIME NOT NULL,
    estadoReserva VARCHAR(25) NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT FK_Reserva_Recepcionista
        FOREIGN KEY (idRecepcionista)
        REFERENCES Recepcionista(cedula),

    CONSTRAINT FK_Reserva_Cliente
        FOREIGN KEY (idCliente)
        REFERENCES Cliente(cedula)
) ENGINE = InnoDB;

CREATE TABLE TipoHabitacion (
    idTipoHabitacion INT AUTO_INCREMENT PRIMARY KEY,
    nombreTipoHab VARCHAR(45) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    capacidadMaxima INT NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1
) ENGINE = InnoDB;

CREATE TABLE Habitacion (
    idHabitacion INT AUTO_INCREMENT PRIMARY KEY,
    idTipoHab INT NOT NULL,
    numeroHabitacion VARCHAR(45) NOT NULL,
    estadoHabitacion VARCHAR(45) NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT FK_Habitacion_TipoHabitacion
        FOREIGN KEY (idTipoHab)
        REFERENCES TipoHabitacion(idTipoHabitacion)
) ENGINE = InnoDB;

CREATE TABLE Tarifa (
    idTarifa INT AUTO_INCREMENT PRIMARY KEY,
    idTipoHabitacion INT NOT NULL,
    precioBase DECIMAL(10,2) NOT NULL,
    nombreTarifa VARCHAR(45) NOT NULL,
    fechaInicio DATE NULL,
    fechaFin DATE NULL,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT FK_Tarifa_TipoHabitacion
        FOREIGN KEY (idTipoHabitacion)
        REFERENCES TipoHabitacion(idTipoHabitacion),

    CONSTRAINT FK_Tarifa_TipoCliente
        FOREIGN KEY (idTipoCliente)
        REFERENCES tipoCliente(idTipoCliente)
) ENGINE = InnoDB;

CREATE TABLE detalleReserva (
    idDetalleReserva INT AUTO_INCREMENT PRIMARY KEY,
    idHabitacion INT NOT NULL,
    idReserva INT NOT NULL,
    idTarifa INT NOT NULL,
    cantidadPersonas INT NOT NULL,
    precioAplicado DECIMAL(10,2) NOT NULL,
    subTotal DECIMAL(10,2) NOT NULL,
    estado TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT FK_DetalleReserva_Habitacion
        FOREIGN KEY (idHabitacion)
        REFERENCES Habitacion(idHabitacion),

    CONSTRAINT FK_DetalleReserva_Reserva
        FOREIGN KEY (idReserva)
        REFERENCES Reserva(idReserva),

    CONSTRAINT FK_DetalleReserva_Tarifa
        FOREIGN KEY (idTarifa)
        REFERENCES Tarifa(idTarifa)
) ENGINE = InnoDB;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(30) DEFAULT 'user',
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    remember_token VARCHAR(255)
) ENGINE=InnoDB;