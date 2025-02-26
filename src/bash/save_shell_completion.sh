#!/bin/bash

declare -A SHELL_COMPLETION_DIRS
SHELL_COMPLETION_DIRS["zsh"]="$HOME/.zfunc"
SHELL_COMPLETION_DIRS["bash"]="$HOME/.local/share/bash-completion/completions"
SHELL_COMPLETION_DIRS["fish"]="$HOME/.config/fish/completions"

#########################################
# Get output filename based on shell differences
# Args:
# 0 - name of command for which completion is being saved
# 1 - shell for which completion is being saved [zsh | bash | fish]
# Output:
# stdout - filename
function get_file_name {
    local cmd=$1
    local shell=$2

    case $shell in
        zsh)
            echo "_$cmd"
            ;;
        bash)
            echo "$cmd"
            ;;
        fish)
            echo "$cmd.fish"
            ;;
        *)
            echo "Unknown shell"
            exit 1
            ;;
    esac
}

# function display_help {
#     cat << EOF
# Usage: CMD -c command_name -s shell -t completion_file_text [OPTIONS]

# Arguments:
#     -c, --command   command_name: The name of the command for which the completion is being saved
#     -s, --shell     shell: The shell for which the completion is being saved. Options: ${SHELLS[@]}
#     -t, --text      completion_file_text: The text to be saved in the completion file

# Options:
#     -f, --force: Force overwrite of existing completion file
#     -v, --verbose: Verbose output
#     -h, --help: Display this help message
# EOF
# }

# #########################################
# # Save completion file for a command
# #
# function save_completion {

#   local command_name
#   local shell
#   local completion_file_text

#   ############
#   # OPTIONS
#   ############
#   local FORCE=0
#   local VERBOSE=0
#   local -a SHELLS=("zsh" "bash" "fish")

# while [[ $# -gt 0 ]]; do
#     key="$1"

#     case $key in
#         -h|--help)
#             display_help
#             exit 0
#             ;;
#         -c|--command)
#             command_name="$2"
#             shift # past argument
#             shift # past value
#             ;;
#         -s|--shell)
#             shell="$2"
#             shift # past argument
#             shift # past value
#             ;;
#         -t|--text)
#             completion_file_text="$2"
#             shift # past argument
#             shift # past value
#             ;;
#         -f|--force)
#             FORCE=1
#             shift # past argument
#             ;;
#         -v|--verbose)
#             VERBOSE=1
#             shift # past argument
#             ;;
#         *)
#             echo "Invalid option: $1" >&2
#             exit 1
#             ;;
#     esac
# done

#     if [[ -r $completion_file_text ]]; then
#         completion_file_text="$(cat $completion_file_text)"
#     fi

#     echo "command_name: $command_name"
#     echo "shell: $shell"
#     echo "completion_file_text: $completion_file_text"

#   # Check if required options are set
#   if [[ -z $command_name || -z $shell || -z $completion_file_text ]]; then
#     echo "Usage: completion_saver_util -c command_name -s shell -t completion_file_text [-fv]"
#     exit 1
#   fi
#     if [[ -r $completion_file_text ]]; then
#         completion_file_text="$(cat $completion_file_text)"
#     fi

#   # varios info for debugging
#   if [[ $VERBOSE == true ]]; then

#     echo "args:"
#     echo "  command_name: $command_name"
#     echo "  shell: $shell"
#     echo "  completion_file_text: $completion_file_text"
#     echo
#     echo "  force: $FORCE"
#     echo
#     echo "completion dirs:"
#     for i in "${!SHELL_COMPLETION_DIRS[@]}"; do
#         echo "  $i: ${SHELL_COMPLETION_DIRS[$i]}"
#     done
#   fi

#   # destination for completion file
#   local outfile="${SHELL_COMPLETION_DIRS[$shell]}/$(get_completion_file_name "$command_name" "$shell")"
#   # exit if file exits and force is not set
#   if [[ -f $outfile && $FORCE == false ]]; then
#     echo "Completion file already exists. Use -f to overwrite."
#     exit 1
#   fi
#   [[ $VERBOSE == true ]] && echo "outfile: $outfile"

#   # save completion file
#   echo "$completion_file_text" > "$outfile"
#   return 0
# }

# ### main
# if [[ $# -eq 0 ]]; then
#     display_help
#     exit 1
# fi

# save_completion "$@"
# echo "$@"

echo "${SHELL_COMPLETION_DIRS[$2]}/$(get_file_name $1 $2)"
