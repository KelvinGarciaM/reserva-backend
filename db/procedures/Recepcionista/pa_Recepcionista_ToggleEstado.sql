USE reservasdbV2;
GO

/* ============================================
   6. ACTIVAR / DESACTIVAR
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_ToggleEstado
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.recepcionista
        WHERE cedula = @cedula
    )
    BEGIN
        THROW 50214,
            'El recepcionista no existe.',
            1;
    END;

    UPDATE dbo.recepcionista
    SET estado =
        CASE
            WHEN estado = 1 THEN 0
            ELSE 1
        END
    WHERE cedula = @cedula;

    SELECT
        cedula,
        estado,
        'Estado actualizado exitosamente.' AS mensaje
    FROM dbo.recepcionista
    WHERE cedula = @cedula;
END;
GO
