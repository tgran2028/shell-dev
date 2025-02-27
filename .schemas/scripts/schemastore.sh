#!/bin/bash

download_catalog() {
  curl -fsSL https://www.schemastore.org/api/json/catalog.json -o ~/.cache/schemastore/catalog.json
}

get_catalog() {
  if [ ! -f ~/.cache/schemastore/catalog.json ]; then
    download_catalog
  fi
  # if older than 1 day, download again
  if test "$(find ~/.cache/schemastore/catalog.json -mmin +1440)"; then
    download_catalog
  fi
  cat ~/.cache/schemastore/catalog.json
}

search_catalog() {
  local name="$1"
  get_catalog | jq --arg name "$name" '.schemas[] | select(.name | ascii_downcase | test($name; "i"))'
}

list_names() {
  get_catalog | jq -rM '.schemas[].name'
}

download_schema() {
  local name="$1"
  local url=$(search_catalog "$name" | jq -rM '.url')
  local schema_dir="$HOME/.cache/schemastore/schemas"
  mkdir -p "$schema_dir"
  if [ -z "$url" ]; then
    echo "Schema not found: $name"
    return 1
  fi
  local schema_file="$schema_dir/$(basename "$url")"
  if [ ! -f "$schema_file" ]; then
    curl -fsSL "$url" -o "$schema_file"
  fi
  echo "$schema_file"
}

get_schema() {
  local name="$1"
  local schema_file="$(download_schema "$name")"
  if [ -z "$schema_file" ]; then
    return 1
  fi
  cat "$schema_file" | jq "${@:2}"
}

save_schema_to_cwd() {
  local name="$1"
  local schema_file="$(download_schema "$name")"
  if [ -z "$schema_file" ]; then
    return 1
  fi
  cp "$schema_file" .
}

if [ "$1" = "list" ]; then
  list_names
elif [ "$1" = "get" ]; then
  get_schema "$2" "${@:3}"
elif [ "$1" = "save" ]; then
  save_schema_to_cwd "$2"
else
  echo "Usage: $0 list | get <name> [jq filter] | save <name>"
  exit 1
fi
