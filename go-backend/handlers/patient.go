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
        SELECT p.patient_id,
            p.clinic_id,
            p.first_name,
            p.last_name,
            p.birth_date,
            p.gender,
            p.email,
            p.phone,
            p.cpf,
            COALESCE(p.allergies, ''),
            COALESCE(p.medical_conditions, ''),
            COALESCE(p.medications, ''),
            COALESCE(to_char(p.health_updated_at, 'YYYY-MM-DD"T"HH24:MI:SS'), ''),
            COALESCE(btrim(hu.first_name || ' ' || hu.last_name), ''),
            p.created_at,
            p.updated_at,
            p.updated_by
        FROM patient p
        LEFT JOIN users hu ON hu.user_id = p.health_updated_by
        WHERE p.clinic_id = $1
        ORDER BY p.first_name, p.last_name
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
			&p.Allergies,
			&p.MedicalConditions,
			&p.Medications,
			&p.HealthUpdatedAt,
			&p.HealthUpdatedByName,
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
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgUniqueViolation &&
			pqErr.Constraint == "patient_cpf_unique" {
			http.Error(w, "CPF já existente para outro paciente", http.StatusConflict)
			return
		}

		log.Printf("CreatePatient: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func DeletePatient(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	patientID, ok := queryID(w, r)
	if !ok {
		return
	}

	result, err := db.DB.Exec(`
        DELETE FROM patient
        WHERE patient_id = $1
        AND clinic_id = $2
    `, patientID, claims.ClinicID)
	if err != nil {
		// Com a migration 0010 a FK de appointment é RESTRICT.
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgForeignKeyViolation {
			http.Error(w, "Paciente possui agendamentos e não pode ser excluído", http.StatusConflict)
			return
		}
		log.Printf("DeletePatient: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Paciente não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func UpdatePatient(w http.ResponseWriter, r *http.Request) {

	claims := middleware.GetClaims(r)

	patientID, ok := queryID(w, r)
	if !ok {
		return
	}

	var p models.Patient

	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	result, err := db.DB.Exec(`
        UPDATE patient
        SET
            first_name = $1,
            last_name = $2,
            cpf = $3,
            birth_date = $4,
            gender = $5,
            email = $6,
            phone = $7,
            updated_at = CURRENT_TIMESTAMP,
            updated_by = $8
        WHERE patient_id = $9
        AND clinic_id = $10
    `,
		p.FirstName,
		p.LastName,
		p.CPF,
		p.BirthDate,
		p.Gender,
		p.Email,
		p.Phone,
		claims.UserID,
		patientID,
		claims.ClinicID,
	)

	if err != nil {
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgUniqueViolation &&
			pqErr.Constraint == "patient_cpf_unique" {
			http.Error(w, "CPF já existente para outro paciente", http.StatusConflict)
			return
		}

		log.Printf("UpdatePatient: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	rows, err := result.RowsAffected()
	if err != nil {
		log.Printf("UpdatePatient rows affected: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if rows == 0 {
		http.Error(w, "Patient not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// cleanHealthList normaliza um campo de saúde: um item por linha, sem linhas
// vazias nem espaços sobrando.
func cleanHealthList(text string) string {
	items := []string{}

	for _, line := range strings.Split(text, "\n") {
		if item := strings.TrimSpace(line); item != "" {
			items = append(items, item)
		}
	}

	return strings.Join(items, "\n")
}

// UpdatePatientHealth grava alergias, condições e medicamentos (um item por
// linha) e registra quem alterou e quando. Chamado pela tela de atendimento.
//
//	PUT /patients/health?id=5
//	{"allergies": "Dipirona\nLátex", "medical_conditions": "...", "medications": "..."}
func UpdatePatientHealth(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	patientID, ok := queryID(w, r)
	if !ok {
		return
	}

	var in struct {
		Allergies         string `json:"allergies"`
		MedicalConditions string `json:"medical_conditions"`
		Medications       string `json:"medications"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	result, err := db.DB.Exec(`
        UPDATE patient
        SET
            allergies = NULLIF($1, ''),
            medical_conditions = NULLIF($2, ''),
            medications = NULLIF($3, ''),
            health_updated_at = LOCALTIMESTAMP,
            health_updated_by = $4,
            updated_by = $4
        WHERE patient_id = $5
        AND clinic_id = $6
    `,
		cleanHealthList(in.Allergies),
		cleanHealthList(in.MedicalConditions),
		cleanHealthList(in.Medications),
		claims.UserID,
		patientID,
		claims.ClinicID,
	)
	if err != nil {
		log.Printf("UpdatePatientHealth: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Paciente não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}
