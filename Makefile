BINARY := mkweb
BINDIR := bin
PKG := .

.PHONY: help build install run test vet fmt clean

help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'

build: ## Compila el binario en ./bin
	go build -o $(BINDIR)/$(BINARY) $(PKG)

install: ## Instala el binario en $GOPATH/bin
	go install $(PKG)

run: ## Ejecuta el CLI sin compilar (ARGS="create ...")
	go run $(PKG) $(ARGS)

test: ## Corre los tests
	go test ./...

vet: ## Análisis estático
	go vet ./...

fmt: ## Verifica formato (debe salir vacío)
	gofmt -l .

clean: ## Borra el binario compilado
	rm -rf $(BINDIR)
