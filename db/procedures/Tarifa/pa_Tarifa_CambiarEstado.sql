USE reservasdbV2;
GO

/* =========================================================
   3. ACTIVAR / DESACTIVAR TARIFA

   @activar:
       1 = activar
       0 = desactivar manualmente
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_CambiarEstado
    @idTarifa INT,
    @activar TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF @activar NOT IN (0, 1)
            THROW 50414, 'El parámetro activar debe ser 0 o 1.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.tarifa WITH (UPDLOCK, HOLDLOCK)
            WHERE idTarifa = @idTarifa
        )
        BEGIN
            THROW 50415, 'La tarifa indicada no existe.', 1;
        END;

        -- ACTIVAR
        IF @activar = 1
        BEGIN

            -- Se conserva la regla que ya tenía el backend:
            -- solo puede activarse dentro del rango de vigencia.
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.tarifa
                WHERE idTarifa = @idTarifa
                  AND fechaInicio <= CAST(GETDATE() AS DATE)
                  AND fechaFin >= CAST(GETDATE() AS DATE)
            )
            BEGIN
                THROW 50416,
                    'La tarifa solo puede activarse si la fecha actual está dentro del rango de vigencia.',
                    1;
            END;

            UPDATE dbo.tarifa
            SET
                estado = 1,
                desactivadaManual = 0
            WHERE idTarifa = @idTarifa;

        END
        ELSE
        BEGIN

            -- DESACTIVACIÓN MANUAL
            UPDATE dbo.tarifa
            SET
                estado = 0,
                desactivadaManual = 1
            WHERE idTarifa = @idTarifa;

        END;

        DECLARE @estadoActual TINYINT;
        DECLARE @manualActual TINYINT;

        SELECT
            @estadoActual = estado,
            @manualActual = desactivadaManual
        FROM dbo.tarifa
        WHERE idTarifa = @idTarifa;

        COMMIT TRANSACTION;

        SELECT
            @idTarifa AS idTarifa,
            @estadoActual AS estado,
            @manualActual AS desactivadaManual,
            CASE
                WHEN @activar = 1
                    THEN 'Tarifa activada correctamente.'
                ELSE
                    'Tarifa desactivada correctamente.'
            END AS mensaje;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
