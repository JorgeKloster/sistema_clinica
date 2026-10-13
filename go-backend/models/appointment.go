package models

import "time"

type Appointment struct {
	AppointmentID int       `json:"appointment_id"`
	PatientID     int       `json:"patient_id"`
	DoctorID      int       `json:"doctor_id"` // references users
	ProcedureID   int       `json:"procedure_id"`
	ScheduledAt   time.Time `json:"scheduled_at"`
	Status        string    `json:"status"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
	UpdatedBy     int       `json:"updated_by"`
}
