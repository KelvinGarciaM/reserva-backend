USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Reserva_Detalle
AS
SELECT
    r.idReserva,
    r.idRecepcionista,
    r.idCliente,

    CONCAT(c.nombre, ' ', c.apellidos)
        AS nombreCliente,

    CONCAT(re.nombre, ' ', re.apellidos)
        AS nombreRecepcionista,

    r.fechaReserva,
    r.estadoReserva,
    r.estado,
    r.iva,
    r.subTotal,
    r.total

FROM dbo.reserva AS r

INNER JOIN dbo.cliente AS c
    ON r.idCliente = c.cedula

INNER JOIN dbo.recepcionista AS re
    ON r.idRecepcionista = re.cedula;
GO