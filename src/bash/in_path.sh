#!/bin/bash
#
# Script to determine if provided path is in $PATH

# COLORS
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

### OPTIONS
QUIET=false    # -q; --quiet       Do not output any message
RESOLOVE=false # -r; --resolve   Resolve symbolic links

display_help() {
    echo "Usage: $0 [options] <path>"
    echo "Check if provided path is in \$PATH"
    echo
    echo "Options:"
    echo "  -q, --quiet  Do not output any message"
    echo "  -r, --resolve  Resolve symbolic links"
}

# Check if no argument is provided
if [ $# -eq 0 ]; then
    display_help
    exit 1
fi

# parse options
while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
    case $1 in
        -h | --help)
            display_help
            exit
            ;;
        -q | --quiet)
            QUIET=true
            ;;
        -r | --resolve)
            RESOLVE=true
            ;;
    esac
    shift
done

# Get path
if [[ $RESOLVE == true ]]; then
    DIR="$(realpath "$1")"
else
    DIR="$(realpath -L "$1")"
fi

if [[ ! -d "$DIR" ]]; then
    if [[ $QUIET == false ]]; then
        echo "$DIR does not exist"
    fi
    exit 2
fi

mapfile -t PATHS < <(echo "$PATH" | tr ':' '\n')

# check if path is in $PATH
for p in "${PATHS[@]}"; do
    if [[ $DIR == "$p" ]]; then
        if [[ $QUIET == false ]]; then
            COLORED_DIR="${BOLD}${MAGENTA}${DIR}${RESET}"
            echo -e "${PATH//$DIR/$COLORED_DIR}"
        fi
        exit 0
    fi
done

exit 1
