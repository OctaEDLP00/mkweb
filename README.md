# mkweb

`mkweb` es un creador de proyectos para web (vanilla y Phaser, en JavaScript o
TypeScript). Genera la estructura de carpetas y archivos lista para instalar
dependencias y arrancar el dev server.

Requiere Go (ver versión en `go.mod`).

## Instalación

```sh
go install github.com/OctaEDLP00/mkweb@v0.1.1   # última release 
# o compilar local:
go build -o mkweb .
make build
make install   # go install . → $GOPATH/bin
```

También hay binarios precompilados en la pestaña Releases del repo
(linux/darwin/windows, amd64/arm64): cada tag `v*` publica `mkweb` + checksums.

## Alternativa shell

`mkweb.sh` es la versión original en Bash, con las mismas 4 plantillas.
Sirve si no querés compilar Go:

```sh
./mkweb.sh -t vanilla-ts -n mi-app
./mkweb.sh -t phaser --name my-game
./mkweb.sh                        # interactivo (pregunta plantilla y nombre)
```

## Uso

```sh
mkweb create my-game --template phaser-ts --pm pnpm
mkweb create my-game --template phaser    # Phaser JavaScript
mkweb create mi-app --template vanilla-ts --pm bun --install
mkweb create mi-app --template vanilla    # Vanilla JavaScript

mkweb create -t vanilla-ts -n mi-app -p npm   # flags cortos
mkweb create                              # modo interactivo (selectores de plantilla
                                          # y gestor con ↑/↓ + Enter, nombre e instalación)

mkweb list                                # plantillas disponibles
mkweb version                             # versión del CLI
mkweb completion bash                     # autocompletado (bash|zsh|fish|powershell)
```

## Gestores (`--pm`/`-p`)

| Gestores    |       |
|--------------|------|
| `pnpm`    | ✅ |
| `npm` | ✅ |
| `yarn`     | ✅ |
| `bun`  | ✅ |
| `nube`  | ✅ |
| `nub`  | ✅ |
| `utoo`  | ✅ |
| `upm`  | ✅ |

El `package.json` generado incluye `"packageManager": "<pm>@<semver>"` con la
versión **instalada** (`<pm> --version`; para `npm` refleja el npm del Node
activo). Si el gestor no está instalado, se genera sin ese campo y se avisa.

Tras generar, se pregunta si instalar dependencias (`--install` lo hace sin
preguntar; sin flags no se instala nada):

Tras generar el proyecto (o si elegiste instalar, solo arrancar):

```sh
cd mi-app \
npm install \
npm run dev   # con el gestor que elegiste
```

## Plantillas

| Plantilla    | Descripción      |
|--------------|------------------|
| `vanilla`    | Vanilla JavaScript |
| `vanilla-ts` | Vanilla TypeScript |
| `phaser`     | Phaser JavaScript  |
| `phaser-ts`  | Phaser TypeScript  |

## Estructura del repo

- `cmd/` — comandos Cobra (`create`, `list`, `version`).
- `internal/templates/` — registry + catálogo (`variants/common/` para archivos base
  y `variants/<tech>/<lang>/` para cada plantilla, renderizadas como `text/template`
  con `{{.ProjectName}}` y `{{.Template}}`).
- `internal/generator/` — motor que crea carpetas y escribe los archivos.
- `internal/config/` — versión y defaults. `internal/ui/` — mensajes y prompts.

Para agregar una tecnología nueva, ver `AGENTS.md` (sección Plantillas).

## Commits

Los mensajes siguen Conventional Commits (`<tipo>[scope][!]: <asunto>` con
`feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`).
`scripts/commit-lint.sh` los valida; instalalo como hook:

```sh
./scripts/commit-lint.sh --install
```

## Desarrollo

```sh
make build   # compila ./bin/mkweb
make test    # go test ./...
make vet     # go vet ./...
make fmt     # gofmt -l . (debe salir vacío)
```
