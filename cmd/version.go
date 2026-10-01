package cmd

import (
	"fmt"

	"github.com/spf13/cobra"

	"mkweb/internal/config"
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Mostrar la versión del CLI",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("mkweb %s\n", config.Version)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
