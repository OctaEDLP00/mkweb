// Package variants comparte la carga y el renderizado de los archivos de
// plantilla que viven en disco bajo variants/common/ y
// variants/<tech>/<lang>/.
//
// Cada archivo se interpreta como text/template con las variables
// {{.ProjectName}} y {{.Template}} (ver templates.Vars).
package variants

import (
	"embed"
	"fmt"
	"io/fs"
	"strings"
	"text/template"

	"github.com/OctaEDLP00/mkweb/internal/templates"
)

// Los dotfiles (.editorconfig, .gitignore) se nombran explícitos porque
// el patrón de directorio los excluiría (embed omite archivos que
// empiezan con '.' o '_' al expandir directorios).
//
//go:embed common/.editorconfig common/.gitignore common/README.md common/public/favicon.svg
var commonFS embed.FS

var commonParsed = MustParse(MustSub(commonFS, "common"))

// MustSub devuelve el subárbol dir de un FS embebido o falla en el arranque.
func MustSub(files embed.FS, dir string) fs.FS {
	sub, err := fs.Sub(files, dir)
	if err != nil {
		panic(fmt.Sprintf("variants: subárbol %q: %v", dir, err))
	}
	return sub
}

// MustParse parsea como text/template todos los archivos de fsys.
// Falla en el arranque si alguna plantilla no compila, para detectar
// errores de edición sin tener que generar un proyecto.
func MustParse(fsys fs.FS) map[string]*template.Template {
	out := map[string]*template.Template{}
	err := fs.WalkDir(fsys, ".", func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		raw, err := fs.ReadFile(fsys, p)
		if err != nil {
			return err
		}
		t, err := template.New(p).Parse(string(raw))
		if err != nil {
			return fmt.Errorf("plantilla %s: %w", p, err)
		}
		out[p] = t
		return nil
	})
	if err != nil {
		panic(fmt.Sprintf("variants: %v", err))
	}
	return out
}

// Render ejecuta las plantillas parseadas con vars y devuelve
// ruta relativa -> contenido final.
func Render(parsed map[string]*template.Template, vars templates.Vars) (map[string]string, error) {
	out := make(map[string]string, len(parsed))
	for name, t := range parsed {
		var b strings.Builder
		if err := t.Execute(&b, vars); err != nil {
			return nil, fmt.Errorf("plantilla %s: %w", name, err)
		}
		out[name] = b.String()
	}
	return out, nil
}

// CommonFiles renderiza los archivos compartidos de variants/common/
// (.editorconfig, .gitignore, README.md, public/favicon.svg).
func CommonFiles(vars templates.Vars) (map[string]string, error) {
	return Render(commonParsed, vars)
}
