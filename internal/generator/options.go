package generator

// Options son los parámetros para generar un proyecto
// (equivale a las variables PROJECT_NAME/TEMPLATE en mkweb.sh).
type Options struct {
	ProjectName  string
	TemplateName string
	// PackageManager es el spec "<pm>@<semver>" o "" para omitirlo.
	PackageManager string
}
