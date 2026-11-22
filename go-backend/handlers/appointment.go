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
	"time"
)

const (
	// Horário local da clínica, sem fuso.
	appointmentTimeLayout = "2006-01-02T15:04:05"
	dateLayout            = "2006-01-02"

	// A agenda busca uma semana por vez; o limite evita consultas enormes.
	maxListRangeDays = 62

	msgPastAppointment = "Não é possível agendar em uma data ou horário que já passou"
)

var validAppointmentStatuses = map[string]bool{
	"scheduled":   true,
	"confirmed":   true,
	"in_progress": true,
	"completed":   true,
	"canceled":    true,
}

// appointmentInput é o corpo aceito em create/update. clinic_id e updated_by
// nunca são lidos do corpo.
type appointmentInput struct {
	PatientID   int `json:"patient_id"`
	DoctorID    int `json:"doctor_id"`
	ProcedureID int `json:"procedure_id"`
	// Sala escolhida. Se vier vazia (0), usa a sala sugerida pelo procedimento.
	RoomID   int    `json:"room_id"`
	StartsAt string `json:"starts_at"`
	EndsAt   string `json:"ends_at"`
	Status   string `json:"status"`
	Notes    string `json:"notes"`
}

// parseLocalTime aceita "2006-01-02T15:04:05" e "2006-01-02T15:04".
func parseLocalTime(s string) (time.Time, error) {
	s = strings.TrimSpace(s)
	for _, layout := range []string{appointmentTimeLayout, "2006-01-02T15:04"} {
		if t, err := time.Parse(layout, s); err == nil {
			return t, nil
		}
	}
	return time.Time{}, errors.New("invalid time")
}

// normalize valida e padroniza o corpo. Retorna a mensagem de erro (400)
// ou "" se estiver tudo certo. defaultStatus é usado quando status vem vazio.
func (in *appointmentInput) normalize(defaultStatus string) string {
	in.Notes = strings.TrimSpace(in.Notes)
	in.Status = strings.TrimSpace(in.Status)

	if in.PatientID <= 0 {
		return "Selecione o paciente"
	}
	if in.DoctorID <= 0 {
		return "Selecione o profissional"
	}
	if in.ProcedureID <= 0 {
		return "Selecione o procedimento"
	}

	start, err := parseLocalTime(in.StartsAt)
	if err != nil {
		return "Horário inicial inválido"
	}
	end, err := parseLocalTime(in.EndsAt)
	if err != nil {
		return "Horário final inválido"
	}
	if !end.After(start) {
		return "O horário final deve ser depois do inicial"
	}
	if start.Format(dateLayout) != end.Format(dateLayout) {
		return "O agendamento deve começar e terminar no mesmo dia"
	}
	in.StartsAt = start.Format(appointmentTimeLayout)
	in.EndsAt = end.Format(appointmentTimeLayout)

	if in.Status == "" {
		in.Status = defaultStatus
	}
	if in.Status != "" && !validAppointmentStatuses[in.Status] {
		return "Status inválido"
	}

	return ""
}

// checkAppointmentRefs garante que paciente, profissional, procedimento e
// sala pertencem à clínica do usuário logado, e que o profissional tem o perfil
// "doctor". Retorna a mensagem de erro (400) ou "" se estiver tudo certo;
// err é um erro inesperado do banco (500).
func checkAppointmentRefs(clinicID int, in *appointmentInput) (msg string, err error) {
	var patientOK, doctorOK bool
	var procedureRoom sql.NullInt64

	err = db.DB.QueryRow(`
        SELECT
            EXISTS (SELECT 1 FROM patient   WHERE patient_id   = $1 AND clinic_id = $4),
            EXISTS (SELECT 1 FROM users     WHERE user_id      = $2 AND clinic_id = $4 AND role = 'doctor'),
            (SELECT room_id FROM procedure WHERE procedure_id = $3 AND clinic_id = $4)
    `, in.PatientID, in.DoctorID, in.ProcedureID, clinicID).Scan(&patientOK, &doctorOK, &procedureRoom)
	if err != nil {
		return "", err
	}

	procedureOK := procedureRoom.Valid

	// Sala: a escolhida pelo usuário ou, se não houve escolha, a sugerida
	// pelo procedimento.
	roomOK := true

	if procedureOK && in.RoomID <= 0 {
		in.RoomID = int(procedureRoom.Int64)
	} else if procedureOK {
		err = db.DB.QueryRow(`
            SELECT EXISTS (SELECT 1 FROM room WHERE room_id = $1 AND clinic_id = $2)
        `, in.RoomID, clinicID).Scan(&roomOK)
		if err != nil {
			return "", err
		}
	}

	switch {
	case !patientOK:
		return "Paciente inválido", nil
	case !doctorOK:
		return "Profissional inválido: selecione um profissional de saúde da clínica", nil
	case !procedureOK:
		return "Procedimento inválido", nil
	case !roomOK:
		return "Sala inválida", nil
	}
	return "", nil
}

