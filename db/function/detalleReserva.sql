/* =========================================================
   FUNCIÓN: fn_NochesEstancia

   Descripción:
   Calcula la cantidad de noches comprendidas entre una fecha
   de entrada y una fecha de salida.

   Ejemplo:
   09/10/2026 -> 12/10/2026 = 3 noches.

   Importancia:
   Permite reutilizar el cálculo de noches en consultas,
   reportes y cálculos relacionados con una estadía.
   ========================================================= */

CREATE OR ALTER FUNCTION dbo.fn_NochesEstancia
(
    @fechaEntrada DATE,
    @fechaSalida DATE
)
RETURNS INT
AS
BEGIN
    IF @fechaEntrada IS NULL
       OR @fechaSalida IS NULL
       OR @fechaSalida <= @fechaEntrada
    BEGIN
        RETURN 0;
    END;

    RETURN DATEDIFF(
        DAY,
        @fechaEntrada,
        @fechaSalida
    );
END;
GO

-- Ejemplo:
-- SELECT
--     idDetalleReserva,
--     dbo.fn_NochesEstancia(fechaEntrada, fechaSalida) AS noches
-- FROM dbo.detallereserva;