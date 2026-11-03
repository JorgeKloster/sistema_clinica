package routes

import (
	"go-backend/handlers"
	"go-backend/middleware"
	"net/http"
)

func RegisterRoutes() {

	// PUBLIC
	http.HandleFunc(
		"/users/register",
		handlers.RegisterUser,
	)

	http.HandleFunc(
		"/users/login",
		handlers.LoginUser,
	)

	// PROTECTED

	// Clinics
	http.Handle(
		"/clinics",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetClinics,
			),
		),
	)

	http.Handle(
		"/clinics/create",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.CreateClinic,
			),
		),
	)

	// Users
	http.Handle(
		"/users",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetUsers,
			),
		),
	)

	// Patients
	http.Handle(
		"/patients",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetPatients,
			),
		),
	)

	http.Handle(
		"/patients/create",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.CreatePatient,
			),
		),
	)

	http.Handle(
		"/patients/delete",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.DeletePatient,
			),
		),
	)

	// Procedures
	http.Handle(
		"/procedures",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetProcedures,
			),
		),
	)

	http.Handle(
		"/procedures/create",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.CreateProcedure,
			),
		),
	)

	// Appointments
	http.Handle(
		"/appointments",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetAppointments,
			),
		),
	)

	http.Handle(
		"/appointments/create",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.CreateAppointment,
			),
		),
	)
}
