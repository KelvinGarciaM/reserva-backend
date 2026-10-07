package repository

import (
	"context"
	"database/sql"
	"time"

	"reserva-backend/models"

	"github.com/shopspring/decimal"
)

type TarifaRepository struct {
	db *sql.DB
}

func NewTarifaRepository(
	db *sql.DB,
) *TarifaRepository {
	return &TarifaRepository{
		db: db,
	}
}

type CrearTarifaResultado struct {
	IDTarifa int32
	Mensaje  string
}

type ActualizarTarifaResultado struct {
	IDTarifa       int32
	FilasAfectadas int32
	Mensaje        string
}

type CambiarEstadoTarifaResultado struct {
	IDTarifa          int32
	Estado            int8
	DesactivadaManual int8
	Mensaje           string
}

type SincronizarTarifaResultado struct {
	TarifasVencidas  int32
	TarifasActivadas int32
}

type EstadisticasTarifa struct {
	TotalReservas      int64
	UltimaVezUtilizada sql.NullTime
}

func (r *TarifaRepository) SincronizarVigencia(
	ctx context.Context,
) (SincronizarTarifaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Tarifa_SincronizarVigencia
	`

	var resultado SincronizarTarifaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
	).Scan(
		&resultado.TarifasVencidas,
		&resultado.TarifasActivadas,
	)

	return resultado, err
}

func (r *TarifaRepository) Listar(
	ctx context.Context,
) ([]models.Tarifa, error) {

	_, err := r.SincronizarVigencia(ctx)
	if err != nil {
		return nil, err
	}

	const consulta = `
		SELECT
			idTarifa,
			idTipoHabitacion,
			nombreTarifa,
			tipoHabitacion,
			precioBase,
			fechaInicio,
			fechaFin,
			descripcion,
			estado,
			desactivadaManual
		FROM dbo.vw_Tarifa_Detalle
		ORDER BY idTarifa
	`

	rows, err := r.db.QueryContext(ctx, consulta)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	tarifas := make([]models.Tarifa, 0)

	for rows.Next() {

		var tarifa models.Tarifa

		err := rows.Scan(
			&tarifa.IDTarifa,
			&tarifa.IDTipoHabitacion,
			&tarifa.NombreTarifa,
			&tarifa.TipoHabitacion,
			&tarifa.PrecioBase,
			&tarifa.FechaInicio,
			&tarifa.FechaFin,
			&tarifa.Descripcion,
			&tarifa.Estado,
			&tarifa.DesactivadaManual,
		)

		if err != nil {
			return nil, err
		}

		tarifas = append(tarifas, tarifa)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return tarifas, nil
}

func (r *TarifaRepository) ObtenerPorNombre(
	ctx context.Context,
	nombre string,
) (models.Tarifa, error) {

	const consulta = `
		SELECT
			idTarifa,
			idTipoHabitacion,
			nombreTarifa,
			tipoHabitacion,
			precioBase,
			fechaInicio,
			fechaFin,
			descripcion,
			estado,
			desactivadaManual
		FROM dbo.vw_Tarifa_Detalle
		WHERE nombreTarifa = @NombreTarifa
	`

	var tarifa models.Tarifa

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("NombreTarifa", nombre),
	).Scan(
		&tarifa.IDTarifa,
		&tarifa.IDTipoHabitacion,
		&tarifa.NombreTarifa,
		&tarifa.TipoHabitacion,
		&tarifa.PrecioBase,
		&tarifa.FechaInicio,
		&tarifa.FechaFin,
		&tarifa.Descripcion,
		&tarifa.Estado,
		&tarifa.DesactivadaManual,
	)

	return tarifa, err
}

func (r *TarifaRepository) Crear(
	ctx context.Context,
	idTipoHabitacion int32,
	precioBase decimal.Decimal,
	nombreTarifa string,
	fechaInicio *time.Time,
	fechaFin *time.Time,
	descripcion *string,
	estado int8,
) (CrearTarifaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Tarifa_Crear
			@idTipoHabitacion = @IDTipoHabitacion,
			@precioBase = @PrecioBase,
			@nombreTarifa = @NombreTarifa,
			@fechaInicio = @FechaInicio,
			@fechaFin = @FechaFin,
			@descripcion = @Descripcion,
			@estado = @Estado
	`

	var inicio any
	var fin any
	var desc any

	if fechaInicio != nil {
		inicio = *fechaInicio
	}

	if fechaFin != nil {
		fin = *fechaFin
	}

	if descripcion != nil {
		desc = *descripcion
	}

	var resultado CrearTarifaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTipoHabitacion", idTipoHabitacion),
		sql.Named("PrecioBase", precioBase),
		sql.Named("NombreTarifa", nombreTarifa),
		sql.Named("FechaInicio", inicio),
		sql.Named("FechaFin", fin),
		sql.Named("Descripcion", desc),
		sql.Named("Estado", estado),
	).Scan(
		&resultado.IDTarifa,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *TarifaRepository) Actualizar(
	ctx context.Context,
	idTarifa int32,
	idTipoHabitacion *int32,
	precioBase *decimal.Decimal,
	nombreTarifa *string,
	fechaInicio *time.Time,
	fechaFin *time.Time,
	descripcion *string,
) (ActualizarTarifaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Tarifa_Actualizar
			@idTarifa = @IDTarifa,
			@idTipoHabitacion = @IDTipoHabitacion,
			@precioBase = @PrecioBase,
			@nombreTarifa = @NombreTarifa,
			@fechaInicio = @FechaInicio,
			@fechaFin = @FechaFin,
			@descripcion = @Descripcion
	`

	var tipo any
	var precio any
	var nombre any
	var inicio any
	var fin any
	var desc any

	if idTipoHabitacion != nil {
		tipo = *idTipoHabitacion
	}

	if precioBase != nil {
		precio = *precioBase
	}

	if nombreTarifa != nil {
		nombre = *nombreTarifa
	}

	if fechaInicio != nil {
		inicio = *fechaInicio
	}

	if fechaFin != nil {
		fin = *fechaFin
	}

	if descripcion != nil {
		desc = *descripcion
	}

	var resultado ActualizarTarifaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTarifa", idTarifa),
		sql.Named("IDTipoHabitacion", tipo),
		sql.Named("PrecioBase", precio),
		sql.Named("NombreTarifa", nombre),
		sql.Named("FechaInicio", inicio),
		sql.Named("FechaFin", fin),
		sql.Named("Descripcion", desc),
	).Scan(
		&resultado.IDTarifa,
		&resultado.FilasAfectadas,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *TarifaRepository) Activar(
	ctx context.Context,
	idTarifa int32,
) (CambiarEstadoTarifaResultado, error) {

	return r.cambiarEstado(
		ctx,
		idTarifa,
		1,
	)
}

func (r *TarifaRepository) Desactivar(
	ctx context.Context,
	idTarifa int32,
) (CambiarEstadoTarifaResultado, error) {

	return r.cambiarEstado(
		ctx,
		idTarifa,
		0,
	)
}

func (r *TarifaRepository) cambiarEstado(
	ctx context.Context,
	idTarifa int32,
	activar int8,
) (CambiarEstadoTarifaResultado, error) {

	const procedimiento = `
		EXEC dbo.pa_Tarifa_CambiarEstado
			@idTarifa = @IDTarifa,
			@activar = @Activar
	`

	var resultado CambiarEstadoTarifaResultado

	err := r.db.QueryRowContext(
		ctx,
		procedimiento,
		sql.Named("IDTarifa", idTarifa),
		sql.Named("Activar", activar),
	).Scan(
		&resultado.IDTarifa,
		&resultado.Estado,
		&resultado.DesactivadaManual,
		&resultado.Mensaje,
	)

	return resultado, err
}

func (r *TarifaRepository) ObtenerEstadisticas(
	ctx context.Context,
	idTarifa int32,
) (EstadisticasTarifa, error) {

	const consulta = `
		SELECT
			COUNT(dr.idDetalleReserva) AS totalReservas,
			MAX(r.fechaReserva) AS ultimaVezUtilizada
		FROM dbo.detallereserva AS dr
		INNER JOIN dbo.reserva AS r
			ON dr.idReserva = r.idReserva
		WHERE dr.idTarifa = @IDTarifa
	`

	var resultado EstadisticasTarifa

	err := r.db.QueryRowContext(
		ctx,
		consulta,
		sql.Named("IDTarifa", idTarifa),
	).Scan(
		&resultado.TotalReservas,
		&resultado.UltimaVezUtilizada,
	)

	return resultado, err
}
