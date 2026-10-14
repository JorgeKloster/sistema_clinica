package handlers

import (
	"encoding/json"
	"go-backend/db"
	"go-backend/models"
	"net/http"
)

func GetClinics(w http.ResponseWriter, r *http.Request) {
	rows, err := db.DB.Query(`SELECT clinic_id, name, address, phone, created_at, updated_at, updated_by FROM clinic`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var clinics []models.Clinic
	for rows.Next() {
		var c models.Clinic
		if err := rows.Scan(&c.ClinicID, &c.Name, &c.Address, &c.Phone, &c.CreatedAt, &c.UpdatedAt, &c.UpdatedBy); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		clinics = append(clinics, c)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(clinics)
}

func CreateClinic(w http.ResponseWriter, r *http.Request) {
	var c models.Clinic
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := db.DB.Exec(`
        INSERT INTO clinic (name, address, phone, created_at, updated_at, updated_by)
        VALUES ($1, $2, $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $4)
    `, c.Name, c.Address, c.Phone, c.UpdatedBy)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}
