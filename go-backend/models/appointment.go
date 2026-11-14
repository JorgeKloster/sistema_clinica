package models

import "time"

// Appointment é o agendamento como a API o devolve (já com os nomes do
// paciente, do profissional e do procedimento, para a agenda não precisar
// de uma consulta extra por item).
//
// StartsAt e EndsAt são horário local da clínica no formato
// "2006-01-02T15:04:05", sem fuso, para o app não deslocar o horário.
type Appointment struct {
	AppointmentID   int    `json:"appointment_id"`
	ClinicID        int    `json:"clinic_id"`
	PatientID       int    `json:"patient_id"`
	PatientName     string `json:"patient_name"`
	DoctorID        int    `json:"doctor_id"` // references users
	DoctorName      string `json:"doctor_name"`
	DoctorSpecialty string `json:"doctor_specialty"`
	ProcedureID     int    `json:"procedure_id"`
	ProcedureName   string `json:"procedure_name"`
	StartsAt        string `json:"starts_at"`
	EndsAt          string `json:"ends_at"`
	Status          string `json:"status"`
	Notes           string `json:"notes"`
	// Atendimento: início/fim reais (vazios até acontecerem) e anotações clínicas.
	StartedAt     string `json:"started_at"`
	FinishedAt    string `json:"finished_at"`
	ClinicalNotes string `json:"clinical_notes"`
	// Sala (a do procedimento) e, em atendimento, segundos desde o início,
	// calculados no servidor para o app não depender do relógio/fuso dele.
	RoomID         int       `json:"room_id"`
	RoomName       string    `json:"room_name"`
	ElapsedSeconds int       `json:"elapsed_seconds"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
	UpdatedBy      int       `json:"updated_by"`
}
