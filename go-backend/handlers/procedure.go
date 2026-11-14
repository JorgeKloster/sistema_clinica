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
        SELECT p.procedure_id,
            p.clinic_id,
            p.name,
            COALESCE(p.description, ''),
            COALESCE(p.price, 0),
            p.duration_minutes,
            p.room_id,
            r.name,
            p.created_at,
            p.updated_at,
            COALESCE(p.updated_by, 0)
        FROM procedure p
        JOIN room r ON r.room_id = p.room_id
        WHERE p.clinic_id = $1
        ORDER BY p.name
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
			&p.DurationMinutes,
			&p.RoomID,
			&p.RoomName,
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
	if p.DurationMinutes == 0 {
		p.DurationMinutes = 60
	}
	if p.DurationMinutes < 5 || p.DurationMinutes > 480 {
		return "A duração deve ficar entre 5 e 480 minutos"
	}
	if p.RoomID <= 0 {
		return "Selecione a sala do procedimento"
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
	// A sala precisa ser da mesma clínica: o SELECT só devolve linha se for.
	result, err := db.DB.Exec(`
        INSERT INTO procedure (clinic_id, name, description, price, duration_minutes, room_id, updated_by)
        SELECT $1, $2, $3, $4, $5, r.room_id, $7
        FROM room r
        WHERE r.room_id = $6 AND r.clinic_id = $1
    `, claims.ClinicID, p.Name, p.Description, p.Price, p.DurationMinutes, p.RoomID, claims.UserID)
	if err != nil {
		log.Printf("CreateProcedure: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Sala inválida", http.StatusBadRequest)
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
            duration_minutes = $4,
            room_id = (SELECT r.room_id FROM room r WHERE r.room_id = $5 AND r.clinic_id = $8),
            updated_by = $6
        WHERE procedure_id = $7
        AND clinic_id = $8
    `, p.Name, p.Description, p.Price, p.DurationMinutes, p.RoomID, claims.UserID, procedureID, claims.ClinicID)
	if err != nil {
		// Sala de outra clínica (ou inexistente) resulta em room_id nulo.
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgNotNullViolation {
			http.Error(w, "Sala inválida", http.StatusBadRequest)
			return
		}
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
