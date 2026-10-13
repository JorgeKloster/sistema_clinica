package models

import "time"

type Users struct {
	UserID       int       `json:"user_id"`
	ClinicID     int       `json:"clinic_id"`
	FirstName    string    `json:"first_name"`
	LastName     string    `json:"last_name"`
	Email        string    `json:"email"`
	Phone        string    `json:"phone"`
	PasswordHash string    `json:"password_hash"` // stored hash
	Role         string    `json:"role"`
	Specialty    string    `json:"specialty"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
	UpdatedBy    int       `json:"updated_by"`
}
