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

	http.Handle(
		"/users/create",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.CreateUser,
			),
		),
	)

	http.Handle(
		"/users/update",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.UpdateUser,
			),
		),
	)

	http.Handle(
		"/users/delete",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.DeleteUser,
			),
		),
	)

	// Specialties
	http.Handle(
		"/specialties",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetSpecialties,
			),
		),
	)

	http.Handle(
		"/specialties/create",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.CreateSpecialty,
			),
		),
	)

	http.Handle(
		"/specialties/delete",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.DeleteSpecialty,
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

	http.Handle(
		"/patients/update",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.UpdatePatient,
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

	http.Handle(
		"/procedures/update",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.UpdateProcedure,
			),
		),
	)

	http.Handle(
		"/procedures/delete",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.DeleteProcedure,
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

	http.Handle(
		"/appointments/update",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.UpdateAppointment,
			),
		),
	)

	http.Handle(
		"/appointments/status",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.UpdateAppointmentStatus,
			),
		),
	)

	http.Handle(
		"/appointments/delete",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.DeleteAppointment,
			),
		),
	)

	http.Handle(
		"/appointments/get",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetAppointment,
			),
		),
	)

	http.Handle(
		"/appointments/clinical-notes",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.UpdateClinicalNotes,
			),
		),
	)

	http.Handle(
		"/appointments/history",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetPatientHistory,
			),
		),
	)

	http.Handle(
		"/patients/health",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.UpdatePatientHealth,
			),
		),
	)

	// Rooms

	http.Handle(
		"/room-types",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetRoomTypes,
			),
		),
	)

	http.Handle(
		"/room-types/create",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.CreateRoomType,
			),
		),
	)

	http.Handle(
		"/room-types/delete",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.DeleteRoomType,
			),
		),
	)

	http.Handle(
		"/rooms",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetRooms,
			),
		),
	)

	http.Handle(
		"/rooms/create",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.CreateRoom,
			),
		),
	)

	http.Handle(
		"/rooms/update",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.UpdateRoom,
			),
		),
	)

	http.Handle(
		"/rooms/delete",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.DeleteRoom,
			),
		),
	)

	http.Handle(
		"/rooms/live",
		middleware.JWTMiddleware(
			http.HandlerFunc(
				handlers.GetLiveRooms,
			),
		),
	)
}
