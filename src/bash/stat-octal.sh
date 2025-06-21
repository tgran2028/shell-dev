#!/usr/bin/env bash

get_octal_perms() {
    local opt_copy=false file mode

    # parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--copy) opt_copy=true; shift ;;
            # -h|--help) 
            #     echo "Usage: $0 [-c|--copy] <file>"
            #     return
            #     ;;
            *) 
                file=$1
                shift 
                ;;
        esac
    done

    [[ -z $file ]] && { 
        echo "Usage: $0 [-c|--copy] <file>"
        return 1
    }

    if ! mode=$(stat -c '%a' -- "$file" 2>/dev/null); then
        echo "Error: could not stat '$file'."
        return 1
    fi

    if $opt_copy; then
        printf '%s' "$mode" | xclip -selection clipboard
    else
        printf '%s\n' "$mode"
    fi
}

# make it available as a shell command 
if [[ -n $BASH_VERSION ]];then
    # if sourced
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    complete -c get_octal_perms -a "ls -d */" -f
    export -f get_octal_perms
    else 
        get_octal_perms "$@"
    fi
elif [[ -n $ZSH_VERSION ]]; then
    # if sourced
    if [[ "${(%):-%N}" != "${(%):-%x}" ]]; then
        get_octal_perms "$@"
        return 0
    fi

    # add _files as completion for get_octal_perms 
    
else
    complete -c get_octal_perms -a "ls -d */"
fi
