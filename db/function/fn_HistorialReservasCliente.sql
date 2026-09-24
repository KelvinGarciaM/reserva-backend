-- =========================================================
-- FUNCIÓN DE TABLA CON VARIAS INSTRUCCIONES
-- fn_HistorialReservasCliente
-- Devuelve el historial completo de reservas de un cliente
-- =========================================================
--
-- DESCRIPCIÓN:
-- Función de tabla (MSTVF) que recibe la cédula de un cliente
-- y devuelve el historial completo de sus reservas, incluyendo
-- habitación, tipo de habitación, tarifa aplicada, fechas de
-- entrada/salida y montos de subtotal, IVA y total.
--
-- IMPORTANCIA:
-- Centraliza la consulta del historial de un cliente en un solo
-- punto reutilizable, evitando reescribir los JOINs entre cliente,
-- reserva, detallereserva, habitacion y tarifa en cada módulo.
-- Facilita la atención al cliente, la identificación de clientes
-- frecuentes para descuentos, la auditoría de reservas pasadas
-- y la generación de reportes combinados con otras consultas.
-- =========================================================

CREATE FUNCTION fn_HistorialReservasCliente
(
    @cedulaCliente VARCHAR(20)
)
RETURNS @Historial TABLE
(
    idReserva         INT,
    fechaReserva      DATETIME,
    estadoReserva     VARCHAR(25),
    numeroHabitacion  VARCHAR(45),
    nombreTipoHab     VARCHAR(45),
    nombreTarifa      VARCHAR(45),
    fechaEntrada      DATETIME,
    fechaSalida       DATETIME,
    precioAplicado    DECIMAL(10,2),
    subTotal          DECIMAL(10,2),
    iva               DECIMAL(10,2),
    total             DECIMAL(10,2)
)
AS
BEGIN
    INSERT INTO @Historial
    (
        idReserva,
        fechaReserva,
        estadoReserva,
        numeroHabitacion,
        nombreTipoHab,
        nombreTarifa,
        fechaEntrada,
        fechaSalida,
        precioAplicado,
        subTotal,
        iva,
        total
    )
    SELECT
        r.idReserva,
        r.fechaReserva,
        r.estadoReserva,
        h.numeroHabitacion,
        th.nombreTipoHab,
        t.nombreTarifa,
        dr.fechaEntrada,
        dr.fechaSalida,
        dr.precioAplicado,
        dr.subTotal,
        dr.iva,
        dr.total
    FROM reserva r
    INNER JOIN detallereserva dr ON dr.idReserva = r.idReserva
    INNER JOIN habitacion h ON h.idHabitacion = dr.idHabitacion
    INNER JOIN tipohabitacion th ON th.idTipoHabitacion = h.idTipoHab
    INNER JOIN tarifa t ON t.idTarifa = dr.idTarifa
    WHERE r.idCliente = @cedulaCliente AND r.estado = 1 AND dr.estado = 1
    ORDER BY r.fechaReserva DESC;
    RETURN;
END;
GO

SELECT * FROM fn_HistorialReservasCliente('10101010');

-- FUNCION DE TABLA:
CREATE OR ALTER FUNCTION dbo.fn_HabSinReservas( @nuevaEntrada DATETIME, @nuevaSalida DATETIME)
RETURNS @resultado TABLE
(
	idHabitacion INT,
	numeroHabitacion VARCHAR(45)
)
AS
BEGIN
	INSERT INTO @resultado (idHabitacion, numeroHabitacion)
	SELECT h.idHabitacion, h.numeroHabitacion
	FROM dbo.habitacion AS h
	WHERE NOT EXISTS( -- No exista ninguna fila q cumpla estas condiciones
		SELECT d.idHabitacion
		FROM dbo.detallereserva AS d
		WHERE d.idHabitacion = h.idHabitacion AND
		@nuevaEntrada < d.fechaSalida AND-- Ej 22 < 24
		@nuevaSalida > d.fechaEntrada AND -- Ej 26 > 20
		d.estado = 1
	)

	RETURN;
END;
GO

SELECT *
FROM dbo.fn_HabSinReservas('2026-06-03', '2026-06-10');

-- DESCRIPCION: La función fn_HabSinReservas recibe una fecha de entrada y una de salida, y devuelve el ID y el número de las 
-- habitaciones que no tienen un detalle de reserva activo que se cruce con ese período.

