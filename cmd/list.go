package cmd

import (
	"github.com/spf13/cobra"

	"github.com/OctaEDLP00/mkweb/internal/templates"
	"github.com/OctaEDLP00/mkweb/internal/ui"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "Mostrar las plantillas disponibles",
	Run: func(cmd *cobra.Command, args []string) {
		ui.Write(ui.White + "Templates:" + ui.Reset)
		for _, t := range templates.List() {
			ui.Write("    " + ui.Purple + t.Name + ui.Reset + "   " + ui.Yellow + t.Description + ui.Reset)
		}
	},
}

func init() {
	rootCmd.AddCommand(listCmd)
}
