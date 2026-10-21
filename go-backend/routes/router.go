package routes

import (
	"go-backend/handlers"
	"net/http"
)

func RegisterRoutes() {
	// Clinics
	http.HandleFunc("/clinics", handlers.GetClinics)
	http.HandleFunc("/clinics/create", handlers.CreateClinic)

	// Users
	http.HandleFunc("/users", handlers.GetUsers)
	http.HandleFunc("/users/register", handlers.RegisterUser)
	http.HandleFunc("/users/login", handlers.LoginUser)

	// Patients
	http.HandleFunc("/patients", handlers.GetPatients)
	http.HandleFunc("/patients/create", handlers.CreatePatient)

	// Procedures
	http.HandleFunc("/procedures", handlers.GetProcedures)
	http.HandleFunc("/procedures/create", handlers.CreateProcedure)

	// Appointments
	http.HandleFunc("/appointments", handlers.GetAppointments)
	http.HandleFunc("/appointments/create", handlers.CreateAppointment)
}
