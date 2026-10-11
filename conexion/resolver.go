package conexion

import (
	"context"
	"database/sql"
)

// Querier es lo mínimo que usan los repositorios. *sql.DB ya lo cumple.
// Los repositorios guardan un Querier en lugar de un *sql.DB, y así el resto
// de su código (r.db.QueryRowContext(...), etc.) no cambia.
type Querier interface {
	QueryContext(ctx context.Context, query string, args ...any) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
	PrepareContext(ctx context.Context, query string) (*sql.Stmt, error)
	BeginTx(ctx context.Context, opts *sql.TxOptions) (*sql.Tx, error)
}

type ctxKey struct{}

// WithDB guarda en el contexto la conexión del usuario que inició sesión.
func WithDB(ctx context.Context, db *sql.DB) context.Context {
	return context.WithValue(ctx, ctxKey{}, db)
}

// Resolver elige, en cada consulta, la conexión del usuario de la petición.
// Así cada usuario del motor trabaja con SU propia conexión y SQL Server
// aplica los permisos (GRANT/DENY) de ese usuario.
type Resolver struct {
	sinSesion *sql.DB
}

func NewResolver() *Resolver {
	// Conexión que nace CERRADA a propósito: si alguna petición llega sin
	// sesión, la consulta falla ("sql: database is closed") en lugar de
	// ejecutarse con una cuenta con privilegios.
	db, err := sql.Open("sqlserver", "sqlserver://sin-sesion:x@localhost:1?database=x")
	if err != nil {
		panic("no se pudo preparar la conexión vacía: " + err.Error())
	}
	_ = db.Close()
	return &Resolver{sinSesion: db}
}

func (r *Resolver) pick(ctx context.Context) *sql.DB {
	if db, ok := ctx.Value(ctxKey{}).(*sql.DB); ok && db != nil {
		return db
	}
	return r.sinSesion
}

func (r *Resolver) QueryContext(ctx context.Context, query string, args ...any) (*sql.Rows, error) {
	return r.pick(ctx).QueryContext(ctx, query, args...)
}

func (r *Resolver) QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row {
	return r.pick(ctx).QueryRowContext(ctx, query, args...)
}

func (r *Resolver) ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error) {
	return r.pick(ctx).ExecContext(ctx, query, args...)
}

func (r *Resolver) PrepareContext(ctx context.Context, query string) (*sql.Stmt, error) {
	return r.pick(ctx).PrepareContext(ctx, query)
}

func (r *Resolver) BeginTx(ctx context.Context, opts *sql.TxOptions) (*sql.Tx, error) {
	return r.pick(ctx).BeginTx(ctx, opts)
}
