#!/usr/bin/env bash

display_help() {
  local txt="$(
    cat << 'EOF'
Usage: addpath [OPTIONS] DIRECTORY

Add a directory to the PATH environment variable.

OPTIONS:
    -r, --resolve-symlinks  Resolve symlinks before adding to PATH
    -s, --suppress-warnings Suppress warnings messages
    -m, --move-existing     If directory already exists in PATH, enable moving to front or back of PATH

POSITIONAL ARGUMENTS:
    -p, --prepend           Prepend directory to PATH.
    -a, --append            Append directory to PATH.

GENERAL OPTIONS:
    -h, --help              Show this help message and exit
    -q, --quiet             Suppress warnings
    -d, --dry-run           Print the new PATH without modifying the environment

EXAMPLES:
    addpath /path/to/directory
    addpath -r /path/to/directory

EOF
  )"
  if command -v bat &> /dev/null; then
    echo "$txt" | bat -l help -P --plain -f
  else
    echo "$txt"
  fi

}

addpath() {

  # OPTIONS
  local -i RESOLVE_SYMLINKS=0
  local -i QUIET=0
  local -i DRY_RUN=0
  local -i SUPPRESS_WARNINGS=0
  local -i ALLOW_MOVE_EXISTING=0

  local METHOD=prepend # [*prepend|append]

  # ARGUMENTS
  local DIR                     # directory argument to add to PATH
  local -r _PATH_BACKUP="$PATH" # backup of $PATH
  local NPATH="$PATH"           # modified PATH.

  _echo() {
    [[ $QUIET -eq 0 && $SUPPRESS_WARNINGS -eq 0 ]] && echo "$@"
  }

  # if no arguments, show help
  if [ $# -eq 0 ]; then
    display_help
    return 1
  fi

  for arg in "$@"; do
    case "$arg" in
      -h | --help)
        display_help
        return 0
        ;;
      -r | --resolve-symlinks)
        RESOLVE_SYMLINKS=1
        ;;
      -m | --move-existing)
        ALLOW_MOVE_EXISTING=1
        ;;
      -p | --prepend)
        METHOD=prepend
        ;;
      -a | --append)
        METHOD=append
        ;;
      -q | --quiet)
        QUIET=1
        ;;
      -s | --suppress-warnings)
        SUPPRESS_WARNINGS=1
        ;;
      -d | --dry-run)
        DRY_RUN=1
        ;;
      *)
        DIR="$arg"
        ;;
    esac
  done

  [[ $DRY_RUN -eq 1 ]] && QUIET=0

  #
  # Validate directory exists
  #

  if [ ! -d "$DIR" ]; then
    _echo "Directory does not exist: $DIR"
    return 1
  fi

  #
  # Resolve symlinks if enabled
  #
  if [ $RESOLVE_SYMLINKS -eq 1 ]; then
    DIR=$(realpath "$DIR")
  else
    DIR=$(realpath -L "$DIR")
  fi

  #
  # Check if directory is already in PATH
  #
  if [[ ":$NPATH:" == *":$DIR:"* ]]; then

    #
    # Remove from PATH if moving is enabled
    #
    if [ $ALLOW_MOVE_EXISTING -eq 1 ]; then

      NPATH="$(echo "$NPATH" | tr ':' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//' | grep -v "^${DIR}$" | tr '\n' ':' | sed 's/^:*//;s/:*$//')"
    else
      _echo "Directory is already in the PATH: $DIR"
      return 1
    fi
  fi

  #
  # Add directory to PATH
  #
  case $METHOD in
    prepend)
      NPATH="$DIR:$NPATH"
      ;;
    append)
      NPATH="$NPATH:$DIR"
      ;;
  esac

  #
  # If dry-run, print the new PATH and return without modifying the environment
  #
  if [ $DRY_RUN -eq 1 ]; then
    echo "$NPATH"
    return 0
  fi

  #
  # Update changes to PATH
  #
  export PATH="$NPATH"

  [[ $QUIET -eq 0 ]] && echo "$PATH"
  return 0

}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  addpath "$@"

fi
