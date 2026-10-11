USE reservasdbV2;
GO

/* ---------- 11.6 Trigger: auditoría de tarifas ---------- */
CREATE OR ALTER TRIGGER dbo.trg_Tarifa_Auditoria
ON dbo.tarifa
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* INSERT */
    INSERT INTO dbo.auditoriaTarifa
        (idTarifa, accion, precioBaseNuevo, fechaInicioNueva, fechaFinNueva, estadoNuevo)
    SELECT i.idTarifa, 'INSERT', i.precioBase, i.fechaInicio, i.fechaFin, i.estado
    FROM inserted AS i
    LEFT JOIN deleted AS d ON d.idTarifa = i.idTarifa
    WHERE d.idTarifa IS NULL;

    /* UPDATE: solo si cambió precio, fechas o estado */
    INSERT INTO dbo.auditoriaTarifa
        (idTarifa, accion,
         precioBaseAnterior, precioBaseNuevo,
         fechaInicioAnterior, fechaInicioNueva,
         fechaFinAnterior, fechaFinNueva,
         estadoAnterior, estadoNuevo)
    SELECT i.idTarifa, 'UPDATE',
           d.precioBase, i.precioBase,
           d.fechaInicio, i.fechaInicio,
           d.fechaFin, i.fechaFin,
           d.estado, i.estado
    FROM inserted AS i
    INNER JOIN deleted AS d ON d.idTarifa = i.idTarifa
    WHERE i.precioBase <> d.precioBase
       OR ISNULL(i.fechaInicio, '19000101') <> ISNULL(d.fechaInicio, '19000101')
       OR ISNULL(i.fechaFin,    '19000101') <> ISNULL(d.fechaFin,    '19000101')
       OR i.estado <> d.estado;
END;
GO
