package models

import "time"

type Patient struct {
	PatientID int       `json:"patient_id"`
	ClinicID  int       `json:"clinic_id"`
	Name      string    `json:"name"`
	BirthDate time.Time `json:"birth_date"`
	Email     string    `json:"email"`
	Phone     string    `json:"phone"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	UpdatedBy int       `json:"updated_by"`
}
