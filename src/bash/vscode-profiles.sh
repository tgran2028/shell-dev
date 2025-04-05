#!/usr/bin/env bash

set -e

vscode_storage_file_path() {
  local -l app="${1:-code}"
  local config_dir storage_file

  case "${app}" in
    code)
      config_dir="$HOME/.config/Code"
      ;;
    code-insiders)
      config_dir="$HOME/.config/Code - Insiders"
      ;;
    vscodium)
      config_dir="$HOME/.config/VSCodium"
      ;;
    *)
      echo "Invalid app name: ${app}"
      return 1
      ;;
  esac

  storage_file="${config_dir}/User/globalStorage/storage.json"
  if [[ ! -f ${storage_file} ]]; then
    echo "Storage file not found: ${storage_file}"
    return 1
  fi
  echo "${storage_file}"
}

list_profile_names() {
  local storage_file="$1"

  [[ -f ${storage_file} ]] || {
    echo "Storage file not found: ${storage_file}"
    return 1
  }

  jq -r '.userDataProfiles.[].name' "$storage_file" | sort -u
}

list_vscode_profiles() {
  local app="$1"
  local storage_file

  storage_file=$(vscode_storage_file_path "$app") || return 1
  list_profile_names "$storage_file"
}

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <app_name>"
  echo "Where <app_name> can be 'code', 'code-insiders', or 'vscodium'."
  exit 1
fi
list_vscode_profiles "$@"
