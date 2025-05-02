package handlers

import (
	"learning/ai/src/views"
	"net/http"
)

func HandleIndex(w http.ResponseWriter, r *http.Request) error {
		return views.Index().Render(r.Context(), w)
}
