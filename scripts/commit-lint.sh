#!/bin/bash

# commit-lint.sh — Validates commit messages against the Conventional Commits specification.
#
# Usage:
#   ./scripts/commit-lint.sh "feat: add selector"
#   ./scripts/commit-lint.sh .git/COMMIT_EDITMSG       # Used as a commit-msg hook
#   ./scripts/commit-lint.sh --install                # Install the Git hook
#   ./scripts/commit-lint.sh --uninstall              # Uninstall the Git hook
#   ./scripts/commit-lint.sh --help                   # Display help
#
# Features:
#   - Validates commit headers, including type, scope, and breaking change indicators
#   - Checks subject and body line lengths
#   - Validates breaking change declarations and issue references
#   - Supports direct message input and Git commit message files
#   - Can be installed as a Git commit-msg hook

# Formatters
reset='\e[0m'
bold='\e[1m'
dim='\e[2m'
italic='\e[3m'
underline='\e[4m'
blink='\e[5m'
reverse='\e[7m'
hidden='\e[8m'
strikethrough='\e[9m'

# Foreground Colors (Bright)
black='\e[0;90m'
red='\e[0;91m'
green='\e[0;92m'
yellow='\e[0;93m'
blue='\e[0;94m'
purple='\e[0;95m'
cyan='\e[0;96m'
white='\e[0;97m'

# Background (Bright)
BgBlack='\e[100m'
BgRed='\e[101m'
BgGreen='\e[102m'
BgYellow='\e[103m'
BgBlue='\e[104m'
BgPurple='\e[105m'
BgCyan='\e[106m'
BGWhite='\e[107m'

muted='\e[0;2m'

export DEBIAN_FRONTEND=noninteractive

set -uo pipefail

trap ctrl_c INT

enter() { echo ""; }
write() { echo -e "$1"; }
error() { echo -e "${red}[x]${reset} $1"; }
success() { echo -e "${green}[✓]${reset} $1"; }
fail() { echo -e "${red}[x]${reset} $1" >&2; exit 1; }
warning() { echo -e "${yellow}[!]${reset} $1"; }
info() { echo -e "${cyan}[i]${reset} $1"; }
debug() { echo -e "${cyan}[🛠️]${reset} $1"; }

ctrl_c() {
  info "\n${yellow}[*]${reset}${white} Exit...${reset}"
  tput cnorm 2>/dev/null || true
  exit 0
}

declare TYPES="feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert"
declare HEADER_RE="^(${TYPES})(\\([^)]+\\))?(!)?: (.+)$"

declare MAX_SUBJECT_LENGTH=72
declare MAX_BODY_LINE_LENGTH=72

declare COMMIT_HEADER=''
declare COMMIT_BODY=''

banner() {
  write "  ${muted}  ____           _   _     _       _   ${reset}"
  write "  ${muted} / ___|_ __ ___ | |_| |   (_)_ __ | |_ ${reset}"
  write "  ${muted}| |   | '_ \` _ \| __| |   | | '_ \| __|${reset}"
  write "  ${muted}| |___| | | | | | |_| |___| | | | | |  ${reset}"
  write "  ${muted} \____|_| |_| |_|\__|_____|_|_| |_|\__|${reset}"
  enter
  write "${muted}  Shell script to validate commit messages${reset}"
  write "${muted}  against predefined conventions before${reset}"
  write "${muted}  committing.${reset}"
  enter
}

show_help() {
  info "${white}Usage: ./commit-lint.sh ${muted}[options]${reset}"
  enter

  write "${white}Options:${reset}"
  write "  ${purple}-i, --install${reset}    ${muted}# install as hook${reset}"
  write "  ${purple}-u, --uninstall${reset}  ${muted}# uninstall hook${reset}"
  write "  ${purple}-h, --help${reset}       ${muted}# Show this help panel${reset}"
  enter

  write "${white}Examples:${reset}"
  write "  ${cyan}./commit-lint.sh \"commit messge\"${reset}"
  write "  ${cyan}./commit-lint.sh -i ${muted}# Install this script as a hook${reset}"
  write "  ${cyan}./commit-lint.sh -u ${muted}# Uninstall this script as a hook${reset}"
  enter
}

install_hook() {
  local hook
  local src

  hook=$(git rev-parse --git-path hooks/commit-msg 2>/dev/null) \
    || fail 'You are not inside a git repo'

  src=$(realpath "${BASH_SOURCE[0]}") \
    || fail 'Could not resolve script path'

  mkdir -p "$(dirname "$hook")" \
    || fail 'Could not create hooks directory'

  ln -sf "$src" "$hook" \
    || fail 'Could not install hook'

  success 'Installed hook commit-msg'
}

uninstall_hook() {
  local hook
  local src

  hook=$(git rev-parse --git-path hooks/commit-msg 2>/dev/null) \
    || fail 'You are not inside a git repo'

  src=$(realpath "${BASH_SOURCE[0]}") \
    || fail 'Could not resolve script path'

  if [[ ! -L "$hook" ]]; then
    warning 'No symbolic commit-msg hook found'
    return 0
  fi

  [[ "$(readlink -f "$hook")" == "$src" ]] \
    || fail 'The existing hook does not belong to this script'

  rm -f "$hook" || fail 'Could not uninstall hook'

  success 'Uninstalled hook commit-msg'
}

