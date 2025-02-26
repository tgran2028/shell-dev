#!/usr/bin/env bash

set -e

declare OPT_DELIMITER=':'
declare -l OPT_OUTPUT_FORMAT='string'
declare OPT_COLORIZE_OUTPUT=false
declare OPT_MUST_EXIST=false

declare -l OPT_RESOLOVE_TYPE='logical'
declare OPT_RESOLVE_PATH_FLAG=true
declare OPT_OUTFILE_PATH
declare -l OUTFILE_EXT


__debug_opts(){
  cat << EOF
OPT_DELIMITER: $OPT_DELIMITER
OPT_OUTPUT_FORMAT: $OPT_OUTPUT_FORMAT
OPT_COLORIZE_OUTPUT: $OPT_COLORIZE_OUTPUT
OPT_MUST_EXIST: $OPT_MUST_EXIST
OPT_RESOLOVE_TYPE: $OPT_RESOLOVE_TYPE
OPT_RESOLVE_PATH_FLAG: $OPT_RESOLVE_PATH_FLAG
OPT_OUTFILE_PATH: $OPT_OUTFILE_PATH
OUTFILE_EXT: $OUTFILE_EXT
EOF
}

# Added helper function to trim whitespace.
trim() {
  local str
  local NO_NEW_LINE=false
  local -a args=()

  for arg in "$@"; do
    case "$arg" in
      --) break ;;
      -n)
        NO_NEW_LINE=true
        shift
        ;;
      -h | --help)
        cat << 'EOF' | bat -l help -p --plain -f
Usage: trim [OPTIONS] [ARGS]

OPTIONS:
  -n  Do not print newline at the end of the string.
  -h  Show help

ARGS:
  [ARGS]  String to trim whitespace from.

NOTE:
  If stdin is a pipe, it will be read and trimmed. Otherwise, the arguments will be trimmed.

EOF
        return 0
        ;;
      *)
        args+=("$arg")
        shift
        ;;
    esac
    # Use sed to trim whitespace from the beginning and end of the string.
    echo "$arg" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
  done

  if [ -p /dev/stdin ]; then
    str=$(cat)
  else
    str="${args[*]}"
  fi

  if [[ "$NO_NEW_LINE" == true ]]; then
    echo "$str" | perl -pe 'chomp'
  else
    echo "$str" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
  fi
}

process_path_item() {
  local p="$1"

  # Trim and skip empty values.
  p="$(trim "$p")"
  if [[ -z "$p" ]]; then
    return 1
  fi
  if [[ $OPT_MUST_EXIST == true && ! -d "$p" ]]; then
    return 1
  fi
  if [[ -e "$p" ]]; then
    if [[ $OPT_RESOLOVE_TYPE == "resolved" ]]; then
      realpath -L "$p"
    elif [[ $OPT_RESOLOVE_TYPE == "logical" ]]; then
      realpath "$p"
    fi
  else 
    echo "$p"
  fi

  # [[ -z "$p" ]] && return 1
  # # Skip if must-exist option is set and p is not a directory.
  # [[ "$OPT_MUST_EXIST" == true && ! -d "$p" ]] && return 1

  # # Resolve path if enabled and if the path exists (when must-exist is set).
  # if [[ "$OPT_RESOLVE_PATH_FLAG" == true && "$OPT_MUST_EXIST" == true && -e "$p" ]]; then
  #   if [[ "$OPT_RESOLOVE_TYPE" == "resolved" ]]; then
  #     realpath -L "$p"
  #     return 0
  #   elif [[ "$OPT_RESOLOVE_TYPE" == "logical" ]]; then
  #     realpath "$p"
  #     return 0
  #   fi
  # fi
  # return 2
}

