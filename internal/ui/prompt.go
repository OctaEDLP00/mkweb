package ui

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strings"

	"mkweb/internal/pm"
	"mkweb/internal/templates"
)

// PromptTemplate pregunta la plantilla (equivale a prompt_template() en
// mkweb.sh). En una terminal muestra un selector navegable con ↑/↓;
// sin TTY (pipes) cae al prompt de texto.
func PromptTemplate() (string, error) {
	list := templates.List()
	if len(list) == 0 {
		return "", fmt.Errorf("no hay plantillas registradas")
	}

	if isTTY() {
		display := make([]string, len(list))
		for i, t := range list {
			display[i] = t.Name + "   " + t.Description
		}
		idx, err := SelectOption("Template", display)
		if err == nil {
			return list[idx].Name, nil
		}
		if errors.Is(err, errSelectionAborted) {
			return "", err
		}
		// Si el modo raw no está disponible, se cae al prompt de texto.
		Enter()
	}

	Write(White + "Available templates:" + Reset)
	for _, t := range list {
		Write("    " + Purple + t.Name + Reset + "   " + Yellow + t.Description + Reset)
	}
	Enter()
	names := make([]string, len(list))
	for i, t := range list {
		names[i] = t.Name
	}
	for {
		fmt.Printf("◇ Template [%s]: ", strings.Join(names, "/"))
		template, err := readLine()
		if err != nil {
			return "", fmt.Errorf("template is required")
		}
		if template == "" {
			Error("Template is required")
			return "", fmt.Errorf("template is required")
		}
		if templates.IsValid(template) {
			return template, nil
		}
		Error("Unknown template: " + template + ". Choose one of: " + strings.Join(names, ", "))
	}
}

var stdin = bufio.NewReader(os.Stdin)

func readLine() (string, error) {
	line, err := stdin.ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(line), nil
}

// PromptInstall pregunta si se instalan las dependencias con el gestor
// elegido. Devuelve false ante cualquier respuesta que no sea afirmativa.
func PromptInstall(pmName string) (bool, error) {
	fmt.Printf("◇ Install dependencies with %s now? [y/N]: ", pmName)
	ans, err := readLine()
	if err != nil {
		return false, err
	}
	switch strings.ToLower(ans) {
	case "y", "yes", "s", "si", "sí":
		return true, nil
	default:
		return false, nil
	}
}

// PromptPackageManager pregunta el gestor de paquetes. En una terminal
// muestra un selector navegable con ↑/↓; sin TTY (pipes) cae al prompt
// de texto.
func PromptPackageManager() (string, error) {
	if isTTY() {
		idx, err := SelectOption("Package manager", pm.Managers)
		if err == nil {
			return pm.Managers[idx], nil
		}
		if errors.Is(err, errSelectionAborted) {
			return "", err
		}
		// Si el modo raw no está disponible, se cae al prompt de texto.
		Enter()
	}
	Write(White + "Available package managers:" + Reset)
	for _, m := range pm.Managers {
		Write("    " + Purple + m + Reset)
	}
	Enter()
	for {
		fmt.Printf("◇ Package manager [%s]: ", strings.Join(pm.Managers, "/"))
		name, err := readLine()
		if err != nil {
			return "", fmt.Errorf("package manager is required")
		}
		if name == "" {
			Error("Package manager is required")
			return "", fmt.Errorf("package manager is required")
		}
		if pm.IsValid(name) {
			return name, nil
		}
		Error("Unknown package manager: " + name + ". Choose one of: " + strings.Join(pm.Managers, ", "))
	}
}

// PromptProjectName pregunta el nombre del proyecto
// (equivale a prompt_project_name() en mkweb.sh).
func PromptProjectName() (string, error) {
	fmt.Print("◇ Project name: ")
	name, err := readLine()
	if err != nil {
		Error("Project name is required")
		return "", fmt.Errorf("project name is required")
	}
	if strings.TrimSpace(name) == "" {
		Error("Project name is required")
		return "", fmt.Errorf("project name is required")
	}
	return name, nil
}
