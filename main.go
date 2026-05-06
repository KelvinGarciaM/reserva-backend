package main

import (
	"database/sql"
	"log"

	"reserva-backend/api"
	"reserva-backend/dto"
	"reserva-backend/utils"

	_ "github.com/go-sql-driver/mysql"
)

func main() {

	// 1. Cargar configuración
	config, err := utils.LoadConfig("utils")
	if err != nil {
		log.Fatal("Error cargando config:", err)
	}

	// 2. Conexión a la base de datos
	conn, err := sql.Open(config.DBDriver, config.DBSource)
	if err != nil {
		log.Fatal("Error conectando DB:", err)
	}

	// 3. SQLC
	dbtx := dto.New(conn)

	// 4. Server
	server, err := api.NewServer(dbtx, config.TokenSymmetricKey)
	if err != nil {
		log.Fatal("Error iniciando server:", err)
	}

	// 5. Iniciar servidor
	err = server.Start(config.ServerURL)
	if err != nil {
		log.Fatal("Error al correr server:", err)
	}
}
