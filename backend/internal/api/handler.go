package api

import (
	"encoding/json"
	"log"
	"net/http"
)

type Response struct {
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

func WriteJSON(w http.ResponseWriter, status int, v interface{}) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	return json.NewEncoder(w).Encode(v)
}

func WriteError(w http.ResponseWriter, status int, message string) {
	if err := WriteJSON(w, status, Response{Error: message}); err != nil {
		// Log the error or handle it appropriately
		log.Printf("Failed to write JSON response: %v", err)
	}
}
