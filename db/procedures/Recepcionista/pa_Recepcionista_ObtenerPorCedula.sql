USE reservasdbV2;
GO

/* ============================================
   2. OBTENER POR CÉDULA
   ============================================ */

CREATE OR ALTER PROCEDURE dbo.pa_Recepcionista_ObtenerPorCedula
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SET @cedula = LTRIM(RTRIM(@cedula));

    IF @cedula IS NULL OR @cedula = ''
    BEGIN
        THROW 50202,
            'La cédula es obligatoria.',
            1;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.recepcionista
        WHERE cedula = @cedula
    )
    BEGIN
        THROW 50203,
            'El recepcionista solicitado no existe.',
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
    WHERE cedula = @cedula;
END;
GO
