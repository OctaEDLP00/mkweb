package templates

// Vars son las variables disponibles en los archivos de plantilla
// ({{.ProjectName}}, {{.Template}} y {{.PackageManager}}).
type Vars struct {
	ProjectName string
	Template    string
	// PackageManager es el spec "<pm>@<semver>" para el campo
	// packageManager, o "" para omitirlo.
	PackageManager string
}

// Template describe una plantilla disponible.
//
// Files devuelve los archivos específicos de la tecnología, leídos del
// árbol en disco variants/<tech>/<lang>/ y renderizados con vars.
// Los archivos base comunes (.editorconfig, .gitignore, README, favicon)
// los aporta variants.CommonFiles, igual que write_base_files() en mkweb.sh.
type Template struct {
	Name         string
	Description  string
	Tech         string
	Language     string
	IsTypeScript bool
	Folders      []string
	Files        func(vars Vars) (map[string]string, error)
}
