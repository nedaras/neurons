package main

import (
	"learning/ai/pkg/handlers"
	"log"
	"net/http"
)

////go:embed public/*
//var publicFiles embed.FS

func main() {
	router := http.NewServeMux()
	fs := http.FileServer(http.Dir("public"))

	//contentFS, err := fs.Sub(publicFiles, "public")
	//if err != nil {
		//log.Fatal(err)
	//}

	//router.Handle("/", http.FileServer(http.FS(contentFS)))

	router.Handle("/", fs)
	router.HandleFunc("/{$}", unwrap(handlers.HandleIndex))

	log.Fatal(http.ListenAndServe(":8080", router))
}

func unwrap(handler func(w http.ResponseWriter, r *http.Request) error) func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		if err := handler(w, r); err != nil {
			log.Fatal(err)
		}
	}
}
