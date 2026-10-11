USE reservasdbV2;
GO

/* =========================================================
   1. LISTAR TIPOS DE CLIENTE
   @soloActivos:
       NULL = todos
       1    = activos
       0    = inactivos
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_TipoCliente_Listar
    @soloActivos TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF @soloActivos IS NOT NULL
           AND @soloActivos NOT IN (0, 1)
        BEGIN
            THROW 50101,
                'El parámetro soloActivos debe ser 0, 1 o NULL.',
                1;
        END;

        SELECT
            idTipoCliente,
            nombreTipoC,
            descripcion,
            descuentoBase,
            estado
        FROM dbo.tipocliente
        WHERE @soloActivos IS NULL
           OR estado = @soloActivos
        ORDER BY nombreTipoC ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
