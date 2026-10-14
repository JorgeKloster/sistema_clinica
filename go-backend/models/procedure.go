package models

import "time"

type Procedure struct {
	ProcedureID int       `json:"procedure_id"`
	ClinicID    int       `json:"clinic_id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Price       float64   `json:"price"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	UpdatedBy   int       `json:"updated_by"`
}
