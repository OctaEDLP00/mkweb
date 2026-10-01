package config

// Config centraliza las preferencias del CLI.
type Config struct {
	// PackageManager es el gestor de paquetes sugerido en los mensajes finales.
	PackageManager string
}

// Version del CLI (se muestra con `mkweb version`). El CI la inyecta
// con ldflags en cada release; en desarrollo vale "dev".
var Version = "dev"

// DefaultPackageManager es el gestor sugerido por defecto.
const DefaultPackageManager = "npm"

// Default devuelve la configuración por defecto.
func Default() Config {
	return Config{PackageManager: DefaultPackageManager}
}
