package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

const DefaultBindAddress = ":8080"
const EnvBindAddress = "BIND_ADDRESS"

func getEnvOrDefault(key string, defaults string) string {
	v := os.Getenv(key)
	if v != "" {
		return v
	}
	return defaults
}

func greet(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello World! %s", time.Now())
}

func health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(200)
}

func main() {
	bindAddress := getEnvOrDefault(EnvBindAddress, DefaultBindAddress)
	log.Println("App started. Will listen on", bindAddress)

	http.HandleFunc("/", greet)
	http.HandleFunc("/health", health)

	log.Fatalln(http.ListenAndServe(bindAddress, nil))
}