-- JUSTIFICACION: Permite consultar qué habitaciones se pueden ofrecer para las fechas solicitadas y ayuda a evitar que se intente
-- reservar una habitación ya ocupada.

---------------------------Funciónes de tabla en línea--------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_HabitacionesDisponibles
(
    @fechaEntrada DATETIME,
    @fechaSalida  DATETIME
)
RETURNS TABLE
AS
RETURN
(
    SELECT h.idHabitacion,
           h.numeroHabitacion,
           th.nombreTipoHab,
           th.capacidadMaxima
    FROM dbo.habitacion h
    INNER JOIN dbo.tipohabitacion th ON h.idTipoHab = th.idTipoHabitacion
    WHERE h.estado = 1
      AND th.estado = 1
      AND NOT EXISTS (
            SELECT 1
            FROM dbo.detallereserva dr
            INNER JOIN dbo.reserva r ON dr.idReserva = r.idReserva
            WHERE dr.idHabitacion = h.idHabitacion
              AND dr.estado = 1
              AND r.estado = 1
              AND dr.fechaEntrada < @fechaSalida
              AND dr.fechaSalida  > @fechaEntrada
      )
);
GO

-- Uso
SELECT * FROM dbo.fn_HabitacionesDisponibles('2026-10-10', '2026-10-13');

/*Descripción: devuelve las habitaciones activas que no tienen ninguna reserva activa
que se cruce con el rango de fechas indicado, junto con su tipo y capacidad máxima.*/

/*Justificación: es la consulta que el recepcionista necesita antes de crear cualquier
reserva. Evita que una misma habitación se reserve dos veces para fechas que se traslapan,
que es el error más grave que puede tener un sistema de hotel. Además, al mostrar la capacidad máxima, ayuda a elegir una habitación adecuada para la cantidad de personas.*/

GO
CREATE OR ALTER FUNCTION dbo.fn_TarifasVigentes
(
    @fecha DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT t.idTarifa,
           t.nombreTarifa,
           th.idTipoHabitacion,
           th.nombreTipoHab,
           t.precioBase,
           t.fechaInicio,
           t.fechaFin
    FROM dbo.tarifa t
    INNER JOIN dbo.tipohabitacion th ON t.idTipoHabitacion = th.idTipoHabitacion
    WHERE t.estado = 1
      AND t.desactivadaManual = 0
      AND (t.fechaInicio IS NULL OR t.fechaInicio <= @fecha)
      AND (t.fechaFin    IS NULL OR t.fechaFin    >= @fecha)
);
GO

-- Uso
SELECT * FROM dbo.fn_TarifasVigentes('2026-12-24');

/*Descripción: devuelve las tarifas que aplican en una fecha específica para cada tipo
de habitación: tarifas activas, no desactivadas manualmente y cuya fecha de inicio y fin
incluyen esa fecha. Si una tarifa no tiene fecha de inicio o de fin, se toma como abierta
por ese lado.

Justificación: el precio de una habitación depende de la temporada o promoción vigente,
y el campo precioAplicado de detallereserva debe salir de la tarifa correcta. Esta función
centraliza esa regla en un solo lugar, así no hay que repetir las mismas condiciones en cada
consulta o procedimiento, y se reduce el riesgo de cobrar con una tarifa vencida o desactivada.*/


--------------------------Funciones escalares-----------------------------------

CREATE FUNCTION dbo.fn_NochesEstancia (@fechaEntrada DATE, @fechaSalida DATE)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(DAY, @fechaEntrada, @fechaSalida);
END;
/*Muetra las noches totales que se va quedar un cliente de una reserva*/
SELECT idDetalleReserva,
       dbo.fn_NochesEstancia(FechaEntrada, FechaSalida) AS Noches
FROM dbo.detallereserva
---------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_TotalReservasHuesped (@cedula VARCHAR(20))
RETURNS INT
AS
BEGIN
    DECLARE @total INT;

    SELECT @total = COUNT(*)
    FROM dbo.Reserva
    WHERE idCliente = @cedula
      AND EstadoReserva <> 'Cancelada';

    RETURN ISNULL(@total, 0);
END;
GO
--Muestra el total de reversas de los clientes, menos las canceladas
SELECT cedula,
       dbo.fn_TotalReservasHuesped(cedula) AS TotalReservas
FROM dbo.cliente;



