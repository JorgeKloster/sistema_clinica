package handlers

import (
	"database/sql"
	"encoding/json"
	"go-backend/db"
	"go-backend/middleware"
	"log"
	"net/http"
	"strings"
)

type specialtyResponse struct {
	SpecialtyID int    `json:"specialty_id"`
	Name        string `json:"name"`
}

// GetSpecialties lista as especialidades da clínica do token.
func GetSpecialties(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	rows, err := db.DB.Query(`
        SELECT specialty_id, name
        FROM specialty
        WHERE clinic_id = $1
        ORDER BY name
    `, claims.ClinicID)
	if err != nil {
		log.Printf("GetSpecialties: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	specialties := []specialtyResponse{}

	for rows.Next() {
		var s specialtyResponse
		if err := rows.Scan(&s.SpecialtyID, &s.Name); err != nil {
			log.Printf("GetSpecialties scan: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		specialties = append(specialties, s)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(specialties)
}

func CreateSpecialty(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	var in struct {
		Name string `json:"name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	name := strings.TrimSpace(in.Name)
	if name == "" || len([]rune(name)) > 100 {
		http.Error(w, "Informe um nome de até 100 caracteres", http.StatusBadRequest)
		return
	}

	_, err := db.DB.Exec(`
        INSERT INTO specialty (clinic_id, name)
        VALUES ($1, $2)
    `, claims.ClinicID, name)
	if err != nil {
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgUniqueViolation {
			http.Error(w, "Especialidade já cadastrada", http.StatusConflict)
			return
		}
		log.Printf("CreateSpecialty: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func DeleteSpecialty(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	specialtyID, ok := queryID(w, r)
	if !ok {
		return
	}

	var name string
	err := db.DB.QueryRow(`
        SELECT name FROM specialty
        WHERE specialty_id = $1 AND clinic_id = $2
    `, specialtyID, claims.ClinicID).Scan(&name)
	if err == sql.ErrNoRows {
		http.Error(w, "Especialidade não encontrada", http.StatusNotFound)
		return
	}
	if err != nil {
		log.Printf("DeleteSpecialty lookup: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	var inUse bool
	err = db.DB.QueryRow(`
        SELECT EXISTS (
            SELECT 1 FROM users
            WHERE clinic_id = $1 AND lower(specialty) = lower($2)
        )
    `, claims.ClinicID, name).Scan(&inUse)
	if err != nil {
		log.Printf("DeleteSpecialty in-use check: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if inUse {
		http.Error(w, "Há profissionais com esta especialidade. Altere-os antes de excluir.", http.StatusConflict)
		return
	}

	if _, err := db.DB.Exec(`
        DELETE FROM specialty
        WHERE specialty_id = $1 AND clinic_id = $2
    `, specialtyID, claims.ClinicID); err != nil {
		log.Printf("DeleteSpecialty: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// resolveSpecialty valida a especialidade informada contra a lista da clínica
// e troca pelo nome cadastrado (para padronizar maiúsculas/minúsculas).
// Retorna a mensagem de erro (400) ou "" se estiver tudo certo.
// Profissionais de saúde (role "doctor") precisam ter especialidade.
func resolveSpecialty(clinicID int, in *userInput) string {
	if in.Specialty == "" {
		if in.Role == "doctor" {
			return "Selecione a especialidade do profissional"
		}
		return ""
	}

	var canonical string
	err := db.DB.QueryRow(`
        SELECT name FROM specialty
        WHERE clinic_id = $1 AND lower(name) = lower($2)
    `, clinicID, in.Specialty).Scan(&canonical)
	if err == sql.ErrNoRows {
		return "Especialidade inválida para esta clínica"
	}
	if err != nil {
		log.Printf("resolveSpecialty: %v", err)
		return "Erro ao validar a especialidade"
	}

	in.Specialty = canonical
	return ""
}
