package ui

import "fmt"

// Enter imprime una línea en blanco.
func Enter() {
	fmt.Println()
}

// Write imprime texto tal cual (interpreta secuencias ANSI).
func Write(s string) {
	fmt.Println(s)
}

// Error imprime un mensaje de error: "[x] msg" en rojo.
func Error(msg string) {
	fmt.Printf("%s[x]%s %s\n", Red, Reset, msg)
}

// Success imprime un mensaje de éxito: "[✓] msg" en verde.
func Success(msg string) {
	fmt.Printf("%s[✓]%s %s\n", Green, Reset, msg)
}

// Warning imprime un mensaje de aviso: "[!] msg" en amarillo.
func Warning(msg string) {
	fmt.Printf("%s[!]%s %s\n", Yellow, Reset, msg)
}

// Info imprime un mensaje informativo: "[*] msg" en cyan.
func Info(msg string) {
	fmt.Printf("%s[*]%s %s\n", Cyan, Reset, msg)
}

// Banner muestra el encabezado de mkweb (equivale a banner() en mkweb.sh).
func Banner() {
	Write("  " + Muted + "           _                  _     " + Reset)
	Write("  " + Muted + " _ __ ___ | | ____      _____| |__  " + Reset)
	Write("  " + Muted + "| '_ ` _ \\| |/ /\\ \\ /\\ / / _ \\ '_ \\ " + Reset)
	Write("  " + Muted + "| | | | | |   <  \\ V  V /  __/ |_) |" + Reset)
	Write("  " + Muted + "|_| |_| |_|_|\\_\\  \\_/\\_/ \\___|_.__/ " + Reset)
	Enter()
	Write(Muted + "mkweb es un creador de proyectos para web" + Reset)
	Enter()
}

// NextSteps muestra el comando sugerido cuando no se instalaron dependencias.
func NextSteps(projectName, pmName string) {
	Write("  " + Muted + "cd " + projectName + Reset)
	Write("  " + Muted + pmName + " install" + Reset)
	Write("  " + Muted + pmName + " run dev" + Reset)
	Enter()
	Write("  " + "🎉 Happy Coding!!")
}

// NextStepsInstalled muestra el comando sugerido cuando ya se instalaron.
func NextStepsInstalled(projectName, pmName string) {
	Write("  " + Muted + "cd " + projectName + Reset)
	Write("  " + Muted + pmName + " run dev" + Reset)
	Enter()
	Write("  " + "🎉 Happy Coding!!")
}
