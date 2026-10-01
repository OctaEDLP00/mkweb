package ui

import "testing"

func TestClassifyKey(t *testing.T) {
	tests := []struct {
		name string
		seq  []byte
		want selKey
	}{
		{"enter CR", []byte{'\r'}, selEnter},
		{"enter LF", []byte{'\n'}, selEnter},
		{"abort q", []byte{'q'}, selAbort},
		{"abort Q", []byte{'Q'}, selAbort},
		{"abort Ctrl+C", []byte{0x03}, selAbort},
		{"arriba", []byte{0x1b, '[', 'A'}, selUp},
		{"abajo", []byte{0x1b, '[', 'B'}, selDown},
		{"otra flecha", []byte{0x1b, '[', 'C'}, selOther},
		{"letra", []byte{'x'}, selOther},
		{"vacío", nil, selOther},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := classifyKey(tt.seq); got != tt.want {
				t.Errorf("classifyKey(%q) = %v, se esperaba %v", tt.seq, got, tt.want)
			}
		})
	}
}

func TestMoveIndex(t *testing.T) {
	const n = 8
	tests := []struct {
		name string
		idx  int
		key  selKey
		want int
	}{
		{"baja", 0, selDown, 1},
		{"sube", 2, selUp, 1},
		{"wrap arriba", 0, selUp, n - 1},
		{"wrap abajo", n - 1, selDown, 0},
		{"otra tecla no mueve", 3, selOther, 3},
		{"enter no mueve", 3, selEnter, 3},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := moveIndex(tt.idx, n, tt.key); got != tt.want {
				t.Errorf("moveIndex(%d, %d, %v) = %d, se esperaba %d", tt.idx, n, tt.key, got, tt.want)
			}
		})
	}
}
