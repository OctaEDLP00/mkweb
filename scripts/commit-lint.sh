#!/bin/bash
# commit-lint.sh — Valida mensajes de commit (Conventional Commits).
#
# Uso:
#   ./scripts/commit-lint.sh "feat: agrega selector"
#   ./scripts/commit-lint.sh .git/COMMIT_EDITMSG   # como hook commit-msg
#   ./scripts/commit-lint.sh --install             # instala como hook commit-msg
#
# Formato: <tipo>[scope][!]: <asunto>
# Tipos: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert
# Ejemplos: "feat: agrega selector", "fix(ui)!: cambia API", "chore: deps"

set -uo pipefail

TYPES="feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert"
HEADER_RE="^(${TYPES})(\([^)]+\))?(!)?: .+"

red='\e[0;91m'; green='\e[0;92m'; yellow='\e[0;93m'; reset='\e[0m'

fail() { echo -e "${red}[x]${reset} $1" >&2; exit 1; }

install_hook() {
  local top; top=$(git rev-parse --show-toplevel 2>/dev/null) \
    || fail "no estás dentro de un repo git"
  local src; src=$(realpath "${BASH_SOURCE[0]}")
  ln -sf "$src" "$top/.git/hooks/commit-msg"
  echo -e "${green}[✓]${reset} hook commit-msg instalado"
}

[[ "${1:-}" == "--install" ]] && { install_hook; exit 0; }
[[ $# -eq 0 ]] && fail "uso: $0 \"<tipo>: <asunto>\" | <archivo-msg> | --install"

# Si es un archivo (hook commit-msg), toma la primera línea útil
# ignorando comentarios y líneas vacías.
if [[ -f "${1:-}" ]]; then
  msg=$(grep -v -e '^#' -e '^[[:space:]]*$' "$1" | head -n 1)
else
  msg=$1
fi

# Los merges generados por git siempre pasan.
[[ "$msg" =~ ^Merge\  ]] && exit 0

[[ "$msg" =~ $HEADER_RE ]] \
  || fail "mensaje inválido: \"$msg\"\nformato: <tipo>[scope][!]: <asunto>\ntipos: ${TYPES//|/, }"

subject=${msg#*: }
((${#subject} > 72)) \
  && echo -e "${yellow}[!]${reset} el asunto supera 72 caracteres (${#subject})" >&2

echo -e "${green}[✓]${reset} commit válido"
