// Package pm resuelve gestores de paquetes: valida el nombre, obtiene la
// versión instalada (`<pm> --version`) y ejecuta la instalación.
package pm

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"time"
)

// Managers son los gestores aceptados, en el orden en que se ofrecen.
var Managers = []string{"pnpm", "npm", "yarn", "bun", "nube", "nub", "utoo", "upm"}

// IsValid indica si name es un gestor conocido.
func IsValid(name string) bool {
	for _, m := range Managers {
		if name == m {
			return true
		}
	}
	return false
}

var semverRe = regexp.MustCompile(`\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?`)

// ParseVersion extrae el primer token semver de la salida de `<pm> --version`
// (ej. "11.16.0\n" -> "11.16.0", "v1.4.2" -> "1.4.2").
func ParseVersion(output string) (string, error) {
	v := semverRe.FindString(output)
	if v == "" {
		return "", fmt.Errorf("no se pudo interpretar la versión en %q", output)
	}
	return v, nil
}

// Resolve devuelve el spec "<pm>@<semver>" con la versión instalada.
// Para npm, `npm --version` refleja el npm del Node activo, que es justo
// lo que pide el contrato de packageManager.
func Resolve(name string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	out, err := exec.CommandContext(ctx, name, "--version").Output()
	if err != nil {
		return "", fmt.Errorf("%s no está instalado o no respondió: %w", name, err)
	}
	v, err := ParseVersion(string(out))
	if err != nil {
		return "", fmt.Errorf("%s: %w", name, err)
	}
	return name + "@" + v, nil
}

// Install ejecuta `<pm> install` en dir, heredando stdin/stdout/stderr
// para que el progreso sea visible.
func Install(dir, name string) error {
	cmd := exec.Command(name, "install")
	cmd.Dir = dir
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("%s install: %w", name, err)
	}
	return nil
}
