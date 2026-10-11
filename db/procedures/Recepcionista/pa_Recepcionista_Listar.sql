USE reservasdbV2;
GO

/* ============================================
   1. LISTAR RECEPCIONISTAS
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Listar
    @soloActivos TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @soloActivos IS NOT NULL
       AND @soloActivos NOT IN (0, 1)
    BEGIN
        THROW 50201,
            'El parámetro soloActivos debe ser 0, 1 o NULL.',
            1;
    END;

    SELECT
        cedula,
        nombre,
        apellidos,
        telefono,
        correo,
        estado
    FROM dbo.recepcionista
    WHERE @soloActivos IS NULL
       OR estado = @soloActivos
    ORDER BY nombre, apellidos;
END;
GO
