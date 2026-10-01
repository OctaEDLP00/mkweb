package vanilla

import (
	"embed"

	"mkweb/internal/templates"
	"mkweb/internal/templates/variants"
)

//go:embed js ts
var files embed.FS

var (
	jsParsed = variants.MustParse(variants.MustSub(files, "js"))
	tsParsed = variants.MustParse(variants.MustSub(files, "ts"))
)

func init() {
	templates.Register(templates.Template{
		Name:         "vanilla",
		Description:  "Vanilla JavaScript",
		Tech:         "vanilla",
		Language:     "js",
		IsTypeScript: false,
		Folders: []string{
			"public/assets/audio",
			"public/assets/font",
			"src/modules",
			"src/assets",
		},
		Files: func(v templates.Vars) (map[string]string, error) {
			return variants.Render(jsParsed, v)
		},
	})

	templates.Register(templates.Template{
		Name:         "vanilla-ts",
		Description:  "Vanilla TypeScript",
		Tech:         "vanilla",
		Language:     "ts",
		IsTypeScript: true,
		Folders: []string{
			"public/assets/audio",
			"public/assets/font",
			"src/modules",
			"src/assets",
			"src/types",
		},
		Files: func(v templates.Vars) (map[string]string, error) {
			return variants.Render(tsParsed, v)
		},
	})
}
