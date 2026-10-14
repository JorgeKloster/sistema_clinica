package handlers

import (
	"database/sql"
	"encoding/json"
	"go-backend/db"
	"go-backend/models"
	"net/http"

	"golang.org/x/crypto/bcrypt"
)

func RegisterUser(w http.ResponseWriter, r *http.Request) {
	var u models.Users
	if err := json.NewDecoder(r.Body).Decode(&u); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(u.PasswordHash), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, "Error hashing password", http.StatusInternalServerError)
		return
	}

	_, err = db.DB.Exec(`
        INSERT INTO users (clinic_id, first_name, last_name, email, phone, password_hash, role, specialty, created_at, updated_at, updated_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $9)
    `, u.ClinicID, u.FirstName, u.LastName, u.Email, u.Phone, string(hashedPassword), u.Role, u.Specialty, u.UpdatedBy)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func LoginUser(w http.ResponseWriter, r *http.Request) {
	var creds struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&creds); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var storedHash string
	var userID int
	err := db.DB.QueryRow(`SELECT user_id, password_hash FROM users WHERE email = $1`, creds.Email).Scan(&userID, &storedHash)
	if err == sql.ErrNoRows {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(creds.Password)) != nil {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	// TODO: issue JWT here
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Login successful",
		"user_id": userID,
	})
}

func GetUsers(w http.ResponseWriter, r *http.Request) {
	rows, err := db.DB.Query(`SELECT user_id, clinic_id, first_name, last_name, email, phone, role, specialty, created_at, updated_at, updated_by FROM users`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var users []models.Users
	for rows.Next() {
		var u models.Users
		if err := rows.Scan(&u.UserID, &u.ClinicID, &u.FirstName, &u.LastName, &u.Email, &u.Phone, &u.Role, &u.Specialty, &u.CreatedAt, &u.UpdatedAt, &u.UpdatedBy); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		users = append(users, u)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}