// writeAppointmentError traduz erros do Postgres (conflito de horário,
// referência inválida...) para respostas da API e responde ao cliente.
func writeAppointmentError(w http.ResponseWriter, op string, err error) {
	if pqErr, ok := pgError(err); ok {
		switch pqErr.Code {
		case pgExclusionViolation:
			if pqErr.Constraint == "appointment_room_no_overlap" {
				http.Error(w, "A sala deste procedimento já está ocupada neste horário", http.StatusConflict)
				return
			}
			http.Error(w, "O profissional já possui um agendamento neste horário", http.StatusConflict)
			return
		case pgForeignKeyViolation, pgCheckViolation:
			http.Error(w, "Dados do agendamento inválidos", http.StatusBadRequest)
			return
		}
	}

	log.Printf("%s: %v", op, err)
	http.Error(w, "Internal server error", http.StatusInternalServerError)
}

// appointmentSelect traz o agendamento já com os nomes de paciente,
// profissional e procedimento. Quem usa acrescenta WHERE/ORDER BY.
const appointmentSelect = `
        SELECT
            a.appointment_id,
            a.clinic_id,
            a.patient_id,
            btrim(COALESCE(p.first_name, '') || ' ' || COALESCE(p.last_name, '')),
            a.doctor_id,
            btrim(u.first_name || ' ' || u.last_name),
            COALESCE(u.specialty, ''),
            a.procedure_id,
            pr.name,
            COALESCE(a.room_id, 0),
            COALESCE(rm.name, ''),
            to_char(a.starts_at, 'YYYY-MM-DD"T"HH24:MI:SS'),
            to_char(a.ends_at,   'YYYY-MM-DD"T"HH24:MI:SS'),
            a.status,
            COALESCE(a.notes, ''),
            COALESCE(to_char(a.started_at,  'YYYY-MM-DD"T"HH24:MI:SS'), ''),
            COALESCE(to_char(a.finished_at, 'YYYY-MM-DD"T"HH24:MI:SS'), ''),
            COALESCE(a.clinical_notes, ''),
            a.created_at,
            a.updated_at,
            COALESCE(a.updated_by, 0)
        FROM appointment a
        JOIN patient   p  ON p.patient_id    = a.patient_id
        JOIN users     u  ON u.user_id       = a.doctor_id
        JOIN procedure pr ON pr.procedure_id = a.procedure_id
        LEFT JOIN room rm ON rm.room_id      = a.room_id`

type rowScanner interface {
	Scan(dest ...any) error
}

func scanAppointment(row rowScanner) (models.Appointment, error) {
	var a models.Appointment

	err := row.Scan(
		&a.AppointmentID,
		&a.ClinicID,
		&a.PatientID,
		&a.PatientName,
		&a.DoctorID,
		&a.DoctorName,
		&a.DoctorSpecialty,
		&a.ProcedureID,
		&a.ProcedureName,
		&a.RoomID,
		&a.RoomName,
		&a.StartsAt,
		&a.EndsAt,
		&a.Status,
		&a.Notes,
		&a.StartedAt,
		&a.FinishedAt,
		&a.ClinicalNotes,
		&a.CreatedAt,
		&a.UpdatedAt,
		&a.UpdatedBy,
	)

	if err == nil && a.Status == "in_progress" && a.StartedAt != "" {
		a.ElapsedSeconds = elapsedSince(a.StartedAt)
	}

	return a, err
}

