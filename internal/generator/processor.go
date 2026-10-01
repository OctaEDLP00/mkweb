package generator

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// WriteFile crea los directorios padres y escribe content en root/rel.
func WriteFile(root, rel, content string) error {
	full := filepath.Join(root, rel)
	if err := os.MkdirAll(filepath.Dir(full), 0o755); err != nil {
		return err
	}
	return os.WriteFile(full, []byte(content), 0o644)
}

// MarkEmptyDirsWithGitkeep recorre root y crea un .gitkeep en cada
// directorio vacío (equivale al find ... -empty de mkweb.sh).
func MarkEmptyDirsWithGitkeep(root string) error {
	var dirs []string
	err := filepath.WalkDir(root, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			dirs = append(dirs, path)
		}
		return nil
	})
	if err != nil {
		return err
	}
	// De más profundo a más superficial para detectar vacíos reales.
	for i := len(dirs) - 1; i >= 0; i-- {
		entries, err := os.ReadDir(dirs[i])
		if err != nil {
			return err
		}
		if len(entries) == 0 {
			if err := os.WriteFile(filepath.Join(dirs[i], ".gitkeep"), []byte{}, 0o644); err != nil {
				return err
			}
		}
	}
	return nil
}

// EnsureProjectDir valida que el destino no exista (equivale al
// `[[ -e "$PROJECT_FOLDER" ]]` de mkweb.sh).
func EnsureProjectDir(name string) error {
	if strings.TrimSpace(name) == "" {
		return fmt.Errorf("project name is required")
	}
	if _, err := os.Stat(name); err == nil {
		return fmt.Errorf("directory already exists: %s", name)
	} else if !os.IsNotExist(err) {
		return err
	}
	return nil
}
