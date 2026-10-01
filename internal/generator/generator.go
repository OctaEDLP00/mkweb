package generator

import (
	"fmt"
	"os"
	"path/filepath"

	"mkweb/internal/templates"
	"mkweb/internal/templates/variants"
	_ "mkweb/internal/templates/variants/phaser"
	_ "mkweb/internal/templates/variants/vanilla"
	"mkweb/internal/ui"
)

// Generate crea la estructura de directorios y archivos del proyecto.
// Equivale a create_project() en mkweb.sh.
func Generate(opts Options) error {
	tpl, err := templates.Get(opts.TemplateName)
	if err != nil {
		return err
	}

	if err := EnsureProjectDir(opts.ProjectName); err != nil {
		return err
	}

	root := opts.ProjectName
	vars := templates.Vars{ProjectName: opts.ProjectName, Template: tpl.Name, PackageManager: opts.PackageManager}

	ui.Info(fmt.Sprintf("%s template selected", tpl.Name))
	ui.Info(fmt.Sprintf("project folder: %s", opts.ProjectName))

	// 1. Crear carpetas de la plantilla.
	for _, folder := range tpl.Folders {
		if err := os.MkdirAll(filepath.Join(root, folder), 0o755); err != nil {
			return err
		}
	}

	// 2. Combinar archivos base (variants/common/) + archivos de la variante.
	all, err := variants.CommonFiles(vars)
	if err != nil {
		return err
	}
	own, err := tpl.Files(vars)
	if err != nil {
		return fmt.Errorf("template %s: %w", tpl.Name, err)
	}
	for rel, content := range own {
		all[rel] = content
	}

	// 3. Escribir todos los archivos.
	for rel, content := range all {
		if err := WriteFile(root, rel, content); err != nil {
			return fmt.Errorf("write %s: %w", rel, err)
		}
	}

	// 4. Mantener carpetas vacías en git.
	if err := MarkEmptyDirsWithGitkeep(root); err != nil {
		return err
	}

	ui.Success(fmt.Sprintf("Project '%s' created with template '%s'", opts.ProjectName, tpl.Name))
	return nil
}