format_array() {
  local obj="$1"
  local fmt="$2"
  local delimiter="${3:-}"

  case "$fmt" in
    string)
      # Read the object into an array and join with the given delimiter
      read -r -a arr <<< "$obj"
      (
        IFS="$delimiter"
        echo "${arr[*]}"
      )
      ;;
    json)
      echo "$obj" | jq -R -M -s 'split(" ")'
      ;;
    yaml)
      echo "$obj" | jq -R -M -s 'split(" ")' | yq -p j -o y -PM
      ;;
    list)
      echo "$obj" | tr ' ' '\n'
      ;;
    *)
      echo "Invalid format. Must be one of [string, json, yaml, list]"
      return 1
      ;;
  esac
}
__show_help() {
  cat << 'EOF' | bat -l help -p --plain -f
Deduplicate path variable.

Usage: deduplicate_path [OPTIONS] <INPUT>

OPTIONS:
  -d, --delimiter <char>  delimiter to use for splitting path. Default is ':'
  -o, --output <path>     output path to write to. Default is $PATH

  -e, --must-exist            Remove non-existent directories from path
  -r, --resolve <type>    Resolve path. Options: [resolved, logical]. Defaults to logical.
  --no-resolve            Do not resolve path.

  -c, --color             Colorize stdout per format. No color by default.
  -f, --format            output format. Defaults to `string` (joined by delimiter). Options: [string, json, yaml, list]


  -h, --help              show help


ARGUMENTS:
    <INPUT>               Optional. input path to deduplicate. Default is $PATH

EOF
}

