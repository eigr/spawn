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

	// Copiar os arquivos
	if err := copier.CopyDir(srcDir, destDir); err != nil {
		log.Fatalf("Erro ao copiar arquivos: %v", err)
	}
	log.Println("Arquivos copiados com sucesso.")

	// Executar o comando do usuário
	if len(os.Args) > 1 {
		if err := runner.RunCommand(os.Args[1], os.Args[2:]...); err != nil {
			log.Fatalf("Erro ao executar o comando: %v", err)
		}
	} else {
		log.Println("Nenhum comando especificado. Finalizando...")
	}
}
