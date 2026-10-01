# AGENTS.md — mkweb-go-cli

CLI en Go (Cobra) que genera proyectos web. Spec de arquitectura en `INFO.md`;
comportamiento de referencia en `~/Escritorio/Dev/mkweb.sh` (fuera del repo).

## Verificar

```sh
go build ./...   # el binario también: go build -o /tmp/mkweb .
go vet ./...
gofmt -l .       # debe salir vacío
go test ./...    # hoy no hay tests; hay skills go en skills-lock.json si agregás
```

`README.md` documenta uso y plantillas; `Makefile` aporta `build install run test vet fmt clean` (`make help` los lista). CI en `.github/workflows/` (`ci.yml`: build+vet+test+gofmt+`bash -n`; `release.yml`: tags `v*` → binarios multi-OS en Releases, versión inyectada por ldflags en `config.Version`).

## Arquitectura

`main.go` → `cmd/` (Cobra: `create`, `list`, `version`; `help`/`completion` las da Cobra)
→ `internal/templates` (registry) → `internal/generator` (escribe archivos)
→ `internal/ui` (mensajes/estilos/prompts), `internal/config` (versión, defaults),
`internal/pm` (gestores: validar, versión instalada, `install`).

## Plantillas (zona de mayor riesgo)

- Archivos reales en disco: `internal/templates/variants/common/` (base: `.editorconfig`,
  `.gitignore`, `README.md`, `public/favicon.svg`) y `variants/<tech>/<lang>/`
  (`vanilla`/`phaser` × `js`/`ts`). Se emben con `go:embed` y se renderizan.
- **Todo archivo de plantilla se parsea como `text/template`.** Variables:
  `{{.ProjectName}}`, `{{.Template}}` y `{{.PackageManager}}` (spec `"<pm>@<semver>"`
  o `""`; el campo `packageManager` usa `{{if .PackageManager}}` para omitirse).
  Un `{{`/`}}` accidental rompe el arranque (`MustParse` hace `panic` en
  `internal/templates/variants/loader.go`). Los literales JS `${...}` son seguros.
- **Dotfiles: hay que listarlos explícitos en el `//go:embed` de `loader.go`.**
  `embed` los excluye al expandir directorios; si agregás un dotfile a `common/`,
  agregá su patrón o no se incluye en el binario (falla en silencio).
- **Los directorios vacíos no se pueden embeber.** Las carpetas del proyecto
  generado se declaran en el campo `Folders` del registrador (`vanilla.go`/`phaser.go`);
  los `.gitkeep` los crea `MarkEmptyDirsWithGitkeep` en tiempo de ejecución.
- Nueva variante = nuevo dir `variants/<tech>/{js,ts}/` + registrador `init()` con
  `templates.Register` (ver los existentes) + **import blank (`_`) en
  `internal/generator/generator.go`**, si no la plantilla nunca se registra.
- `src/types/index.ts` va dentro de cada árbol `ts/` (no en `common/`).

## Convenciones y trampas

- Nombres de archivo con typo que se conservan a propósito:
  `internal/ui/pompt.go`. No lo renombres.
- `internal/ui/pompt.go` usa un único `bufio.Reader` compartido sobre stdin.
  No crees un reader por prompt: el primero buferiza input del segundo y el modo
  interactivo pierde respuestas. El selector (`selector.go`) lee de ese mismo reader.
- `internal/ui/selector.go` implementa el selector ↑/↓ con `stty raw` (stdlib, sin
  deps): solo corre con TTY en stdin, si no cae a texto. Enter confirma, q/Ctrl+C
  cancela (propaga el error, no hace fallback). `setRawMode` restaura con `defer`.
- Comentarios del código en español; mantener el idioma.
