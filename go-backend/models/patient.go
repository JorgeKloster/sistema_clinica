package models

import "time"

type Patient struct {
	PatientID int    `json:"patient_id"`
	ClinicID  int    `json:"clinic_id"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	CPF       string `json:"cpf"`
	BirthDate string `json:"birth_date"`
	Gender    string `json:"gender"`
	Email     string `json:"email"`
	Phone     string `json:"phone"`
	// Informações de saúde (texto livre), mostradas no atendimento.
	Allergies         string `json:"allergies"`
	MedicalConditions string `json:"medical_conditions"`
	Medications       string `json:"medications"`
	// Quando e por quem as informações de saúde foram alteradas (vazios se
	// nunca preenchidas). HealthUpdatedAt é horário local, sem fuso.
	HealthUpdatedAt     string    `json:"health_updated_at"`
	HealthUpdatedByName string    `json:"health_updated_by_name"`
	CreatedAt           time.Time `json:"created_at"`
	UpdatedAt           time.Time `json:"updated_at"`
	UpdatedBy           int       `json:"updated_by"`
}
