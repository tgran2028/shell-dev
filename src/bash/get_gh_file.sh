#!/bin/bash

# Convert string to array by specified delimiter

# function arr::split {
#   local -a arr
#   local delimiter
#   local string

#   # usage:
#   #  - split <string> -d <delimiter>
#   #  - split -d <delimiter> <string>
#   #  - split <string> <delimiter>

#   local -i pos=-1
#   while [[ $# -gt 0 ]]; do
#     pos=$((pos + 1))
#     case "$1" in
#       -d)
#         delimiter=$2
#         shift 2
#         ;;
#       *)
#         if [[ $pos -eq 0 ]]; then
#           string=$1
#         elif [[ $pos -eq 1 ]]; then
#           delimiter=$1
#         fi
#         shift
#         ;;
#     esac
#   done

#   IFS=$delimiter read -r -a arr <<< "$string"
#   echo "${array[@]}"
# }

# function arr::insert {
#   local -i index
#   local value
#   local -a array

#   # usage: insert <index> <value> <array>
#   # usage: insert <value> <array> -i <index>

#   while [[ $# -gt 0 ]]; do
#     case "$1" in
#       -i)
#         index=$2
#         shift 2
#         ;;
#       *)
#         if [[ -z $value ]]; then
#           value=$1
#         else
#           array=("$@")
#           break
#         fi
#         shift
#         ;;
#     esac
#   done

#   local -i arr_size=${#array[@]}
#   local -i pos_index

#   # if $i is positive, then it is the index
#   if [[ $index -gt 0 ]]; then
#     pos_index=$index
#   else
#     pos_index=$((arr_size + $(($index + 1))))
#   fi

#   # pos_index must be less than or equal to arr_size, else raise error
#   if [[ $pos_index -gt $arr_size ]]; then
#     echo "Index out of range"
#     return 1
#   fi
#   local -a new_array=(
#     "${array[@]:0:$pos_index}"
#     "$value"
#     "${array[@]:$pos_index}"
#   )
#   echo "${new_array[@]}"
# }

# function arr::pop {
#   local -i index
#   local -a array

#   # usage: remove <index> <array>
#   # usage: remove <array> -i <index>

#   while [[ $# -gt 0 ]]; do
#     case "$1" in
#       -i)
#         index=$2
#         shift 2
#         ;;
#       *)
#         if [[ -z $index ]]; then
#           index=$1
#         else
#           array=("$@")
#           break
#         fi
#         shift
#         ;;
#     esac
#   done

#   local -i arr_size=${#array[@]}
#   local -i pos_index

#   # if $i is positive, then it is the index
#   if [[ $index -gt 0 ]]; then
#     pos_index=$index
#   else
#     pos_index=$((arr_size + $(($index + 1))))
#   fi

#   # pos_index must be less than or equal to arr_size, else raise error
#   if [[ $pos_index -gt $arr_size ]]; then
#     echo "Index out of range"
#     return 1
#   fi

#   local -a new_array=(
#     "${array[@]:0:$pos_index}"
#     "${array[@]:$((pos_index + 1))}"
#   )
#   echo "${new_array[@]}"
# }

# function arr::join {
#   local -a array
#   local delimiter

#   # usage: join <array> -d <delimiter>
#   # usage: join -d <delimiter> <array>

#   local -i pos=-1
#   while [[ $# -gt 0 ]]; do
#     pos=$((pos + 1))
#     case "$1" in
#       -d)
#         delimiter=$2
#         shift 2
#         ;;
#       *)
#         if [[ $pos -eq 0 ]]; then
#           array=("$@")
#         elif [[ $pos -eq 1 ]]; then
#           delimiter=$1
#         fi
#         shift
#         ;;
#     esac
#   done

#   local IFS=$delimiter
#   echo "${array[*]}"
# }

# # function arr::unique {
# #     local -a array
# #     local -a unique_array

# #     # usage: unique <array>

# #     array=("$@")

# #     for item in "${array[@]}"; do
# #         if [[ ! " ${unique_array[@]} " =~ " ${item} " ]]; then
# #             unique_array+=("$item")
# #         fi
# #     done

# #     echo "${unique_array[@]}"
# # }

# function arr::to_json {
#   local -a arr=("$@")
#   printf '%s\n' "${arr[@]}" | jq -R . | jq -scM .
# }

# #printf '%s\n' "${arr[@]}" | jq -R . | jq -sc .

# #owner='home-assistant'
# #name='core'
# #fullname="${owner}/${name}"
# #branch='dev'
# #path='mypy.ini'

