USE reservasdbV2;
GO

/* Trigger base: trg_validar_capacidad_habitacion */
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
