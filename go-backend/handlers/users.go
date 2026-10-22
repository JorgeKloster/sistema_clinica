package handlers

import (
	"database/sql"
	"encoding/json"
	"go-backend/db"
	"go-backend/models"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

var jwtKey = []byte("your_secret_key") // keep safe, use env var

type Claims struct {
	UserID   int    `json:"user_id"`
	ClinicID int    `json:"clinic_id"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

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
	var user models.Users
	err := db.DB.QueryRow(`SELECT user_id, clinic_id, first_name, last_name, email, phone, role, specialty, password_hash, created_at, updated_at, updated_by FROM users WHERE email = $1`, creds.Email).Scan(&user.UserID, &user.ClinicID, &user.FirstName, &user.LastName, &user.Email, &user.Phone, &user.Role, &user.Specialty, &storedHash, &user.CreatedAt, &user.UpdatedAt, &user.UpdatedBy)
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

	// Create JWT claims
	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &Claims{
		UserID:   user.UserID,
		ClinicID: user.ClinicID,
		Role:     user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		http.Error(w, "Could not create token", http.StatusInternalServerError)
		return
	}

	// Return token + user info
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"token": tokenString,
		"user":  user,
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
