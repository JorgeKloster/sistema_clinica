package main

import (
	"go-backend/db"
	"go-backend/routes"
	"log"
	"net/http"

	"github.com/rs/cors"
)

func main() {
	db.Connect()
	routes.RegisterRoutes() // adjust your RegisterRoutes to accept mux

	// Configure CORS
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE"},
		AllowedHeaders:   []string{"Content-Type", "Authorization"},
		AllowCredentials: true,
	})

	handler := c.Handler(http.DefaultServeMux)

	log.Println("Backend running on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", handler))
}
