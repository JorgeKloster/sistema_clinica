package handlers

import (
	"errors"
	"go-backend/middleware"
	"net/http"
	"strconv"

	"github.com/lib/pq"
)

// Código SQLSTATE do Postgres para os erros de constraint que tratamos.
const (
	pgUniqueViolation     = "23505"
	pgForeignKeyViolation = "23503"
	pgCheckViolation      = "23514"
)

// requireAdmin responde 403 e retorna false se o usuário logado não for admin.
func requireAdmin(w http.ResponseWriter, r *http.Request) bool {
	if middleware.GetClaims(r).Role != "admin" {
		http.Error(w, "Acesso restrito a administradores", http.StatusForbidden)
		return false
	}
	return true
}

// queryID lê o parâmetro ?id= e responde 400 se for inválido.
func queryID(w http.ResponseWriter, r *http.Request) (int, bool) {
	id, err := strconv.Atoi(r.URL.Query().Get("id"))
	if err != nil || id <= 0 {
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
