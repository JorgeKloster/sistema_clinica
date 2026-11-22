package handlers

import (
	"errors"
	"go-backend/middleware"
	"log"
	"net/http"
	"os"
	"strconv"
	"sync"
	"time"
	_ "time/tzdata" // embute os fusos: não depende do sistema da imagem

	"github.com/lib/pq"
)

// Código SQLSTATE do Postgres para os erros de constraint que tratamos.
const (
	pgUniqueViolation     = "23505"
	pgForeignKeyViolation = "23503"
	pgCheckViolation      = "23514"
	pgExclusionViolation  = "23P01"
	pgNotNullViolation    = "23502"
)

// requireAdmin responde 403 e retorna false se o usuário logado não for admin.
func requireAdmin(w http.ResponseWriter, r *http.Request) bool {
	if middleware.GetClaims(r).Role != "admin" {
		http.Error(w, "Acesso restrito a administradores", http.StatusForbidden)
		return false
	}
	return true
}

// parsePositiveInt converte s em um inteiro maior que zero.
func parsePositiveInt(s string) (int, bool) {
	n, err := strconv.Atoi(s)
	if err != nil || n <= 0 {
		return 0, false
	}
	return n, true
}

// queryID lê o parâmetro ?id= e responde 400 se for inválido.
func queryID(w http.ResponseWriter, r *http.Request) (int, bool) {
	id, ok := parsePositiveInt(r.URL.Query().Get("id"))
	if !ok {
		http.Error(w, "Invalid id", http.StatusBadRequest)
		return 0, false
	}
	return id, true
}

// pgError devolve o *pq.Error contido em err, se houver.
func pgError(err error) (*pq.Error, bool) {
	var pqErr *pq.Error
	if errors.As(err, &pqErr) {
		return pqErr, true
	}
	return nil, false
}

var (
	clinicLocOnce sync.Once
	clinicLoc     *time.Location
)

// clinicLocation é o fuso da clínica (CLINIC_TIMEZONE, padrão
// America/Sao_Paulo). Os horários dos agendamentos são guardados "sem fuso"
// nesse horário local; usar o relógio/fuso do banco ou do servidor aqui
// misturaria referências.
func clinicLocation() *time.Location {
	clinicLocOnce.Do(func() {
		name := os.Getenv("CLINIC_TIMEZONE")
		if name == "" {
			name = "America/Sao_Paulo"
		}

		loc, err := time.LoadLocation(name)
		if err != nil {
			log.Printf("CLINIC_TIMEZONE %q inválido (%v); usando UTC", name, err)
			loc = time.UTC
		}

		clinicLoc = loc
	})

	return clinicLoc
}

// clinicNow é o "agora" no horário local da clínica, no formato do banco.
func clinicNow() string {
	return time.Now().In(clinicLocation()).Format(appointmentTimeLayout)
}

// isPastLocal diz se um horário local da clínica (formato do banco) já
// passou. A precisão é de minuto: o minuto atual ainda conta como livre.
// Os dois lados estão no mesmo formato, então comparar texto basta.
func isPastLocal(local string) bool {
	now := time.Now().In(clinicLocation()).Truncate(time.Minute)

	return local < now.Format(appointmentTimeLayout)
}

// elapsedSince devolve os segundos desde um horário local da clínica.
func elapsedSince(local string) int {
	t, err := time.ParseInLocation(appointmentTimeLayout, local, clinicLocation())
	if err != nil {
		return 0
	}

	if seconds := int(time.Since(t).Seconds()); seconds > 0 {
		return seconds
	}

	return 0
}