deduplicate_path() {
  local input_path
  local output_path
  local output

  local -a input_path_array
  local -a output_path_array=()

  local -a seen=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -h | --help)
        __show_help
        return 0
        ;;
      -d | --delimiter)
        [[ ! ${#2} -eq 1 ]] && echo "Delimiter must be a single character" && return 1
        OPT_DELIMITER="$2"
        shift 2
        ;;
      -f | --format)
        [[ ! "$2" =~ ^(string|json|yaml|list)$ ]] && echo "Invalid format. Must be one of [string, json, yaml, list]" && return 1
        OPT_OUTPUT_FORMAT="$2"
        shift 2
        ;;
      -e | --must-exist)
        OPT_MUST_EXIST=true
        shift
        ;;
      -r | --resolve)
        [[ ! "$2" =~ ^(resolved|logical)$ ]] && echo "Invalid resolve type. Must be one of [resolved, logical]" && return 1
        OPT_RESOLOVE_TYPE="$2"
        shift 2
        ;;
      --no-resolve)
        OPT_RESOLVE_PATH_FLAG=false
        shift
        ;;
      -o | --output)
        OPT_OUTFILE_PATH="$2"
        shift 2
        ;;
      -c | --color)
        OPT_COLORIZE_OUTPUT=true
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  __debug_opts
  ######################################################
  #                   CLEAN INPUT PATH                 #
  ######################################################

  #
  if [[ -p /dev/stdin ]]; then
    input_path="$(cat)"
  elif [[ -n "$1" ]]; then
    input_path="$1"
  else
    input_path="$PATH"
  fi
  input_path="$(
    trim "$(echo "${input_path}" | sed -e "s/${OPT_DELIMITER}\+/${OPT_DELIMITER}/g" -e "s/^${OPT_DELIMITER}//" -e "s/${OPT_DELIMITER}$//" | perl -pe 'chomp')"
  )"

  # create input_path_array
  IFS="$OPT_DELIMITER" read -r -a input_path_array <<< "$input_path"


  ######################################################
  #        PROCESS EACH PATH TO OUTPUT ARRAY           #
  ######################################################
  # splits

  # clean path:
  # - trim leading/trailing whitespace
  # - skip empty values
  # - skip if must-exist option is set and p is not a directory
  # - resolve path if enabled and if the path exists (when must-exist is set)
  # for p in "${input_path_array[@]}"; do

  #   clean_p="$(process_path_item "$p")"
  #   [[ $? -eq 1 ]] && continue
  #   # echo "$p | $clean_p"


  #   # Append unique, non-visited paths.
    # if [[ -z "${seen[$clean_p]}" ]]; then
    #   output_path_array+=("$clean_p")
    #   seen[$clean_p]=1
    # fi

  #   # check if in seen array
  #   for s in "${seen[@]}"; do
  #     if [[ "$s" == "$clean_p" ]]; then
  #       continue 2
  #     fi
  #   done

  #   # add to seen array
  #   seen+=("$clean_p")
  #   output_path_array+=("$clean_p")
  
  # done

  declare -a seen=()
  for p in "${input_path_array[@]}"; do
    clean_p="$(process_path_item "$p")"
    [[ $? -ne 0 || -z "$clean_p" ]] && echo "failed '$p' to '$clean_p'" && continue
    if echo "${seen[@]}" | tr ' ' '\n' | sort -u | grep -q "$clean_p" >/dev/null 2>&1; then
      echo "Duplicate path: $clean_p"
      continue
    fi
    seen+=("$clean_p")
    output_path_array+=("$clean_p")
  done
  
  # ######################################################
  # #                   OUTPUT PATH                      #
  # ######################################################

  output_path="$(
    IFS="$OPT_DELIMITER"
    echo "${output_path_array[*]}" | sed -e "s/${OPT_DELIMITER}${OPT_DELIMITER}/${OPT_DELIMITER}/g" -e "s/^${OPT_DELIMITER}//" -e "s/${OPT_DELIMITER}$//"
  )"

  echo "$output_path" | tr "$OPT_DELIMITER" '\n'
}
  # ######################################################
  # #                FORMAT OUTPUT (path or array)       #
  # ######################################################

  # case "$OPT_OUTPUT_FORMAT" in
  #   string)
  #     output="$output_path"
  #     OUTFILE_EXT='.txt'
  #     ;;
  #   json)
  #     # write output by convert output_path_array to json using jq
  #     output="$(
  #       IFS="$OPT_DELIMITER"
  #       echo "${output_path_array[*]}" | jq -R -M -s 'split(":")'
  #     )"
  #     OUTFILE_EXT='.json'
  #     [[ "$OPT_COLORIZE_OUTPUT" == true ]] && output="$(echo "$output" | jq -M | bat -l json -P --plain -f)"
  #     ;;
  #   yaml)
  #     # use yq
  #     output="$(
  #       IFS="$OPT_DELIMITER"
  #       echo "${output_path_array[*]}" | jq -R -M -s 'split(":")' | yq -p j -o y
  #     )"
  #     [[ "$OPT_COLORIZE_OUTPUT" == true ]] && output="$(echo "$output" | bat -l yaml -P --plain -f)"
  #     OUTFILE_EXT='.yaml'
  #     ;;
  #   list)
  #     # write as multiline array, one element per line
  #     output="$(
  #       IFS="$OPT_DELIMITER"
  #       echo "${output_path_array[*]}"
  #     )"
  #     OUTFILE_EXT='.list'
  #     ;;
  #   *)
  #     echo "Invalid format. Must be one of [string, json, yaml, list]"
  #     return 1
  #     ;;
  # esac



  # ######################################################
  # #                WRITE OUTPUT TO FILE (if selected)  #
  # ######################################################

  # # [[ -z "$OPT_OUTFILE_PATH" ]] && echo "no valid output" && exit 1
  # if [[ -n "$OPT_OUTFILE_PATH" ]]; then
  #   local outfile_stem outfile_dir outfile_abs

  #   # file stem from outfile (fixed substitution syntax)
  #   outfile_stem="$(basename "${OPT_OUTFILE_PATH//$OUTFILE_EXT/}")"
  #   # parent directory of outfile
  #   outfile_dir="$(dirname "$OPT_OUTFILE_PATH")"
  #   # absolute path of outfile
  #   outfile_abs="${outfile_dir}/${outfile_stem}${OUTFILE_EXT}"

  #   if [[ ! -d "$outfile_dir" ]]; then
  #     mkdir -p "$outfile_dir"
  #   fi

  #   echo "$output" | tee "$outfile_abs" > /dev/null

  # else
  #   echo "$output"
  # fi
# }

# ensure file not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  deduplicate_path "$@"
fi
