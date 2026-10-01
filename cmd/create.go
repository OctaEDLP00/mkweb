package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"mkweb/internal/generator"
	"mkweb/internal/pm"
	"mkweb/internal/templates"
	"mkweb/internal/ui"
)

var (
	createTemplate string
	createName     string
	createPM       string
	createInstall  bool
)

var createCmd = &cobra.Command{
	Use:   "create [name]",
	Short: "Generar un proyecto",
	Long: `Genera un proyecto con la plantilla indicada.

Ejemplos:
  mkweb create my-game --template phaser-ts --pm pnpm
  mkweb create my-game --template phaser
  mkweb create mi-app --template vanilla-ts --pm bun --install
  mkweb create                        (modo interactivo)`,
	Args: cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		name := createName
		if len(args) > 0 && name == "" {
			name = args[0]
		}
		template := createTemplate
		pmName := createPM

		// Fallback interactivo: preguntar lo que no vino por flags
		// (equivale al bloque "Interactive fallback" de mkweb.sh).
		bannerShown := false
		showBanner := func() {
			if !bannerShown {
				ui.Banner()
				bannerShown = true
			}
		}

		if template == "" {
			showBanner()
			t, err := ui.PromptTemplate()
			if err != nil {
				return err
			}
			template = t
		}

		if !templates.IsValid(template) {
			ui.Error(fmt.Sprintf("Unknown template: %s", template))
			return fmt.Errorf("unknown template: %s", template)
		}

		if name == "" {
			showBanner()
			n, err := ui.PromptProjectName()
			if err != nil {
				return err
			}
			name = n
		}

		if pmName == "" {
			showBanner()
			p, err := ui.PromptPackageManager()
			if err != nil {
				return err
			}
			pmName = p
		}

		if !pm.IsValid(pmName) {
			ui.Error(fmt.Sprintf("Unknown package manager: %s", pmName))
			return fmt.Errorf("unknown package manager: %s", pmName)
		}

		// Resuelve "<pm>@<semver>" con la versión instalada. Para npm,
		// `npm --version` refleja el npm del Node activo. Si el gestor no
		// está instalado se genera sin el campo packageManager.
		spec, err := pm.Resolve(pmName)
		if err != nil {
			ui.Warning(fmt.Sprintf("%s no está instalado: se genera sin campo packageManager", pmName))
			spec = ""
		}

		if err := generator.Generate(generator.Options{
			ProjectName:    name,
			TemplateName:   template,
			PackageManager: spec,
		}); err != nil {
			return err
		}

		doInstall := createInstall
		if !createInstall && bannerShown {
			doInstall, err = ui.PromptInstall(pmName)
			if err != nil {
				return err
			}
		}

		if doInstall {
			ui.Info(fmt.Sprintf("Instalando dependencias con %s...", pmName))
			if err := pm.Install(name, pmName); err != nil {
				return err
			}
			ui.Success("Dependencias instaladas")
			ui.NextStepsInstalled(name, pmName)
			return nil
		}

		ui.NextSteps(name, pmName)
		return nil
	},
}

func init() {
	createCmd.Flags().StringVarP(&createTemplate, "template", "t", "", "Project template (vanilla, vanilla-ts, phaser, phaser-ts)")
	createCmd.Flags().StringVarP(&createName, "name", "n", "", "Project name")
	createCmd.Flags().StringVarP(&createPM, "pm", "p", "", "Package manager (pnpm, npm, yarn, bun, nube, nub, utoo, upm)")
	createCmd.Flags().BoolVar(&createInstall, "install", false, "Instalar dependencias tras crear el proyecto")
	rootCmd.AddCommand(createCmd)
}
