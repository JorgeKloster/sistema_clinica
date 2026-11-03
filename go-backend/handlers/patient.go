package handlers

import (
	"encoding/json"
	"go-backend/db"
	"go-backend/middleware"
	"go-backend/models"
	"log"
	"net/http"
	"strings"
)

func GetPatients(w http.ResponseWriter, r *http.Request) {

	claims := middleware.GetClaims(r)

	log.Printf(
		"ClinicID JWT: %d",
		claims.ClinicID,
	)

	rows, err := db.DB.Query(`
        SELECT
            patient_id,
            clinic_id,
            first_name,
            last_name,
            birth_date,
            gender,
            email,
            phone,
            cpf,
            created_at,
            updated_at,
            updated_by
        FROM patient
        WHERE clinic_id = $1
        ORDER BY first_name, last_name
    `,
		claims.ClinicID,
	)

	if err != nil {
		http.Error(
			w,
			err.Error(),
			http.StatusInternalServerError,
		)
		return
	}

	defer rows.Close()

	patients := []models.Patient{}

	for rows.Next() {
		var p models.Patient

		err := rows.Scan(
			&p.PatientID,
			&p.ClinicID,
			&p.FirstName,
			&p.LastName,
			&p.BirthDate,
			&p.Gender,
			&p.Email,
			&p.Phone,
			&p.CPF,
			&p.CreatedAt,
			&p.UpdatedAt,
			&p.UpdatedBy,
		)

		if err != nil {
			http.Error(
				w,
				err.Error(),
				http.StatusInternalServerError,
			)
			return
		}

		patients = append(
			patients,
			p,
		)
	}

	w.Header().Set(
		"Content-Type",
		"application/json",
	)

	json.NewEncoder(w).Encode(
		patients,
	)
}

func CreatePatient(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)
	var p models.Patient
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	p.ClinicID = claims.ClinicID
	p.UpdatedBy = claims.UserID

	_, err := db.DB.Exec(`
        INSERT INTO patient (clinic_id, first_name, last_name, cpf, birth_date, email, phone, gender, created_at, updated_at, updated_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $9)
    `, p.ClinicID, p.FirstName, p.LastName, p.CPF, p.BirthDate, p.Email, p.Phone, p.Gender, p.UpdatedBy)

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

func DeletePatient(
	w http.ResponseWriter,
	r *http.Request,
) {
	claims := middleware.GetClaims(r)

	patientID := r.URL.Query().Get("id")

	_, err := db.DB.Exec(`
        DELETE FROM patient
        WHERE patient_id = $1
        AND clinic_id = $2
    `,
		patientID,
		claims.ClinicID,
	)

	if err != nil {
		http.Error(
			w,
			err.Error(),
			http.StatusInternalServerError,
		)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
