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

func GetProcedures(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	rows, err := db.DB.Query(`
        SELECT procedure_id,
            clinic_id,
            name,
            COALESCE(description, ''),
            COALESCE(price, 0),
            created_at,
            updated_at,
            COALESCE(updated_by, 0)
        FROM procedure
        WHERE clinic_id = $1
        ORDER BY name
    `, claims.ClinicID)
	if err != nil {
		log.Printf("GetProcedures: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	procedures := []models.Procedure{}

	for rows.Next() {
		var p models.Procedure
		if err := rows.Scan(
			&p.ProcedureID,
			&p.ClinicID,
			&p.Name,
			&p.Description,
			&p.Price,
			&p.CreatedAt,
			&p.UpdatedAt,
			&p.UpdatedBy,
		); err != nil {
			log.Printf("GetProcedures scan: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		procedures = append(procedures, p)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(procedures)
}

func validateProcedure(p *models.Procedure) string {
	p.Name = strings.TrimSpace(p.Name)
	p.Description = strings.TrimSpace(p.Description)

	if p.Name == "" {
		return "Nome é obrigatório"
	}
	if p.Price < 0 {
		return "Valor não pode ser negativo"
	}
	return ""
}

func CreateProcedure(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	var p models.Procedure
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if msg := validateProcedure(&p); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}

	// clinic_id e updated_by vêm sempre do token, nunca do corpo da requisição.
	_, err := db.DB.Exec(`
        INSERT INTO procedure (clinic_id, name, description, price, updated_by)
        VALUES ($1, $2, $3, $4, $5)
    `, claims.ClinicID, p.Name, p.Description, p.Price, claims.UserID)
	if err != nil {
		log.Printf("CreateProcedure: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func UpdateProcedure(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	procedureID, ok := queryID(w, r)
	if !ok {
		return
	}

	var p models.Procedure
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if msg := validateProcedure(&p); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}

	result, err := db.DB.Exec(`
        UPDATE procedure
        SET
            name = $1,
            description = $2,
            price = $3,
            updated_by = $4
        WHERE procedure_id = $5
        AND clinic_id = $6
    `, p.Name, p.Description, p.Price, claims.UserID, procedureID, claims.ClinicID)
	if err != nil {
		log.Printf("UpdateProcedure: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Procedimento não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func DeleteProcedure(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	procedureID, ok := queryID(w, r)
	if !ok {
		return
	}

	result, err := db.DB.Exec(`
        DELETE FROM procedure
        WHERE procedure_id = $1
        AND clinic_id = $2
    `, procedureID, claims.ClinicID)
	if err != nil {
		// Com a migration 0009 a FK de appointment é RESTRICT.
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgForeignKeyViolation {
			http.Error(w, "Procedimento possui agendamentos e não pode ser excluído", http.StatusConflict)
			return
		}
		log.Printf("DeleteProcedure: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Procedimento não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
