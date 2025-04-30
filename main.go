package main

import (
	"learning/ai/src/views"
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

	router.HandleFunc("/{$}", func(w http.ResponseWriter, r *http.Request) {
		if err := views.Index().Render(r.Context(), w); err != nil {
			log.Fatal(err)
		}
	})

	log.Fatal(http.ListenAndServe(":8080", router))
}
