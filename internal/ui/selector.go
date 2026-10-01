package ui

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
)

// errSelectionAborted indica que el usuario canceló el selector.
var errSelectionAborted = errors.New("selección cancelada")

type selKey int

const (
	selOther selKey = iota
	selUp
	selDown
	selEnter
	selAbort
)

// classifyKey interpreta una secuencia de teclas ya leída:
// Enter confirma, q/Q/Ctrl+C cancela, ESC[A / ESC[B son ↑/↓.
func classifyKey(seq []byte) selKey {
	if len(seq) == 1 {
		switch seq[0] {
		case '\r', '\n':
			return selEnter
		case 'q', 'Q', 0x03:
			return selAbort
		}
		return selOther
	}
	if len(seq) == 3 && seq[0] == 0x1b && seq[1] == '[' {
		switch seq[2] {
		case 'A':
			return selUp
		case 'B':
			return selDown
		}
	}
	return selOther
}

// moveIndex desplaza la selección con wrap-around.
func moveIndex(idx, n int, k selKey) int {
	switch k {
	case selUp:
		return (idx - 1 + n) % n
	case selDown:
		return (idx + 1) % n
	default:
		return idx
	}
}

// isTTY indica si stdin es una terminal (solo ahí funciona el selector).
func isTTY() bool {
	st, err := os.Stdin.Stat()
	if err != nil {
		return false
	}
	return st.Mode()&os.ModeCharDevice != 0
}

// setRawMode pone stdin en modo raw (sin eco ni canonical) y devuelve la
// función que restaura el estado anterior. Falla si `stty` no está
// disponible o stdin no es una terminal.
func setRawMode() (func(), error) {
	get := exec.Command("stty", "-g")
	get.Stdin = os.Stdin
	save, err := get.Output()
	if err != nil {
		return nil, err
	}
	raw := exec.Command("stty", "raw", "-echo")
	raw.Stdin = os.Stdin
	if err := raw.Run(); err != nil {
		return nil, err
	}
	return func() {
		restore := exec.Command("stty", string(bytes.TrimSpace(save)))
		restore.Stdin = os.Stdin
		_ = restore.Run()
	}, nil
}

// readSelKey lee una tecla (o secuencia de escape ANSI) del reader
// compartido de stdin. En modo raw Ctrl+C llega como byte 0x03.
func readSelKey() selKey {
	b, err := stdin.ReadByte()
	if err != nil {
		return selOther
	}
	if b != 0x1b {
		return classifyKey([]byte{b})
	}
	seq := []byte{b}
	for len(seq) < 3 {
		nb, err := stdin.ReadByte()
		if err != nil {
			break
		}
		seq = append(seq, nb)
	}
	return classifyKey(seq)
}

// SelectOption muestra un selector navegable con ↑/↓, Enter para confirmar
// y q/Ctrl+C para cancelar. Requiere TTY en stdin.
func SelectOption(label string, options []string) (int, error) {
	if len(options) == 0 {
		return 0, fmt.Errorf("sin opciones para elegir")
	}
	restore, err := setRawMode()
	if err != nil {
		return 0, err
	}
	defer restore()

	fmt.Printf("◇ %s (↑/↓ + Enter, q para salir):\r\n", label)
	fmt.Print("\x1b[?25l")
	defer fmt.Print("\x1b[?25h")

	idx := 0
	renderOptions(options, idx)
	for {
		k := readSelKey()
		switch k {
		case selEnter:
			fmt.Print("\r\n")
			return idx, nil
		case selAbort:
			fmt.Print("\r\n")
			return 0, errSelectionAborted
		case selUp, selDown:
			// Se sube el cursor y se redibuja la lista in situ.
			fmt.Printf("\x1b[%dA", len(options))
			idx = moveIndex(idx, len(options), k)
			renderOptions(options, idx)
		}
	}
}

func renderOptions(options []string, idx int) {
	for i, opt := range options {
		if i == idx {
			fmt.Printf("\r\x1b[K  %s❯ %s%s\r\n", Cyan, opt, Reset)
		} else {
			fmt.Printf("\r\x1b[K    %s\r\n", opt)
		}
	}
}