read_commit_msg() {
  local input="${1:-}"
  local content=''
  local line
  local header_found=false

  [[ -n "$input" ]] || fail 'No commit message was provided'

  if [[ -f "$input" ]]; then
    [[ -r "$input" ]] || fail "The file '$input' cannot be read"

    content=$(sed '/^[[:space:]]*#/d' "$input") \
      || fail "The file '$input' could not be read"
  else
    content="$input"
  fi

  COMMIT_HEADER=''
  COMMIT_BODY=''

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$header_found" == false ]]; then
      [[ "$line" =~ ^[[:space:]]*$ ]] && continue

      COMMIT_HEADER="$line"
      header_found=true
      continue
    fi

    COMMIT_BODY+="${COMMIT_BODY:+$'\n'}$line"
  done <<< "$content"

  [[ "$header_found" == true ]] \
    || fail 'The commit message is empty'
}

validate_commit_header() {
  local subject

  [[ "$COMMIT_HEADER" =~ $HEADER_RE ]] || fail \
    "Invalid message: \"$COMMIT_HEADER\"\nformat: <type>[scope][!]: <subject>\ntypes: ${TYPES//|/, }"

  subject="${BASH_REMATCH[4]}"

  ((${#subject} <= MAX_SUBJECT_LENGTH)) || warning \
    "subject exceeds ${MAX_SUBJECT_LENGTH} characters (${#subject})"

  [[ "$subject" =~ ^[[:space:]] ]] && fail \
    "The matter cannot begin with spaces"

  [[ "$subject" =~ [[:space:]]$ ]] && fail \
    "the matter cannot end with spaces"
}

validate_commit_body() {
  local line
  local line_number=0

  [[ -n "$COMMIT_BODY" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    ((line_number += 1))

    ((${#line} <= MAX_BODY_LINE_LENGTH)) || warning \
      "line ${line_number} of body exceeds ${MAX_BODY_LINE_LENGTH} characters (${#line})"
  done <<< "$COMMIT_BODY"
}

validate_breaking_change() {
  local line
  local description
  local found=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      'BREAKING CHANGE:'*)
        description="${line#BREAKING CHANGE:}"
        [[ "$description" =~ [^[:space:]] ]] || fail \
          'BREAKING CHANGE must include a description'
        found=true
        ;;

      'BREAKING-CHANGE:'*)
        description="${line#BREAKING-CHANGE:}"
        [[ "$description" =~ [^[:space:]] ]] || fail \
          'BREAKING-CHANGE must include a description'
        found=true
        ;;
    esac
  done <<< "$COMMIT_BODY"

  if [[ "$COMMIT_HEADER" =~ !: ]]; then
    info 'breaking change detected by the header'
  elif [[ "$found" == true ]]; then
    info 'breaking change declared via footer'
  fi
}

validate_commit_footer() {
  local -a lines=()
  local line
  local normalized
  local start
  local end
  local i
  local footer_found=false

  mapfile -t lines <<< "$COMMIT_BODY"

  end=$((${#lines[@]} - 1))

  # Ignore trailing empty lines.
  while ((end >= 0)) && [[ "${lines[end]}" =~ ^[[:space:]]*$ ]]; do
    ((end -= 1))
  done

  ((end >= 0)) || return 0

  start="$end"

  # Find the beginning of the last paragraph.
  while ((start > 0)); do
    [[ "${lines[start - 1]}" =~ ^[[:space:]]*$ ]] && break
    ((start -= 1))
  done

  # Footers must be separated from the body.
  ((start > 0)) || return 0

  for ((i = start; i <= end; i++)); do
    line="${lines[i]}"
    normalized="${line,,}"

    case "$normalized" in
      closes\ * | closes:\ * | fixes\ * | fixes:\ * | resolves\ * | resolves:\ * | refs\ * | refs:\ * | related\ * | related:\ * | see\ also\ * | see\ also:\ *)
        [[ "$line" =~ \#[0-9]+ ]] || fail \
          "Invalid issue reference: \"$line\""

        footer_found=true
        ;;

      'breaking change:'* | 'breaking-change:'*)
        footer_found=true
        ;;
    esac
  done

  [[ "$footer_found" == true ]] && info 'Footer detected'
}

commit_msg() {
  local input="${1:-}"

  # Read commit message from argument or file.
  read_commit_msg "$input"

  # Allow Git-generated merge commits.
  [[ "$COMMIT_HEADER" =~ ^Merge[[:space:]] ]] && return 0

  # Validate commit header.
  validate_commit_header

  # Validate commit body.
  validate_commit_body

  # Validate breaking changes.
  validate_breaking_change

  # Validate commit footers.
  validate_commit_footer

  success 'valid commit'
}

init() {
  trap 'tput cnorm 2>/dev/null || true' EXIT

  local input=''

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i | --install)
        install_hook
        exit 0
        ;;

      -u | --uninstall)
        uninstall_hook
        exit 0
        ;;

      -h | --help)
        banner
        show_help
        exit 0
        ;;

      --)
        shift
        input="$*"
        break
        ;;

      -*)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;

      *)
        input="$1"
        shift

        [[ $# -eq 0 ]] || fail 'Only one argument is allowed'
        break
        ;;
    esac
  done

  if [[ -n "$input" ]]; then
    commit_msg "$input"
  else
    banner
    show_help
  fi
}

init "$@"

