package runner

import (
	"os"
	"os/exec"
)

func RunCommandAsync(cmd string, args ...string) (*exec.Cmd, error) {
	command := exec.Command(cmd, args...)
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr

	if err := command.Start(); err != nil {
		return nil, err
	}

	return command, nil
}
