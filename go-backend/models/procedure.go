package models

import "time"

type Procedure struct {
	ProcedureID int     `json:"procedure_id"`
	ClinicID    int     `json:"clinic_id"`
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Price       float64 `json:"price"`
	// Duração sugerida em minutos; o agendamento pode ajustá-la.
	DurationMinutes int `json:"duration_minutes"`
	// Sala onde o procedimento é realizado (obrigatória).
	RoomID    int       `json:"room_id"`
	RoomName  string    `json:"room_name"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	UpdatedBy int       `json:"updated_by"`
}
