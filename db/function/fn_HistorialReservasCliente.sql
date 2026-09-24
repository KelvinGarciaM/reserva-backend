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
