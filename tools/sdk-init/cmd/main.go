package main

import (
	"log"
	"os"

	"sdk-init/pkg/copier"
	"sdk-init/pkg/runner"
)

func main() {
	srcDir := "/protos"
	destDir := "/shared/protos"

	if err := copier.CopyDir(srcDir, destDir); err != nil {
		log.Fatalf("Error copying files: %v", err)
	}
	log.Println("Files copied successfully.")

	if len(os.Args) > 1 {
		if err := runner.RunCommand(os.Args[1], os.Args[2:]...); err != nil {
			log.Fatalf("Error executing command: %v", err)
		}
	} else {
		log.Println("No command specified. Finishing...")
	}
}
