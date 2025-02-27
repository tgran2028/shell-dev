#!/usr/bin/env bash

set -euo pipefail

OPT_DEBUG=${DEBUG_FIX_PATH:-0}

# Color definitions.
GRAY='\033[0;37m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

log() {
  local COLOR
  local -l level

  level="$1"
  shift

  if [[ $level == "info" ]]; then
    COLOR="$WHITE"
  elif [[ $level == "warn" ]]; then
    COLOR="$YELLOW"
  elif [[ $level == "error" ]]; then
    COLOR="$RED"
  elif [[ $level == "debug" ]]; then
    COLOR="$GRAY"
  else
    COLOR="$WHITE"
  fi

  echo -e "${COLOR}${BOLD}${level^^}:${NC} $*" >&2

}

log::debug() {
  if [[ $OPT_DEBUG -eq 1 ]]; then
    log debug "$*"
  fi
}

log::info() {
  log info "$*"
}

log::warn() {
  log warn "$*"
}

log::error() {
  log error "$*"
}

# Ensure jq is installed.
if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

# Global arrays
declare -a DEFAULT_PATHS=($(jq -rM '.paths|.[]' /etc/path.default.json 2> /dev/null | xargs -n1))
declare -a HOME_PATHS=("$HOME/.local/bin" "$HOME/bin")
declare -a OPT_PATHS=()
declare -a OTHER_PATHS=()

declare -a EXCLUDE_TERMS
declare -l USE_SHELL

if [[ $# -eq 1 ]]; then
  USE_SHELL="$1"
else
  USE_SHELL=$(ps -p $$ -o comm=)
fi

if [[ "$USE_SHELL" == "zsh" ]]; then
  log::debug "Running in zsh"
  EXCLUDE_TERMS=(fish bash_completion)
elif [[ "$USE_SHELL" == "bash" ]]; then
  log::debug "Running in bash"
  EXCLUDE_TERMS=(fish zsh antigen antidote zprofile)
else
  log::debug "Running in unknown shell"
  EXCLUDE_TERMS=()
fi

log::debug "Shell: $(ps -p $$ -o comm=)"
log::debug "Exclude terms: ${EXCLUDE_TERMS[*]}"

# Helper function to check whether an element exists in an array.
array_contains() {
  local needle="$1"
  shift
  for element in "$@"; do
    [[ $element == "$needle" ]] && return 0
  done
  return 1
}

# Helper function to print category summaries.
print_summary() {
  local title="$1"
  local arr=("${!2}")
  local count="${#arr[@]}"
  echo -e "\n${title} (${count}):"
  printf '%s\n' "${arr[@]}"
}

# Split PATH into an array using ':' as separator.
IFS=':' read -ra PATH_DIRS <<< "$PATH"

for dir in "${PATH_DIRS[@]}"; do
  # Skip if directory doesn't exist.
  if [[ ! -d $dir ]]; then
    continue
  fi

  # Canonicalize the directory.
  dir="$(realpath -L "$dir")"

  # Skip if the directory contains any exclude term.
  for term in "${EXCLUDE_TERMS[@]}"; do
    if [[ $dir == *"$term"* ]]; then
      continue 2
    fi
  done

  # If directory is a default path, output it and skip further processing.
  if array_contains "$dir" "${DEFAULT_PATHS[@]}"; then
    log::debug "default: $dir"
    continue
  fi

  # Categorize the directory.
  if [[ $dir == /home/* ]]; then
    if ! array_contains "$dir" "${HOME_PATHS[@]}"; then
      HOME_PATHS+=("$dir")
      log::debug "home: $dir"
    fi
  elif [[ $dir == /opt/* ]]; then
    if ! array_contains "$dir" "${OPT_PATHS[@]}"; then
      OPT_PATHS+=("$dir")
      log::debug "opt: $dir"
    fi
  else
    if ! array_contains "$dir" "${OTHER_PATHS[@]}"; then
      OTHER_PATHS+=("$dir")
      log::debug "other: $dir"
    fi
  fi
done

# reverse order of HOME_PATHS
mapfile -t HOME_PATHS < <(printf "%s\n" "${HOME_PATHS[@]}" | tac)

# combine all paths
ALL_PATHS=("${HOME_PATHS[@]}" "${OPT_PATHS[@]}" "${OTHER_PATHS[@]}" "${DEFAULT_PATHS[@]}")

# Display summary of categorized directories.
out="$(
  cat << EOF

${GREEN}${BOLD}-----------------------------------
HOME (${#HOME_PATHS[@]})
-----------------------------------${NC}
${GREEN}$(printf "%s\n" "${HOME_PATHS[@]}")${NC}

${CYAN}${BOLD}-----------------------------------
OPT (${#OPT_PATHS[@]})
-----------------------------------${NC}
${CYAN}$(printf "%s\n" "${OPT_PATHS[@]}")${NC}

${YELLOW}${BOLD}-----------------------------------
OTHER (${#OTHER_PATHS[@]})
-----------------------------------${NC}
${YELLOW}$(printf "%s\n" "${OTHER_PATHS[@]}")${NC}

${MAGENTA}${BOLD}-----------------------------------
DEFAULT (${#DEFAULT_PATHS[@]})
-----------------------------------${NC}
${MAGENTA}$(printf "%s\n" "${DEFAULT_PATHS[@]}")${NC}

${WHITE}${BOLD}-----------------------------------
ALL (${#ALL_PATHS[@]})
-----------------------------------${NC}
${WHITE}$(printf "%s\n" "${ALL_PATHS[@]}")${NC}

EOF
)"

log::debug "$out"

# COMBINE ON ":"
declare -xg __PATH_OLD="$PATH"
declare -xg __PATH_NEW="$(
  IFS=:
  echo "${ALL_PATHS[*]}"
)"

echo "$__PATH_NEW"
