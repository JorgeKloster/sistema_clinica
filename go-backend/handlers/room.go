package handlers

import (
	"database/sql"
	"encoding/json"
	"errors"
	"go-backend/db"
	"go-backend/middleware"
	"go-backend/models"
	"log"
	"net/http"
	"strings"
)

// ---------------------------------------------------------------- tipos

type roomTypeResponse struct {
	RoomTypeID int    `json:"room_type_id"`
	Name       string `json:"name"`
}

// GetRoomTypes lista os tipos de sala da clínica do token.
func GetRoomTypes(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	rows, err := db.DB.Query(`
        SELECT room_type_id, name
        FROM room_type
        WHERE clinic_id = $1
        ORDER BY name
    `, claims.ClinicID)
	if err != nil {
		log.Printf("GetRoomTypes: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	types := []roomTypeResponse{}

	for rows.Next() {
		var t roomTypeResponse
		if err := rows.Scan(&t.RoomTypeID, &t.Name); err != nil {
			log.Printf("GetRoomTypes scan: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		types = append(types, t)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(types)
}

func CreateRoomType(w http.ResponseWriter, r *http.Request) {
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
        INSERT INTO room_type (clinic_id, name)
        VALUES ($1, $2)
    `, claims.ClinicID, name)
	if err != nil {
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgUniqueViolation {
			http.Error(w, "Tipo de sala já cadastrado", http.StatusConflict)
			return
		}
		log.Printf("CreateRoomType: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func DeleteRoomType(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	typeID, ok := queryID(w, r)
	if !ok {
		return
	}

	result, err := db.DB.Exec(`
        DELETE FROM room_type
        WHERE room_type_id = $1 AND clinic_id = $2
    `, typeID, claims.ClinicID)
	if err != nil {
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgForeignKeyViolation {
			http.Error(w, "Há salas deste tipo. Altere-as antes de excluir.", http.StatusConflict)
			return
		}
		log.Printf("DeleteRoomType: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Tipo de sala não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ---------------------------------------------------------------- salas

type roomResponse struct {
	RoomID         int    `json:"room_id"`
	Name           string `json:"name"`
	RoomTypeID     int    `json:"room_type_id"`
	RoomTypeName   string `json:"room_type_name"`
	Resources      string `json:"resources"` // um recurso por linha
	ProcedureCount int    `json:"procedure_count"`
}

type roomInput struct {
	Name       string `json:"name"`
	RoomTypeID int    `json:"room_type_id"`
	Resources  string `json:"resources"`
}

// normalize valida e padroniza o corpo. Retorna a mensagem de erro (400).
func (in *roomInput) normalize() string {
	in.Name = strings.TrimSpace(in.Name)
	in.Resources = cleanHealthList(in.Resources) // um item por linha, sem vazios

	if in.Name == "" || len([]rune(in.Name)) > 100 {
		return "Informe um nome de até 100 caracteres"
	}
	if in.RoomTypeID <= 0 {
		return "Selecione o tipo da sala"
	}
	return ""
}

// GetRooms lista as salas da clínica com tipo, recursos e quantos
// procedimentos usam cada uma.
func GetRooms(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	rows, err := db.DB.Query(`
        SELECT r.room_id,
               r.name,
               r.room_type_id,
               rt.name,
               COALESCE(r.resources, ''),
               (SELECT count(*) FROM procedure p WHERE p.room_id = r.room_id)
        FROM room r
        JOIN room_type rt ON rt.room_type_id = r.room_type_id
        WHERE r.clinic_id = $1
        ORDER BY r.name
    `, claims.ClinicID)
	if err != nil {
		log.Printf("GetRooms: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	rooms := []roomResponse{}

	for rows.Next() {
		var room roomResponse
		if err := rows.Scan(
			&room.RoomID,
			&room.Name,
			&room.RoomTypeID,
			&room.RoomTypeName,
			&room.Resources,
			&room.ProcedureCount,
		); err != nil {
			log.Printf("GetRooms scan: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		rooms = append(rooms, room)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(rooms)
}

// roomTypeBelongsToClinic confere que o tipo é da clínica do usuário.
func roomTypeBelongsToClinic(clinicID, typeID int) (bool, error) {
	var ok bool
	err := db.DB.QueryRow(`
        SELECT EXISTS (
            SELECT 1 FROM room_type
            WHERE room_type_id = $1 AND clinic_id = $2
        )
    `, typeID, clinicID).Scan(&ok)

	return ok, err
}

func writeRoomError(w http.ResponseWriter, op string, err error) {
	if pqErr, ok := pgError(err); ok {
		switch pqErr.Code {
		case pgUniqueViolation:
			http.Error(w, "Já existe uma sala com este nome", http.StatusConflict)
			return
		case pgForeignKeyViolation:
			http.Error(w, "Tipo de sala inválido", http.StatusBadRequest)
			return
		}
	}

	log.Printf("%s: %v", op, err)
	http.Error(w, "Internal server error", http.StatusInternalServerError)
}

func CreateRoom(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	var in roomInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if msg := in.normalize(); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}

	ok, err := roomTypeBelongsToClinic(claims.ClinicID, in.RoomTypeID)
	if err != nil {
		log.Printf("CreateRoom type check: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if !ok {
		http.Error(w, "Tipo de sala inválido", http.StatusBadRequest)
		return
	}

	_, err = db.DB.Exec(`
        INSERT INTO room (clinic_id, name, room_type_id, resources, updated_by)
        VALUES ($1, $2, $3, NULLIF($4, ''), $5)
    `, claims.ClinicID, in.Name, in.RoomTypeID, in.Resources, claims.UserID)
	if err != nil {
		writeRoomError(w, "CreateRoom", err)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func UpdateRoom(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	roomID, ok := queryID(w, r)
	if !ok {
		return
	}

	var in roomInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if msg := in.normalize(); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}

	valid, err := roomTypeBelongsToClinic(claims.ClinicID, in.RoomTypeID)
	if err != nil {
		log.Printf("UpdateRoom type check: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if !valid {
		http.Error(w, "Tipo de sala inválido", http.StatusBadRequest)
		return
	}

	result, err := db.DB.Exec(`
        UPDATE room
        SET name = $1,
            room_type_id = $2,
            resources = NULLIF($3, ''),
            updated_by = $4
        WHERE room_id = $5
        AND clinic_id = $6
    `, in.Name, in.RoomTypeID, in.Resources, claims.UserID, roomID, claims.ClinicID)
	if err != nil {
		writeRoomError(w, "UpdateRoom", err)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Sala não encontrada", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func DeleteRoom(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	roomID, ok := queryID(w, r)
	if !ok {
		return
	}

	result, err := db.DB.Exec(`
        DELETE FROM room
        WHERE room_id = $1 AND clinic_id = $2
    `, roomID, claims.ClinicID)
	if err != nil {
		if pqErr, ok := pgError(err); ok && pqErr.Code == pgForeignKeyViolation {
			http.Error(w, "A sala possui procedimentos ou agendamentos e não pode ser excluída", http.StatusConflict)
			return
		}
		log.Printf("DeleteRoom: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Sala não encontrada", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// roomOfProcedure devolve a sala do procedimento (validando a clínica).
// found=false se o procedimento não existir nesta clínica.
func roomOfProcedure(clinicID, procedureID int) (roomID int, found bool, err error) {
	err = db.DB.QueryRow(`
        SELECT room_id FROM procedure
        WHERE procedure_id = $1 AND clinic_id = $2
    `, procedureID, clinicID).Scan(&roomID)
	if errors.Is(err, sql.ErrNoRows) {
		return 0, false, nil
	}

	return roomID, err == nil, err
}

// liveRoom é uma sala no painel "atendimentos em andamento".
type liveRoom struct {
	RoomID       int                 `json:"room_id"`
	Name         string              `json:"name"`
	RoomTypeName string              `json:"room_type_name"`
	Current      *models.Appointment `json:"current"` // em atendimento agora
	Next         *models.Appointment `json:"next"`    // próximo de hoje
}

// GetLiveRooms mostra, por sala, o atendimento em andamento e o próximo
// agendamento do dia, para a recepção saber o que acontece em cada sala.
//
//	GET /rooms/live
func GetLiveRooms(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	rooms := []*liveRoom{}
	byID := map[int]*liveRoom{}

	roomRows, err := db.DB.Query(`
        SELECT r.room_id, r.name, rt.name
        FROM room r
        JOIN room_type rt ON rt.room_type_id = r.room_type_id
        WHERE r.clinic_id = $1
        ORDER BY r.name
    `, claims.ClinicID)
	if err != nil {
		log.Printf("GetLiveRooms rooms: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer roomRows.Close()

	for roomRows.Next() {
		var lr liveRoom
		if err := roomRows.Scan(&lr.RoomID, &lr.Name, &lr.RoomTypeName); err != nil {
			log.Printf("GetLiveRooms scan room: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		item := lr
		rooms = append(rooms, &item)
		byID[item.RoomID] = &item
	}
	if err := roomRows.Err(); err != nil {
		log.Printf("GetLiveRooms rooms rows: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Em atendimento (qualquer dia: o atendimento só termina ao finalizar).
	current, err := db.DB.Query(appointmentSelect+`
        WHERE a.clinic_id = $1
          AND a.status = 'in_progress'
          AND a.room_id IS NOT NULL
        ORDER BY a.started_at DESC NULLS LAST
    `, claims.ClinicID)
	if err != nil {
		log.Printf("GetLiveRooms current: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer current.Close()

	for current.Next() {
		a, err := scanAppointment(current)
		if err != nil {
			log.Printf("GetLiveRooms scan current: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		if lr, ok := byID[a.RoomID]; ok && lr.Current == nil {
			item := a
			lr.Current = &item
		}
	}

	// Próximos do dia (ainda não iniciados e que não terminaram).
	now := clinicNow()

	upcoming, err := db.DB.Query(appointmentSelect+`
        WHERE a.clinic_id = $1
          AND a.status IN ('scheduled', 'confirmed')
          AND a.room_id IS NOT NULL
          AND a.ends_at > $2::timestamp
          AND a.starts_at < ($2::timestamp)::date + 1
        ORDER BY a.starts_at, a.appointment_id
    `, claims.ClinicID, now)
	if err != nil {
		log.Printf("GetLiveRooms upcoming: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer upcoming.Close()

	for upcoming.Next() {
		a, err := scanAppointment(upcoming)
		if err != nil {
			log.Printf("GetLiveRooms scan upcoming: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		if lr, ok := byID[a.RoomID]; ok && lr.Next == nil {
			item := a
			lr.Next = &item
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(rooms)
}
