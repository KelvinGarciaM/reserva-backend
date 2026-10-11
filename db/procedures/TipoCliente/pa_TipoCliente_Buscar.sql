USE reservasdbV2;
GO

/* =========================================================
   7. BUSCAR TIPOS DE CLIENTE
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Buscar
    @busqueda VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        idTipoCliente,
        nombreTipoC,
        descripcion,
        descuentoBase,
        estado
    FROM dbo.tipocliente
    WHERE
        CAST(idTipoCliente AS VARCHAR(20)) LIKE @busqueda + '%'
        OR nombreTipoC LIKE @busqueda + '%'
        OR descripcion LIKE @busqueda + '%'
    ORDER BY nombreTipoC;
END;
GO