# # url_sg='https://sourcegraph.com/github.com/home-assistant/core/-/blob/mypy.ini'
# # url_sg_raw='https://sourcegraph.com/github.com/home-assistant/core/-/raw/mypy.ini'
# # gh_url='https://github.com/home-assistant/core/blob/dev/mypy.ini'
# # gh_url_raw='https://raw.githubusercontent.com/home-assistant/core/dev/mypy.ini'

# ### interpolate variables
# #URL_SG_BLOB="https://sourcegraph.com/github.com/${fullname}/-/blob/${path}"
# #URL_SG_RAW="https://sourcegraph.com/github.com/${fullname}/-/raw/${path}"
# #GH_URL_BLOB="https://github.com/${fullname}/blob/${branch}/${path}"
# #GH_URL_RAW="https://raw.githubusercontent.com/${fullname}/${branch}/${path}"

function help_text_util {

  local help_text
  local color='always' # [always|auto|never]
  local outfile

  local -a bat_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c | --color)
        color=$2
        shift 2
        ;;
      -o | --outfile)
        outfile=$2
        shift 2
        ;;
      --bat-args)
        IFS = ' ' read -r -a bat_args <<< "${2/\n/ }"
        shift 2
        ;;
      *)
        help_text=$1
        shift
        ;;
    esac
  done

  # trim newlines, then add newline at the end
  help_text=$(sed -e 's/^[[:space:]]*//;s/[[:space:]]*$//' <<< "$help_text")

}

function string::trim_whitespace {
  local str
  local mode='both' # [both|left|right]

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m | --mode)
        mode=$2
        shift 2
        ;;
      *)
        str=$1
        shift
        ;;
    esac
  done

  case "$mode" in
    both)
      echo "$str" | sed -e
      ;;
    left)
      echo "$str" | sed -e 's/^[[:space:]]*//'
      ;;
    right)
      echo "$str" | sed -e 's/[[:space:]]*$//'
      ;;
  esac
}

function get_gh_file_url {
  local fullname
  local path
  local owner
  local type='raw' # [raw|blob]

  local branch

  show_help() {
    cat << 'EOF'
Usage: 
 - get_gh_file -r <FULLNAME> -p <PATH>
 - get_gh_file -o <OWNER> -n <NAME> -p <PATH>
 - get_gh_file <OWNER>/<NAME>/<PATH> [options]

Get file content from github repository.

Options:
    -r, --repo-fullname <FULLNAME>    Repository fullname (owner/name)
    -n, --name <NAME>                 Repository name
    -o, --owner <OWNER>               Repository owner
    -p, --path <PATH>                 File path

    -b, --branch <BRANCH>             Repository branch (optional)
    --blob                            Get file blob url

Other options:
    -h, --help                        Show help

EOF

  }

  # if no args, show help
  if [[ $# -eq 0 ]]; then
    show_help
    return 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        show_help
        return 0
        ;;
      -r | --repo-fullname)
        fullname=$2
        shift 2
        ;;
      -n | --name)
        name=$2
        shift 2
        ;;
      -p | --path)
        path=$2
        shift 2
        ;;
      -o | --owner)
        owner=$2
        shift 2
        ;;
      -b | --branch)
        branch=$2
        shift 2
        ;;
      --blob)
        type='blob'
        ;;
      *)

        if [[ $(grep -o '/' <<< "$1" | wc -l) -eq 2 ]]; then
          owner=$(cut -d'/' -f1 <<< "$1")
          name=$(cut -d'/' -f2 <<< "$1")
          path=$(cut -d'/' -f3 <<< "$1")
          fullname="${owner}/${name}"
        fi
        shift 1
        ;;
    esac
  done
  # if $fullname, determine $owner and $name
  if [[ ! -z $fullname ]]; then
    IFS='/' read -r -a arr <<< "$fullname"
    owner=${arr[0]}
    name=${arr[1]}
  fi
  # if not $fullname, and ($owner and $name) are provided, then interpolate $fullname
  if [[ -z $fullname ]] && [[ ! -z $owner ]] && [[ ! -z $name ]]; then
    fullname="${owner}/${name}"
  fi

  # if not $branch, use '-'
  [[ -z $branch ]] && branch='-'

  # ensure path is provided
  if [[ -z $path ]]; then
    echo "Path is required"
    return 1
  fi

  local raw_url="https://sourcegraph.com/github.com/${fullname}/${branch}/${type}/${path}"
  echo "$raw_url"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  get_gh_file "$@"
fi
