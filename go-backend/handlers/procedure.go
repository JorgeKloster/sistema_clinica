package handlers

import (
	"encoding/json"
	"go-backend/db"
	"go-backend/models"
	"net/http"
)

func GetProcedures(w http.ResponseWriter, r *http.Request) {
	rows, err := db.DB.Query(`SELECT procedure_id, clinic_id, name, description, price, created_at, updated_at, updated_by FROM procedure`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var procedures []models.Procedure
	for rows.Next() {
		var p models.Procedure
		if err := rows.Scan(&p.ProcedureID, &p.ClinicID, &p.Name, &p.Description, &p.Price, &p.CreatedAt, &p.UpdatedAt, &p.UpdatedBy); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		procedures = append(procedures, p)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(procedures)
}

func CreateProcedure(w http.ResponseWriter, r *http.Request) {
	var p models.Procedure
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := db.DB.Exec(`
        INSERT INTO procedure (clinic_id, name, description, price, created_at, updated_at, updated_by)
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $5)
    `, p.ClinicID, p.Name, p.Description, p.Price, p.UpdatedBy)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}
