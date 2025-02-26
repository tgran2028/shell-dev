#!/bin/bash

# Download dotfiles from a GitHub repository

# -------------------------------------------------------------------------------------------
# Example object from contents. All objects have the same schema.
#
#  `GET repos/{repo}/contents`
#
#  ```json
#  [
#    {
#      "name": ".editorconfig",
#      "path": ".editorconfig",
#      "sha": "627d1671945bb010f3c5b16efabc225985d6b431",
#      "size": 66,
#      "url": "https://api.github.com/repos/microsoft/vscode-docs/contents/.editorconfig?ref=main",
#      "html_url": "https://github.com/microsoft/vscode-docs/blob/main/.editorconfig",
#      "git_url": "https://api.github.com/repos/microsoft/vscode-docs/git/blobs/627d1671945bb010f3c5b16efabc225985d6b431",
#      "download_url": "https://raw.githubusercontent.com/microsoft/vscode-docs/main/.editorconfig",
#      "type": "file",
#      "_links": {
#        "self": "https://api.github.com/repos/microsoft/vscode-docs/contents/.editorconfig?ref=main",
#        "git": "https://api.github.com/repos/microsoft/vscode-docs/git/blobs/627d1671945bb010f3c5b16efabc225985d6b431",
#        "html": "https://github.com/microsoft/vscode-docs/blob/main/.editorconfig"
#      }
#    },
#    ...
#  ]
#
#  ```
# -------------------------------------------------------------------------------------------

REPO=microsoft/vscode-docs

get_repo_contents() {
  local repo="$1"
  local ep
  if [[ $# -gt 1 ]]; then
    ep="repos/$repo/contents/$((IFS=/; echo "${*:2}") | sed 's|^/||; s|/$||')"
  else
    ep="repos/$repo/contents"
  fi
  NO_COLOR=1 gh api "${ep%/}" --cache 5m | jq  -M '.'
}

get_repo_dotfiles() {
  local repo=$1
  gh api "repos/$repo/contents" --cache 1h | jq -M '[ .[] | select(.type == "file" and (.name | startswith("."))) ]'
}

ls_dotfiles() {
  local repo=$1
  get_repo_dotfiles $repo | jq -rM '.[] | .name'
}

get_dotfile_content() {
  local repo=$1
  local dotfile=$2

  gh api repos/$repo/contents/$dotfile --cache 1h | jq -rM '.content' | base64 -d > "${3:-/dev/stdout}"

}

dl_repo_dotfiles() {
  local repo
  local dotfiles

  # opts -d for target directory, -n to only download the ditfile with the same name (minus leading dot)
  local OPT_OUTPUT_DIR
  # local OPT_FILTER_NAME
  local OPT_QUIET

  local -a dotfile_urls

  while getopts "d:n:q:h:" opt; do
    case $opt in
      d) OPT_OUTPUT_DIR=$OPTARG ;;
      n) OPT_FILTER_NAME=$OPTARG ;;
      q) OPT_QUIET=true ;;
      h)
        cat << EOF
Usage: dl_repo_dotfiles [options] <repo>
  -d <dir>    Specify target directory to download dotfiles
  -n <name>   Download only the dotfile with the specified name
  -q          Quiet mode (suppress output)
  -h          Display this help message
EOF
        ;;
    esac
  done

  shift $((OPTIND - 1))
  repo="$1"

  if [ -z "$repo" ]; then
    echo "Error: missing repo argument"
    return 1
  fi

  if [ -z "$OPT_OUTPUT_DIR" ]; then
    OPT_OUTPUT_DIR=.
  fi

  # Get download URLs for all dotfiles in the repo, or if $OPT_FILTER_NAME is set, only the dotfile with the same name.
  # return raw list of download urls (selecting .download_url)
  dotfiles=$(get_repo_dotfiles $repo)
  # if $OPT_FILTER_NAME is set, only download the dotfile with the same name (minus leading dot).
  # if [ -n "$OPT_FILTER_NAME" ]; then
  #   dotfile_urls=($(echo "$dotfiles" | jq -rM "select(.name == \"$OPT_FILTER_NAME\") | .download_url"))
  # else
  #   dotfile_urls=$($(echo "$dotfiles" | jq -rM '.[].download_url'))
  # fi
  declare -a dotfile_urls=( $(get_repo_dotfiles $repo | jq -rM '.[].download_url') )


  if [ ${#dotfile_urls[@]} -eq 0 ]; then
    echo "No dotfiles found in the repository."
    return 1
  fi

  local dst
  # Download dotfiles

  [[ -z $OPT_QUIET ]] && echo -e "Downloading dotfiles from '$repo'...\n"

  for url in "${dotfile_urls[@]}"; do
    dst="$OPT_OUTPUT_DIR/$(basename $url)"

    # if file exists..
    if [[ -f $dst ]];then 
      # Overwrite?
      read -p "File $dst already exists. Overwrite? [y/N] " -n 1 -r
      # if not overwrite...
      if [[  "$(echo "${REPLY:-n}" | tr '[:upper:]' '[:lower:]' | cut -c1)" == "n" ]]; then
        # Change filename?
        read -p "Enter a new name for the file. If blank, the file will be skipped: " -r new_name
        if [[ -n "$new_name" ]]; then
          dst="$OPT_OUTPUT_DIR/$new_name"
        else
          continue
        fi
      fi
    fi
    curl -sSL -o "$dst" "$url"
    if [[ $? -ne 0 ]]; then
      echo "Error downloading $(basename $dst) from '$url' to '$dst'"
      return 1
    elif [ -z "$OPT_QUIET" ]; then
      echo "$(basename $dst): downloaded to $dst"
    fi
  done

  [[ -z $OPT_QUIET ]] && echo -e "\nDownload complete."

  return 0
}

main() {

  # subcommands:
  # - ls|list -> list all dotfiles in the repo
  # - get <dotfile> -> get the content of a dotfile. <dotfile> is the filename of the dotfile.
  # - dl|download -> download all dotfiles in the repo
  # - dl <dotfile> -> download a specific dotfile. <dotfile> is the filename of the dotfile.
  #
  # -h -> help

  __show_help() {
    cat << EOF
Usage {0} <subcommand> [options] <repo>

subcommands:
  
    list | ls         List all dotfiles in the repo
    get <dotfile>     Get the content of a dotfile, where <dotfile> is the filename of the dotfile.
    download | dl     Download all dotfiles in the repo
    download <dotfile> Download a specific dotfile, where <dotfile> is the filename of the dotfile.

download usage: {0} download [options] <repo> [dotfile]
  -d <dir>    Specify target directory to download dotfiles
  -n <name>   Download only the dotfile with the specified name
  -q          Quiet mode (suppress output)
  -h          Display this help message

EOF
  }

  if [[ $# -eq 0 || ${1} == "-h" ]]; then
    __show_help
    return 0
  fi

  local subcommand=$1
  shift

  case $subcommand in
    list | ls)
      ls_dotfiles $@
      ;;
    get)
      get_dotfile_content $@
      ;;
    download | dl)
      dl_repo_dotfiles $@
      ;;
    *)
      __show_help
      ;;
  esac

}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main $@
fi
