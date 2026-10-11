USE reservasdbV2;
GO

CREATE OR ALTER VIEW dbo.vw_Usuario_Detalle
AS
SELECT
    u.id,
    u.name,
    u.role,
    u.email,
    u.image,
    u.cedula,
    u.created_at,
    u.updated_at,
    u.estado,

    CASE
        WHEN r.cedula IS NULL THEN NULL
        ELSE CONCAT(r.nombre, ' ', r.apellidos)
    END AS nombreRecepcionista

FROM dbo.users AS u

LEFT JOIN dbo.recepcionista AS r
    ON r.cedula = u.cedula;
GO