package models

import "time"

type Patient struct {
	PatientID int       `json:"patient_id"`
	ClinicID  int       `json:"clinic_id"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	CPF       string    `json:"cpf"`
	BirthDate string    `json:"birth_date"`
	Gender    string    `json:"gender"`
	Email     string    `json:"email"`
	Phone     string    `json:"phone"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	UpdatedBy int       `json:"updated_by"`
}