// GetAppointment devolve um agendamento (usado pela página de atendimento).
//
//	GET /appointments/get?id=12
func GetAppointment(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	appointmentID, ok := queryID(w, r)
	if !ok {
		return
	}

	a, err := scanAppointment(db.DB.QueryRow(appointmentSelect+`
        WHERE a.appointment_id = $1
        AND a.clinic_id = $2
    `, appointmentID, claims.ClinicID))
	if errors.Is(err, sql.ErrNoRows) {
		http.Error(w, "Agendamento não encontrado", http.StatusNotFound)
		return
	}
	if err != nil {
		log.Printf("GetAppointment: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(a)
}

// GetPatientHistory lista os atendimentos anteriores de um paciente (mais
// recentes primeiro), sem os cancelados. exclude omite o atendimento aberto.
//
//	GET /appointments/history?patient_id=5[&exclude=12]
func GetPatientHistory(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)
	q := r.URL.Query()

	patientID, ok := parsePositiveInt(q.Get("patient_id"))
	if !ok {
		http.Error(w, "patient_id inválido", http.StatusBadRequest)
		return
	}

	exclude := 0
	if raw := q.Get("exclude"); raw != "" {
		id, ok := parsePositiveInt(raw)
		if !ok {
			http.Error(w, "exclude inválido", http.StatusBadRequest)
			return
		}
		exclude = id
	}

	rows, err := db.DB.Query(appointmentSelect+`
        WHERE a.clinic_id = $1
          AND a.patient_id = $2
          AND a.status <> 'canceled'
          AND a.appointment_id <> $3
        ORDER BY a.starts_at DESC, a.appointment_id DESC
        LIMIT 50
    `, claims.ClinicID, patientID, exclude)
	if err != nil {
		log.Printf("GetPatientHistory: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	history := []models.Appointment{}

	for rows.Next() {
		a, err := scanAppointment(rows)
		if err != nil {
			log.Printf("GetPatientHistory scan: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		history = append(history, a)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(history)
}

// UpdateClinicalNotes grava as anotações do atendimento.
//
//	PUT /appointments/clinical-notes?id=12   {"clinical_notes": "..."}
func UpdateClinicalNotes(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	appointmentID, ok := queryID(w, r)
	if !ok {
		return
	}

	var in struct {
		ClinicalNotes string `json:"clinical_notes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	result, err := db.DB.Exec(`
        UPDATE appointment
        SET clinical_notes = NULLIF(btrim($1), ''),
            updated_by = $2
        WHERE appointment_id = $3
        AND clinic_id = $4
    `, in.ClinicalNotes, claims.UserID, appointmentID, claims.ClinicID)
	if err != nil {
		log.Printf("UpdateClinicalNotes: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Agendamento não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// GetAppointments lista os agendamentos (sem os cancelados) de um período.
//
//	GET /appointments?from=2026-11-09&to=2026-11-16[&doctor_id=3]
//
// from é inclusivo e to é exclusivo (uma semana = segunda até a segunda seguinte).
func GetAppointments(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)
	q := r.URL.Query()

	from, err := time.Parse(dateLayout, q.Get("from"))
	if err != nil {
		http.Error(w, "Parâmetro from inválido (use AAAA-MM-DD)", http.StatusBadRequest)
		return
	}
	to, err := time.Parse(dateLayout, q.Get("to"))
	if err != nil {
		http.Error(w, "Parâmetro to inválido (use AAAA-MM-DD)", http.StatusBadRequest)
		return
	}
	if !to.After(from) || to.Sub(from) > maxListRangeDays*24*time.Hour {
		http.Error(w, "Período inválido", http.StatusBadRequest)
		return
	}

	doctorID := 0 // 0 = todos os profissionais
	if raw := q.Get("doctor_id"); raw != "" {
		id, ok := parsePositiveInt(raw)
		if !ok {
			http.Error(w, "doctor_id inválido", http.StatusBadRequest)
			return
		}
		doctorID = id
	}

	rows, err := db.DB.Query(appointmentSelect+`
        WHERE a.clinic_id = $1
          AND a.starts_at >= $2::date
          AND a.starts_at <  $3::date
          AND a.status <> 'canceled'
          AND ($4::int = 0 OR a.doctor_id = $4::int)
        ORDER BY a.starts_at, a.appointment_id
    `, claims.ClinicID, from.Format(dateLayout), to.Format(dateLayout), doctorID)
	if err != nil {
		log.Printf("GetAppointments: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	appointments := []models.Appointment{}

	for rows.Next() {
		a, err := scanAppointment(rows)
		if err != nil {
			log.Printf("GetAppointments scan: %v", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		appointments = append(appointments, a)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(appointments)
}

func CreateAppointment(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	var in appointmentInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if msg := in.normalize("scheduled"); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}
	if isPastLocal(in.StartsAt) {
		http.Error(w, msgPastAppointment, http.StatusBadRequest)
		return
	}

	msg, err := checkAppointmentRefs(claims.ClinicID, &in)
	if err != nil {
		log.Printf("CreateAppointment refs: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}

	var id int
	err = db.DB.QueryRow(`
        INSERT INTO appointment (clinic_id, patient_id, doctor_id, procedure_id, room_id, starts_at, ends_at, status, notes, updated_by)
        VALUES ($1, $2, $3, $4, $10, $5::timestamp, $6::timestamp, $7, NULLIF($8, ''), $9)
        RETURNING appointment_id
    `, claims.ClinicID, in.PatientID, in.DoctorID, in.ProcedureID, in.StartsAt, in.EndsAt, in.Status, in.Notes, claims.UserID, in.RoomID).Scan(&id)
	if err != nil {
		writeAppointmentError(w, "CreateAppointment", err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]int{"appointment_id": id})
}

func UpdateAppointment(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	appointmentID, ok := queryID(w, r)
	if !ok {
		return
	}

	var in appointmentInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	// Status vazio na edição = manter o atual.
	if msg := in.normalize(""); msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}

	// Agendamentos que já passaram podem ser corrigidos (procedimento,
	// observações, status...), mas nenhum pode ser movido para o passado.
	var currentStart string
	err := db.DB.QueryRow(`
        SELECT to_char(starts_at, 'YYYY-MM-DD"T"HH24:MI:SS')
        FROM appointment
        WHERE appointment_id = $1
        AND clinic_id = $2
    `, appointmentID, claims.ClinicID).Scan(&currentStart)
	if errors.Is(err, sql.ErrNoRows) {
		http.Error(w, "Agendamento não encontrado", http.StatusNotFound)
		return
	}
	if err != nil {
		log.Printf("UpdateAppointment current start: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if in.StartsAt != currentStart && isPastLocal(in.StartsAt) {
		http.Error(w, msgPastAppointment, http.StatusBadRequest)
		return
	}

	msg, err := checkAppointmentRefs(claims.ClinicID, &in)
	if err != nil {
		log.Printf("UpdateAppointment refs: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if msg != "" {
		http.Error(w, msg, http.StatusBadRequest)
		return
	}

	result, err := db.DB.Exec(`
        UPDATE appointment
        SET
            patient_id   = $1,
            doctor_id    = $2,
            procedure_id = $3,
            room_id      = $11,
            starts_at    = $4::timestamp,
            ends_at      = $5::timestamp,
            status       = COALESCE(NULLIF($6, ''), status),
            notes        = NULLIF($7, ''),
            updated_by   = $8
        WHERE appointment_id = $9
        AND clinic_id = $10
    `, in.PatientID, in.DoctorID, in.ProcedureID, in.StartsAt, in.EndsAt, in.Status, in.Notes, claims.UserID, appointmentID, claims.ClinicID, in.RoomID)
	if err != nil {
		writeAppointmentError(w, "UpdateAppointment", err)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Agendamento não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// UpdateAppointmentStatus muda só o status (confirmar, iniciar, concluir,
// cancelar). Iniciar grava started_at; concluir grava finished_at.
//
//	PUT /appointments/status?id=12   {"status": "canceled"}
func UpdateAppointmentStatus(w http.ResponseWriter, r *http.Request) {
	claims := middleware.GetClaims(r)

	appointmentID, ok := queryID(w, r)
	if !ok {
		return
	}

	var in struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if !validAppointmentStatuses[in.Status] {
		http.Error(w, "Status inválido", http.StatusBadRequest)
		return
	}

	result, err := db.DB.Exec(`
        UPDATE appointment
        SET status = $1::varchar,
            started_at = CASE WHEN $1::varchar = 'in_progress' THEN COALESCE(started_at, $5::timestamp) ELSE started_at END,
            finished_at = CASE WHEN $1::varchar = 'completed' THEN $5::timestamp ELSE finished_at END,
            updated_by = $2
        WHERE appointment_id = $3
        AND clinic_id = $4
    `, in.Status, claims.UserID, appointmentID, claims.ClinicID, clinicNow())
	if err != nil {
		// Reativar um agendamento cancelado pode conflitar com outro horário.
		writeAppointmentError(w, "UpdateAppointmentStatus", err)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Agendamento não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// DeleteAppointment apaga de vez o agendamento (fica no audit_log). Para o dia
// a dia use o status "canceled", que mantém o histórico. Só administradores.
func DeleteAppointment(w http.ResponseWriter, r *http.Request) {
	if !requireAdmin(w, r) {
		return
	}
	claims := middleware.GetClaims(r)

	appointmentID, ok := queryID(w, r)
	if !ok {
		return
	}

	result, err := db.DB.Exec(`
        DELETE FROM appointment
        WHERE appointment_id = $1
        AND clinic_id = $2
    `, appointmentID, claims.ClinicID)
	if err != nil {
		log.Printf("DeleteAppointment: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if n, _ := result.RowsAffected(); n == 0 {
		http.Error(w, "Agendamento não encontrado", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
