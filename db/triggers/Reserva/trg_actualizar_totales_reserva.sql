USE reservasdbV2;
GO

/* Trigger base: trg_actualizar_totales_reserva */
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
