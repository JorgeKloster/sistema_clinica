package main

import (
    "database/sql"
    "encoding/json"
    "log"
    "net/http"
    _ "github.com/lib/pq"
)

var db *sql.DB

func main() {
    connStr := "host=postgres user=postgres password=secret dbname=postgres sslmode=disable"
    var err error
    db, err = sql.Open("postgres", connStr)
    if err != nil {
        log.Fatal(err)
    }

    http.HandleFunc("/patients", getPatients)
    log.Println("Backend running on port 8080...")
    log.Fatal(http.ListenAndServe(":8080", nil))
}

func getPatients(w http.ResponseWriter, r *http.Request) {
    rows, err := db.Query("SELECT patient_id, name FROM patients")
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    var patients []map[string]interface{}
    for rows.Next() {
        var id int
        var name string
        rows.Scan(&id, &name)
        patients = append(patients, map[string]interface{}{"id": id, "name": name})
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(patients)
}