package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"sdk-init/pkg/copier"
	"sdk-init/pkg/runner"
)

func main() {
	srcDir := getEnv("SRC_DIR", "/protos")
	destDir := getEnv("DEST_DIR", "/shared/protos")

	if err := copier.CopyDir(srcDir, destDir); err != nil {
		log.Fatalf("Error copying files: %v", err)
	}
	log.Println("Files copied successfully.")

	// Configure the channel to capture system signals
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	if len(os.Args) > 1 {
		cmd, err := runner.RunCommandAsync(os.Args[1], os.Args[2:]...)
		if err != nil {
			log.Fatalf("Error starting command: %v", err)
		}

		// Waits for signals and passes to subprocess
		go func() {
			sig := <-sigChan
			log.Printf("Received signal: %v. Forwarding to subprocess...", sig)
			if err := cmd.Process.Signal(sig); err != nil {
				log.Printf("Error forwarding signal to subprocess: %v", err)
			}
		}()

		// Wait for the subprocess to finish...
		if err := cmd.Wait(); err != nil {
			log.Fatalf("Subprocess terminated with error: %v", err)
		} else {
			log.Println("Subprocess terminated successfully.")
		}
	} else {
		log.Println("No command specified. Finishing...")
	}
}

func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}