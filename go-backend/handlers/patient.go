package handlers

import (
	"encoding/json"
	"go-backend/db"
	"go-backend/models"
	"net/http"
	"strings"
)

func GetPatients(w http.ResponseWriter, r *http.Request) {
	rows, err := db.DB.Query(`SELECT patient_id, clinic_id, name, cpf, birth_date, email, phone, created_at, updated_at, updated_by FROM patient`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var patients []models.Patient
	for rows.Next() {
		var p models.Patient
		if err := rows.Scan(&p.PatientID, &p.ClinicID, &p.Name, &p.BirthDate, &p.Email, &p.Phone, &p.CreatedAt, &p.UpdatedAt, &p.UpdatedBy); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		patients = append(patients, p)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(patients)
}

func CreatePatient(w http.ResponseWriter, r *http.Request) {
	var p models.Patient
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := db.DB.Exec(`
        INSERT INTO patient (clinic_id, name, cpf, birth_date, email, phone, created_at, updated_at, updated_by)
        VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $7)
    `, p.ClinicID, p.Name, p.CPF, p.BirthDate, p.Email, p.Phone, p.UpdatedBy)

	if err != nil {
		if strings.Contains(err.Error(), "patient_cpf_unique") {
			http.Error(
				w,
				"CPF já existente para outro paciente",
				http.StatusConflict,
			)
			return
		}

		http.Error(
			w,
			err.Error(),
			http.StatusInternalServerError,
		)

		return
	}

	w.WriteHeader(http.StatusCreated)
}
