#!/usr/bin/bash



# Function to run a Docker container with the specified image and URL
run_singlefile() {
    local url
    local outfile
    local outfile_as_name
    local -i pretty=1
    local tmpf
    local doc

    . ~/.shell/functions/opt.sh

    tmpf="$(mktemp --suffix .html)"
    trap 'rm -f $tmpf' EXIT

    show_help() {
        txt="$(cat << EOF
run_singlefile 

Usage: run_singlefile [-o|--output <FILE>] [-O] [-np|--no-pretty] [-h|--help] <URL>

Options:
    -o, --output <FILE>         Save the output to the specified file
    -O                          Save the output to a file with the same name as the URL
    -np, --no-pretty            Do not prettify the output HTML
    -h, --help                  Display this help message

EOF
)"
    # get if terminal supports colors
    if [[ -t 1 ]]; then
        bat -l help -P --plain -f <<< "$txt"
    else
        echo "$txt"
    fi

    }

    if [[ $# -eq 0 ]]; then
        show_help
        return 1
    fi

    # OPTIND=1
    # local OPT

    # # Parse the command-line options
    # while shiftopt; do
    #     echo $OPT 
    #     case $OPT in
    #     -o | --outfile) outfile=$OPTARG;;
    #     -O) outfile_as_name=1;;
    #     -np | --no-pretty) pretty=0;;
    #     -h | --help) show_help; return 0;;
    #     *) 
    #         if [[ -z $url ]]; then
    #             url=$OPT
    #         else
    #             echo "Error: Invalid argument: $OPT"
    #             return 1
    #         fi
    #         ;;
    #     esac
    # done
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o | --output)
                shiftval
                outfile=$OPT_VAL
                ;;
            -O)
                outfile_as_name=1
                ;;
            -np | --no-pretty)
                pretty=0
                ;;
            -h | --help)
                show_help
                return 0
                ;;
            *)
                url=$1
                ;;
        esac
        shift
    done

    # echo "url: $url"

    if [[ -n $outfile_as_name ]]; then
        outfile=$(basename "$url")
        outfile="${outfile%.*}.html"
    fi

    # # Validate the URL format (basic validation)
    # if [[ ! "$url" =~ ^https?:// ]]; then
    #     echo "Error: Invalid URL format. URL should start with http:// or https://"
    #     return 1
    # fi

    # Run the Docker command with the provided URL
    docker run -it screenbreak/singlefile-dockerized "$url" | tee "$tmpf" > /dev/null

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to run the Docker container"
        return 1
    fi

    # if [[ $pretty -eq 1 ]]; then
    #     prettier --parser html --print-width 100 --tab-width 4 --prose-wrap never --single-attribute-per-line -w "$tmpf" > /dev/null
    # fi

    doc="$(cat "$tmpf")"
    if [[ -n $outfile ]]; then
        tee "$outfile" > /dev/null <<< "$doc"
        echo "$outfile"
    else
        echo "$doc"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If this script is executed, run the tests.
    run_singlefile "$@"
fi

