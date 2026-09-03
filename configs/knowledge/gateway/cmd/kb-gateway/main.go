package main

import (
	"log"
	"os"

	"kb-gateway/internal/kb"
)

func main() {
	paths, err := kb.DefaultPaths()
	if err != nil {
		log.Fatal(err)
	}
	logger := log.New(os.Stderr, "kb-gateway ", log.LstdFlags)
	if err := kb.ListenAndServe(paths, logger); err != nil {
		logger.Fatal(err)
	}
}
