package cmd

import (
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "mkweb",
	Short: "mkweb es un creador de proyectos para web",
	Long:  "mkweb es un creador de proyectos para web (vanilla y phaser, en JavaScript o TypeScript).",
}

// Execute es el punto de entrada del CLI.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}
