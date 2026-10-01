package templates

import (
	"fmt"
	"sort"
)

var registry = map[string]Template{}

// Register da de alta una plantilla en el catálogo.
func Register(t Template) {
	registry[t.Name] = t
}

// Get resuelve la plantilla solicitada o devuelve un error si no existe.
func Get(name string) (Template, error) {
	t, ok := registry[name]
	if !ok {
		return Template{}, fmt.Errorf("unknown template: %s", name)
	}
	return t, nil
}

// List devuelve todas las plantillas ordenadas por nombre.
func List() []Template {
	out := make([]Template, 0, len(registry))
	for _, t := range registry {
		out = append(out, t)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })
	return out
}

// IsValid indica si el nombre corresponde a una plantilla registrada.
func IsValid(name string) bool {
	_, ok := registry[name]
	return ok
}
