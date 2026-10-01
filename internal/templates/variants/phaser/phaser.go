package phaser

import (
	"embed"

	"github.com/OctaEDLP00/mkweb/internal/templates"
	"github.com/OctaEDLP00/mkweb/internal/templates/variants"
)

//go:embed js ts
var files embed.FS

var (
	jsParsed = variants.MustParse(variants.MustSub(files, "js"))
	tsParsed = variants.MustParse(variants.MustSub(files, "ts"))
)

func init() {
	templates.Register(templates.Template{
		Name:         "phaser",
		Description:  "Phaser JavaScript",
		Tech:         "phaser",
		Language:     "js",
		IsTypeScript: false,
		Folders: []string{
			"public/assets/audio",
			"public/assets/font",
			"public/assets/ui",
			"src/modules",
			"src/scenes",
		},
		Files: func(v templates.Vars) (map[string]string, error) {
			return variants.Render(jsParsed, v)
		},
	})

	templates.Register(templates.Template{
		Name:         "phaser-ts",
		Description:  "Phaser TypeScript",
		Tech:         "phaser",
		Language:     "ts",
		IsTypeScript: true,
		Folders: []string{
			"public/assets/audio",
			"public/assets/font",
			"public/assets/ui",
			"src/modules",
			"src/scenes",
			"src/types",
		},
		Files: func(v templates.Vars) (map[string]string, error) {
			return variants.Render(tsParsed, v)
		},
	})
}
