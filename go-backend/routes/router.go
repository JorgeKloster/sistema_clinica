package routes

import (
	"go-backend/handlers"
	"net/http"
)

func RegisterRoutes() {
	http.HandleFunc("/patients", handlers.GetPatients)
	http.HandleFunc("/patients/create", handlers.CreatePatient)

	// Add similar routes for clinics, users, procedures, appointments
}
