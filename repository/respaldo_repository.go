package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"reserva-backend/conexion"
)

var ErrRespaldoNoEncontrado = errors.New("el respaldo indicado no existe")

type Respaldo struct {
	Nombre  string `json:"nombre"`
	Fecha   string `json:"fecha"`
	Tamano  string `json:"tamano,omitempty"`
	Usuario string `json:"usuario,omitempty"`
}

type RespaldoResultado struct {
	Nombre  string `json:"nombre"`
	Mensaje string `json:"mensaje"`
}

type respaldoInterno struct {
	Respaldo
	archivo string
}

type RespaldoRepository struct {
	db          conexion.Querier
	rutaCarpeta string
	abrirMaster func() (*sql.DB, error)
}

func NewRespaldoRepository(
	db conexion.Querier,
	rutaCarpeta string,
	abrirMaster func() (*sql.DB, error),
) *RespaldoRepository {
	return &RespaldoRepository{
		db:          db,
		rutaCarpeta: strings.TrimSpace(rutaCarpeta),
		abrirMaster: abrirMaster,
	}
}

func nombreArchivo(ruta string) string {
	if i := strings.LastIndexAny(ruta, `/\`); i >= 0 {
		return ruta[i+1:]
	}
	return ruta
}

func (r *RespaldoRepository) listarInterno(ctx context.Context) ([]respaldoInterno, error) {
	rows, err := r.db.QueryContext(ctx, `EXEC dbo.pa_Respaldo_Listar`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	respaldos := []respaldoInterno{}

	for rows.Next() {
		var (
			id      int64
			archivo string
			usuario string
			fecha   time.Time
		)

		if err := rows.Scan(&id, &archivo, &usuario, &fecha); err != nil {
			return nil, err
		}

		respaldos = append(respaldos, respaldoInterno{
			Respaldo: Respaldo{
				Nombre:  nombreArchivo(archivo),
				Fecha:   fecha.Format("2006-01-02T15:04:05"),
				Usuario: usuario,
			},
			archivo: archivo,
		})
	}

	return respaldos, rows.Err()
}

func (r *RespaldoRepository) Listar(ctx context.Context) ([]Respaldo, error) {
	internos, err := r.listarInterno(ctx)
	if err != nil {
		return nil, err
	}

	respaldos := make([]Respaldo, 0, len(internos))
	for _, i := range internos {
		respaldos = append(respaldos, i.Respaldo)
	}

	return respaldos, nil
}

func (r *RespaldoRepository) Crear(ctx context.Context) (RespaldoResultado, error) {
	var ruta any
	if r.rutaCarpeta != "" {
		ruta = r.rutaCarpeta
	}

	var archivo, mensaje string

	err := r.db.QueryRowContext(ctx,
		`EXEC dbo.pa_Respaldo_Crear @rutaCarpeta = @Ruta`,
		sql.Named("Ruta", ruta),
	).Scan(&archivo, &mensaje)
	if err != nil {
		return RespaldoResultado{}, err
	}

	return RespaldoResultado{Nombre: nombreArchivo(archivo), Mensaje: mensaje}, nil
}

func (r *RespaldoRepository) Restaurar(ctx context.Context, nombre string) (RespaldoResultado, error) {
	internos, err := r.listarInterno(ctx)
	if err != nil {
		return RespaldoResultado{}, err
	}

	var archivo string
	for _, i := range internos {
		if i.Nombre == nombre {
			archivo = i.archivo
			break
		}
	}

	if archivo == "" {
		return RespaldoResultado{}, ErrRespaldoNoEncontrado
	}

	master, err := r.abrirMaster()
	if err != nil {
		return RespaldoResultado{}, fmt.Errorf("no se pudo abrir la conexión a master: %w", err)
	}
	defer master.Close()

	var archivoRestaurado, mensaje string

	err = master.QueryRowContext(ctx,
		`EXEC dbo.pa_Restaurar_reservasdbV2 @archivo = @Archivo`,
		sql.Named("Archivo", archivo),
	).Scan(&archivoRestaurado, &mensaje)
	if err != nil {
		return RespaldoResultado{}, err
	}

	return RespaldoResultado{Nombre: nombreArchivo(archivoRestaurado), Mensaje: mensaje}, nil
}
