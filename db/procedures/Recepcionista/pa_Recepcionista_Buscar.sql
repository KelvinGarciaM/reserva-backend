USE reservasdbV2;
GO

/* ============================================
   7. BUSCAR
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_Buscar
    @busqueda VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SET @busqueda = LTRIM(RTRIM(@busqueda));

    SELECT
        cedula,
        nombre,
        apellidos,
        telefono,
        correo,
        estado
    FROM dbo.recepcionista
    WHERE
        cedula LIKE @busqueda + '%'
        OR nombre LIKE @busqueda + '%'
        OR apellidos LIKE @busqueda + '%'
        OR telefono LIKE @busqueda + '%'
        OR correo LIKE @busqueda + '%'
    ORDER BY nombre, apellidos;
END;
GO
