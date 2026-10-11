USE reservasdbV2;
GO

/* =========================================================
   4. SINCRONIZAR VIGENCIA AUTOMÁTICAMENTE

   Reemplaza:
   - UpdateTarifasVencidasAutomatico
   - ActivarTarifasVigentesAutomatico
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.pa_Tarifa_SincronizarVigencia
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        DECLARE @hoy DATE = CAST(GETDATE() AS DATE);
        DECLARE @vencidas INT;
        DECLARE @activadas INT;

        BEGIN TRANSACTION;

        -- Tarifas cuya vigencia terminó
        UPDATE dbo.tarifa
        SET
            estado = 0,
            desactivadaManual = 0
        WHERE fechaFin IS NOT NULL
          AND fechaFin < @hoy;

        SET @vencidas = @@ROWCOUNT;

        -- Reactivar únicamente las que no fueron
        -- desactivadas manualmente.
        UPDATE dbo.tarifa
        SET estado = 1
        WHERE estado = 0
          AND desactivadaManual = 0
          AND fechaInicio IS NOT NULL
          AND fechaFin IS NOT NULL
          AND fechaInicio <= @hoy
          AND fechaFin >= @hoy;

        SET @activadas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT
            @vencidas AS tarifasVencidas,
            @activadas AS tarifasActivadas;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
