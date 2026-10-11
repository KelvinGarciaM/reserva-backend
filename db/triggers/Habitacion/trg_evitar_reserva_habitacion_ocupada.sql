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
