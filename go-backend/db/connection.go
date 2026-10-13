package db

import (
	"database/sql"
	"log"
	"os"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

var DB *sql.DB

func Connect() {
	// Load .env file from go-backend folder
	err := godotenv.Load(".env")
	if err != nil {
		log.Println("Warning: .env file not found, relying on system environment variables")
	}

	// Read environment variables
	host := os.Getenv("DB_HOST")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")
	sslmode := os.Getenv("DB_SSLMODE")

	// Build connection string
	connStr := "host=" + host +
		" user=" + user +
		" password=" + password +
		" dbname=" + dbname +
		" sslmode=" + sslmode

	DB, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
}
