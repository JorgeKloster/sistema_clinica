package main

import (
	"go-backend/db"
	"go-backend/routes"
	"log"
	"net/http"
)

func main() {
	db.Connect()
	routes.RegisterRoutes()

	log.Println("Backend running on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
