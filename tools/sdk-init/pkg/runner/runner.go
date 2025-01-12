package runner

import (
	"os"
	"os/exec"
)

// RunCommand executa o comando especificado com argumentos.
func RunCommand(cmd string, args ...string) error {
	command := exec.Command(cmd, args...)
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr

	return command.Run()
}
