USE reservasdbV2;
GO

/* ---------- 11.7 Procedimiento: registrar inicio/cierre de sesión ----------
   La aplicación lo llama después de conectarse con el login del motor
   (LOGIN) y al cerrar sesión (LOGOUT). El rol se detecta automáticamente. */
CREATE OR ALTER PROCEDURE dbo.pa_Auditoria_RegistrarSesion
    @accion     VARCHAR(20),
    @usuarioApp VARCHAR(150) = NULL,
    @ipOrigen   VARCHAR(45)  = NULL,
    @detalle    VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @accion NOT IN ('LOGIN','LOGOUT','LOGIN_FALLIDO')
        THROW 51101, 'Acción de sesión no válida. Use LOGIN, LOGOUT o LOGIN_FALLIDO.', 1;

    INSERT INTO dbo.auditoriaSesion (rolBD, accion, usuarioApp, ipOrigen, detalle)
    VALUES
    (
        CASE
            WHEN IS_MEMBER('rol_admin_hotel') = 1 THEN 'ADMIN'
            WHEN IS_MEMBER('rol_recepcion')   = 1 THEN 'RECEPCION'
            ELSE 'OTRO'
        END,
        @accion, @usuarioApp, @ipOrigen, @detalle
    );

    SELECT SCOPE_IDENTITY() AS idAuditoriaSesion, 'Sesión registrada.' AS mensaje;
END;
GO
