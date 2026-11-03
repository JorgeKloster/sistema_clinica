package middleware

import (
	"context"
	"net/http"
	"os"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/joho/godotenv"
)

var _ = godotenv.Load("middleware/.env")

var JwtKey = []byte(os.Getenv("JWT_SECRET"))

type Claims struct {
	UserID   int    `json:"user_id"`
	ClinicID int    `json:"clinic_id"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

type contextKey string

const ClaimsContextKey contextKey = "claims"

func JWTMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		authHeader := r.Header.Get("Authorization")

		if authHeader == "" {
			http.Error(
				w,
				"Missing Authorization header",
				http.StatusUnauthorized,
			)
			return
		}

		tokenString := strings.TrimPrefix(
			authHeader,
			"Bearer ",
		)

		claims := &Claims{}

		token, err := jwt.ParseWithClaims(
			tokenString,
			claims,
			func(token *jwt.Token) (interface{}, error) {
				return JwtKey, nil
			},
		)

		if err != nil || !token.Valid {
			http.Error(
				w,
				"Invalid token",
				http.StatusUnauthorized,
			)
			return
		}

		ctx := context.WithValue(
			r.Context(),
			ClaimsContextKey,
			claims,
		)

		next.ServeHTTP(
			w,
			r.WithContext(ctx),
		)
	})
}

func GetClaims(
	r *http.Request,
) *Claims {
	return r.Context().
		Value(ClaimsContextKey).(*Claims)
}
