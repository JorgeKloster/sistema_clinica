package handlers

import (
	"database/sql"
	"encoding/json"
	"go-backend/db"
	"go-backend/middleware"
	"go-backend/models"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type Claims struct {
	UserID   int    `json:"user_id"`
	ClinicID int    `json:"clinic_id"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

// RegisterUser só funciona enquanto não existe nenhum usuário (cadastro do
// primeiro administrador). Depois disso, novos usuários são criados por um
// administrador em /users/create.
func RegisterUser(w http.ResponseWriter, r *http.Request) {
	var exists bool
	if err := db.DB.QueryRow(`SELECT EXISTS (SELECT 1 FROM users)`).Scan(&exists); err != nil {
		log.Printf("RegisterUser: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if exists {
		http.Error(w, "Cadastro inicial já realizado. Peça a um administrador para criar o usuário.", http.StatusForbidden)
		return
	}

	// O corpo segue o formato antigo: a senha vem em "password_hash".
	var u models.Users
	if err := json.NewDecoder(r.Body).Decode(&u); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	in := userInput{
		FirstName: u.FirstName,
		LastName:  u.LastName,
		Email:     u.Email,
		Phone:     u.Phone,
		Role:      "admin",
		Password:  u.PasswordHash,
	}
	in.normalize()
	if msg := in.validate(true); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, "Error hashing password", http.StatusInternalServerError)
		return
	}

	// updated_by fica NULL: ainda não existe usuário para referenciar.
	_, err = db.DB.Exec(`
        INSERT INTO users (clinic_id, first_name, last_name, email, phone, password_hash, role)
        VALUES ($1, $2, $3, $4, NULLIF($5, ''), $6, 'admin')
    `, u.ClinicID, in.FirstName, in.LastName, in.Email, in.Phone, string(hashedPassword))
	if err != nil {
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgForeignKeyViolation {
			http.Error(w, "Clínica inexistente", http.StatusBadRequest)
			return
		}
		log.Printf("RegisterUser insert: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
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
	err := db.DB.QueryRow(`SELECT user_id, clinic_id, first_name, last_name, email, COALESCE(phone, ''), role, COALESCE(specialty, ''), password_hash, created_at, updated_at, COALESCE(updated_by, 0) FROM users WHERE email = $1`, creds.Email).Scan(&user.UserID, &user.ClinicID, &user.FirstName, &user.LastName, &user.Email, &user.Phone, &user.Role, &user.Specialty, &storedHash, &user.CreatedAt, &user.UpdatedAt, &user.UpdatedBy)
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
	claims := &middleware.Claims{
		UserID:   user.UserID,
		ClinicID: user.ClinicID,
		Role:     user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(
				time.Now().Add(
					24 * time.Hour,
				),
			),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(middleware.JwtKey)
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

// ---------------------------------------------------------------------------
// Profissionais (CRUD de users, restrito à clínica do token)
// ---------------------------------------------------------------------------

var validRoles = map[string]bool{
	"admin":        true,
	"doctor":       true,
	"receptionist": true,
}

const minPasswordLength = 8

// userResponse é o que a API devolve: nunca inclui password_hash.
type userResponse struct {
	UserID    int       `json:"user_id"`
	ClinicID  int       `json:"clinic_id"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Email     string    `json:"email"`
	Phone     string    `json:"phone"`
	Role      string    `json:"role"`
	Specialty string    `json:"specialty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	UpdatedBy int       `json:"updated_by"`
}

// userInput é o corpo aceito em create/update. clinic_id e updated_by
// nunca são lidos do corpo.
type userInput struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Email     string `json:"email"`
	Phone     string `json:"phone"`
	Role      string `json:"role"`
	Specialty string `json:"specialty"`
	Password  string `json:"password"`
}

func (u *userInput) normalize() {
	u.FirstName = strings.TrimSpace(u.FirstName)
	u.LastName = strings.TrimSpace(u.LastName)
	u.Email = strings.ToLower(strings.TrimSpace(u.Email))
	u.Phone = strings.TrimSpace(u.Phone)
	u.Specialty = strings.TrimSpace(u.Specialty)
	if u.Role != "doctor" {
		u.Specialty = "" // especialidade só faz sentido para médicos/dentistas
	}
}

// validate retorna a mensagem de erro, ou "" se estiver tudo certo.
// passwordRequired é true na criação e false na edição.
func (u *userInput) validate(passwordRequired bool) string {
	switch {
	case u.FirstName == "" || u.LastName == "":
		return "Nome e sobrenome são obrigatórios"
	case !strings.Contains(u.Email, "@"):
		return "E-mail inválido"
	case !validRoles[u.Role]:
		return "Perfil inválido"
	case passwordRequired && len(u.Password) < minPasswordLength:
		return "A senha deve ter pelo menos 8 caracteres"
	case u.Password != "" && len(u.Password) < minPasswordLength:
		return "A senha deve ter pelo menos 8 caracteres"
	}
	return ""
}

func GetUsers(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	rows, err := db.DB.Query(`
        SELECT user_id,
            clinic_id,
            first_name,
            last_name,
            email,
            COALESCE(phone, ''),
            role,
            COALESCE(specialty, ''),
            created_at,
            updated_at,
            COALESCE(updated_by, 0)
        FROM users
        WHERE clinic_id = $1
        ORDER BY first_name, last_name
    `, claims.ClinicID)
	if err != nil {
		log.Printf("GetUsers: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	users := []userResponse{}

	for rows.Next() {
		var u userResponse
		if err := rows.Scan(
			&u.UserID,
			&u.ClinicID,
			&u.FirstName,
			&u.LastName,
			&u.Email,
			&u.Phone,
			&u.Role,
			&u.Specialty,
			&u.CreatedAt,
			&u.UpdatedAt,
			&u.UpdatedBy,
		); err != nil {
			log.Printf("GetUsers scan: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		users = append(users, u)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

func CreateUser(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	var in userInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	in.normalize()
	if msg := in.validate(true); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}
	if msg := resolveSpecialty(claims.ClinicID, &in); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("CreateUser bcrypt: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	_, err = db.DB.Exec(`
        INSERT INTO users (clinic_id, first_name, last_name, email, phone, password_hash, role, specialty, updated_by)
        VALUES ($1, $2, $3, $4, NULLIF($5, ''), $6, $7, NULLIF($8, ''), $9)
    `, claims.ClinicID, in.FirstName, in.LastName, in.Email, in.Phone, string(hash), in.Role, in.Specialty, claims.UserID)
	if err != nil {
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgUniqueViolation {
			http.Error(w, "E-mail já cadastrado para outro usuário", http.StatusConflict)
			return
		}
		log.Printf("CreateUser: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func UpdateUser(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	userID, ok := queryID(w, r)
	if !ok {
		return
	}

	var in userInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	in.normalize()
	if msg := in.validate(false); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}
	if msg := resolveSpecialty(claims.ClinicID, &in); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}

	// Evita que o último admin se rebaixe e deixe a clínica sem administrador.
	if userID == claims.UserID && in.Role != "admin" {
		http.Error(w, "Você não pode remover seu próprio acesso de administrador", http.StatusBadRequest)
		return
	}

	// Senha em branco = manter a atual.
	newHash := sql.NullString{}
	if in.Password != "" {
		hash, err := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)
		if err != nil {
			log.Printf("UpdateUser bcrypt: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		newHash = sql.NullString{String: string(hash), Valid: true}
	}

	result, err := db.DB.Exec(`
        UPDATE users
        SET
            first_name = $1,
            last_name = $2,
            email = $3,
            phone = NULLIF($4, ''),
            role = $5,
            specialty = NULLIF($6, ''),
            password_hash = COALESCE($7, password_hash),
            updated_by = $8
        WHERE user_id = $9
        AND clinic_id = $10
    `, in.FirstName, in.LastName, in.Email, in.Phone, in.Role, in.Specialty, newHash, claims.UserID, userID, claims.ClinicID)
	if err != nil {
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgUniqueViolation {
			http.Error(w, "E-mail já cadastrado para outro usuário", http.StatusConflict)
			return
		}
		log.Printf("UpdateUser: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Profissional não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func DeleteUser(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	userID, ok := queryID(w, r)
	if !ok {
		return
	}

	if userID == claims.UserID {
		http.Error(w, "Você não pode excluir o próprio usuário", http.StatusBadRequest)
		return
	}

	result, err := db.DB.Exec(`
        DELETE FROM users
        WHERE user_id = $1
        AND clinic_id = $2
    `, userID, claims.ClinicID)
	if err != nil {
		// updated_by (auditoria) e appointment.doctor_id referenciam users.
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgForeignKeyViolation {
			http.Error(w, "Profissional possui registros vinculados e não pode ser excluído", http.StatusConflict)
			return
		}
		log.Printf("DeleteUser: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Profissional não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
