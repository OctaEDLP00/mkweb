package ui

const (
	Reset  = "\x1b[0m"
	Bold   = "\x1b[1m"
	Dim    = "\x1b[2m"
	Hidden = "\x1b[8m"

	Black  = "\x1b[0;90m"
	Red    = "\x1b[0;91m"
	Green  = "\x1b[0;92m"
	Yellow = "\x1b[0;93m"
	Blue   = "\x1b[0;94m"
	Purple = "\x1b[0;95m"
	Cyan   = "\x1b[0;96m"
	White  = "\x1b[0;97m"

	Muted = "\x1b[0;2m"
)

// Colorize envuelve s con el color dado y resetea al final.
func Colorize(color, s string) string {
	return color + s + Reset
}
