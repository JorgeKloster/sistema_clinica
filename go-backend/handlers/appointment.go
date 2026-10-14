package handlers

import (
	"encoding/json"
	"go-backend/db"
	"go-backend/models"
	"net/http"
)

func GetAppointments(w http.ResponseWriter, r *http.Request) {
	rows, err := db.DB.Query(`
        SELECT appointment_id, patient_id, doctor_id, procedure_id, scheduled_at, status, created_at, updated_at, updated_by
        FROM appointment
    `)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var appointments []models.Appointment
	for rows.Next() {
		var a models.Appointment
		if err := rows.Scan(&a.AppointmentID, &a.PatientID, &a.DoctorID, &a.ProcedureID, &a.ScheduledAt, &a.Status, &a.CreatedAt, &a.UpdatedAt, &a.UpdatedBy); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		appointments = append(appointments, a)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(appointments)
}

func CreateAppointment(w http.ResponseWriter, r *http.Request) {
	var a models.Appointment
	if err := json.NewDecoder(r.Body).Decode(&a); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := db.DB.Exec(`
        INSERT INTO appointment (patient_id, doctor_id, procedure_id, scheduled_at, status, created_at, updated_at, updated_by)
        VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $6)
    `, a.PatientID, a.DoctorID, a.ProcedureID, a.ScheduledAt, a.Status, a.UpdatedBy)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}
