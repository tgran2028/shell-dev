#!/usr/bin/env bash

set -e

remove_from_path() {

  # params
  local p new_path
  local original_path="$PATH"

  # options
  local EXPORT=false
  local QUIET=false
  local VERBOSE=false
  local EXTENDED_REGEX=false
  local REGEX_EXPR=false

  __show_help() {
    cat << 'EOF'
Remove directory from $PATH variable.

Usage: remove_from_path [OPTIONS] <INPUT>

Pattern Types:

- Literal: If neither -r or -e are passed, the function will interpret the input as a literal path.
- Regex pattern: if -r is passed, the function will interpret input as regex pattern (equivalent to grep)
- Extended Regex pattern: if -e is passed, uses grep extended regex expression. (passing -r and -E is redundant)

OPTIONS:

-e, --export              export revised path to global $PATH variable.

-E, --extended-regexp     PATTERNS are extended regular expressions; (enables -r, --regex)
-r, --regex               PATTERNS are used

-q, --quiet               suppress revised path output

-v, --verbose             enable verbose output
-h, --help                show help

EOF
  }

  if [[ ! -p /dev/stdin && $# -eq 0 ]]; then
    __show_help
    return 1
  fi

  # parse options
  while [ $# -gt 0 ]; do
    case "$1" in
      -h | --help)
        __show_help
        return 0
        ;;
      -r | --regex)
        REGEX_EXPR=true
        shift
        ;;
      -E | --extended-regexp)
        REGEX_EXPR=true
        EXTENDED_REGEX=true
        shift
        ;;
      -e | --export)
        EXPORT=true
        shift
        ;;
      -v | --verbose)
        VERBOSE=true
        shift
        ;;
      -q | --quiet)
        QUIET=true
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  # set path to stdin if provided, else combine remaining args
  if [[ -p /dev/stdin ]]; then
    [[ $# -gt 0 ]] && echo "To many args provided with stdin." && exit 1
    p=$(cat -)
  else
    p=$*
  fi
  # clean path
  p="$(echo "$p" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  # raise error if $p empty
  if [[ -z $p ]]; then
    echo "No input path provided"
    return 1
  fi

  # ~~~ remove input from path ~~~

  # remove literal path
  if [[ "$REGEX_EXPR" == 'false' ]]; then
    new_path="$(echo "$PATH" | tr ':' '\n' | grep -v "^${p}$" | tr '\n' ':' | sed -e 's/^://' -e 's/:$//' -e 's/::/:/g')"
  # remove regex expr matches
  elif [[ "$REGEX_EXPR" == 'true' && "$EXTENDED_REGEX" == 'false' ]]; then
    new_path="$(echo "$PATH" | tr ':' '\n' | grep -v "${p}" | tr '\n' ':' | sed -e 's/^://' -e 's/:$//' -e 's/::/:/g')"
  # remove extended regex expr matches
  else
    new_path="$(echo "$PATH" | tr ':' '\n' | grep -vE "${p}" | tr '\n' ':' | sed -e 's/^://' -e 's/:$//' -e 's/::/:/g')"
  fi

  # export revised path to global PATH variable
  if [[ "$EXPORT" == "true" ]]; then
    [[ "$VERBOSE" == "true" ]] && echo "exporting PATH. Previous PATH saved to '__PATH_backup'"
    declare -gx __PATH_backup="$PATH"
    declare -gx PATH="$new_path"
  fi

  if [[ "$VERBOSE" == "true" ]]; then
    local path_changed
    [[ "$original_path" == "$new_path" ]] && path_changed=false || path_changed=true
    cat << EOF
--- 
parameters:
    - directory to remove from path: '${p}'
options:
    - export: ${EXPORT}
    - verbose: ${VERBOSE}
    - quiet: ${QUIET}
---
Original PATH: '${original_path}'
---
Revised Path: '${new_path}'
---
Path modifed: ${path_changed}
EOF
  fi

  if [[ "$QUIET" == 'false' && "$VERBOSE" == 'false' ]]; then
    echo "$new_path"
  fi
}

# ensure file not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ $# -eq 0 ]]; then
    remove_from_path --help | bat -l help -P --plain -f
  else
    remove_from_path "$@"
  fi
fi
