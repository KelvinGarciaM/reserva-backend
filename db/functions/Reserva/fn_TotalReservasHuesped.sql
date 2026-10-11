USE reservasdbV2;
GO

-- SELECT *
-- FROM dbo.fn_HistorialReservasCliente('10101010')
-- ORDER BY fechaReserva DESC;


/* =========================================================
   FUNCIÓN: fn_TotalReservasHuesped

   Descripción:
   Devuelve la cantidad de reservas activas y no canceladas
   asociadas a un cliente.

   Importancia:
   Puede utilizarse para identificar clientes frecuentes,
   generar estadísticas y apoyar futuras reglas comerciales.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_TotalReservasHuesped
(
    @cedula VARCHAR(20)
)
RETURNS INT
AS
BEGIN
    DECLARE @total INT;

    SELECT @total = COUNT(*)
    FROM dbo.reserva
    WHERE idCliente = @cedula
      AND estado = 1
      AND estadoReserva <> 'Cancelada';

    RETURN ISNULL(@total, 0);
END;
GO
