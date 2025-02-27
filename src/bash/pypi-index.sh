#!/bin/bash

index_path=~/.cache/pypi.simple-index.json

save_index() {

  curl -fsSL 'https://pypi.org/simple/' | htmlq a -t \
    | {
      # remove leading/trailing whitespace
      sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
        |
        # remove empty lines
        grep -v '^$' \
        |
        # unique
        sort -u \
        |
        # convert to json
        jq -R -s -M -c \
          --arg timestamp "$(date +%s)" \
          --arg host 'pypi.org' \
          '{host: $host, last_update: $timestamp | tonumber, packages: split("\n") | map(select(length > 0))}' \
        |
        # output
        tee "$index_path" > /dev/null
    }

}

get_timedelta() {
  local ref_timestamp=$1
  local uom=${2:-sec}
  local now=$(date +%s)

  # validate input
  [[ $ref_timestamp =~ ^[0-9]+$ ]] || echo "Invalid timestamp: $ref_timestamp" >&2

  # calculate delta
  local delta=$((now - ref_timestamp))

  # uom [second|minute|hour|day]
  case $uom in
    s | sec | second | seconds)
      echo $delta
      ;;
    m | min | minute | minutes)
      echo $((delta / 60))
      ;;
    h | hour | hours)
      echo $((delta / 3600))
      ;;
    d | day | days)
      echo $((delta / 86400))
      ;;
    *)
      echo "Invalid unit of measure: $uom" >&2
      return 1
      ;;
  esac
}

ensure_index_updated() {

  if [[ -f $index_path ]]; then
    jq -rM '.last_update' "$index_path" | {
      read -r last_update
      now=$(date +%s)
      if ((now - last_update > 86400)); then
        save_index
      fi
    }
  else
    save_index
  fi
}

pypi_ls_pkgs() {

  ensure_index_updated

  jq -rM '.packages.[]' "$index_path" | {
    while IFS= read -r pkg; do
      echo "$pkg"
    done
  }
}

pypi_get_pkg_data_from_api() {
  local pkg="$1"
  local url="https://pypi.org/pypi/${pkg}/json"
  {
    # GET /pypi/{pkg}/json HTTP/1.1
    curl -fsSL "$url" -H 'Accept: application/json' -H 'Host: pypi.org' \
      |
      # pretty print JSON
      jq -M '.' \
      |
      # page with bat
      bat -l json --plain --file-name "$pkg.json" --pager 'less -RF'
  }
}

# GET /pypi/{pkg}/json HTTP/1.1
# Host: pypi.org
# Accept: application/json
pypi_get_pkg_data() {
  local pkg="$1"
  local cache_dir=~/.cache/pypi/packages
  local cache_file="$cache_dir/$pkg.json"

  [[ ! -d $cache_dir ]] && mkdir -p "$cache_dir"

  # if [[ -f $cache_file ]]; then
  #   # compare timestamp, if less than 24 hours, use cached data
  #   jq -r '.last_update' "$cache_file" | {
  #     read -r last_update
  #     now=$(date +%s)
  #     if ((((now - last_update)) > (24 * 60 * 60))); then
  #       jq -rM '.data' "$cache_file"
  #       return 0
  #     fi
  #   }
  # fi

  if [[ -f $cache_file ]]; then
    jq -rM '.data' "$cache_file"
    return 0
  fi

  local url="https://pypi.org/pypi/${pkg}/json"
  curl "$url" \
    -H 'Accept: application/json' \
    -H 'Host: pypi.org' \
    -fsS \
    | jq -cM \
      --arg timestamp "$(date +%s)" \
      --arg name "$pkg" \
      --arg url "$url" \
      '{name: $name, url: $url, last_update: $timestamp | tonumber, data: .info }' \
    | tee "$cache_file" \
    | jq '.data'
}

pypi_fuzzy_search() {
  local q="${1:-}"
  pypi_ls_pkgs | fzf \
    --query="$q" \
    --multi \
    --tiebreak=index \
    --bind=ctrl-s:toggle-sort \
    --preview-window 'down:50%' \
    --border \
    --preview 'curl -fsL https://pypi.org/pypi/{}/json | jq -C .info | bat -l json --plain' \
    --header 'Select package:' \
    --bind 'tab:execute-silent(echo pip install {+})+abort'

  # --header 'Select package:' \
  # --bind 'tab:execute-silent(echo pip install {+})+abort'

}
# --preview-window 'down:50%' \
# --border \
# --preview 'pypi_get_pkg_daa {+}' \
# --header 'Select package:' \
# --bind 'tab:execute-silent(echo pip install {+})+abort'

main() {
  pypi_fuzzy_search "$@"
}

if [[ "/home/tim/.shell/pypi-index.sh" == "$0" ]]; then
  main "$@"
fi

#   runtime_shell=$(ps -p $$ -o comm=)
#   if [[ $runtime_shell == "bash" ]]; then
#     export -f pypi_get_pkg_data_from_api
#     export -f pypi_fuzzy_search
#     export -f pypi_ls_pkgs
#     export -f pypi_get_pkg_data
#   elif [[ $runtime_shell == "zsh" ]]; then
#     autoload -Uz add-zsh-hook
#     # typeset -fx pypi_get_pkg_data_from_api
#     # typeset -fx pypi_fuzzy_search
#     # typeset -fx pypi_ls_pkgs
#   fi
#   unset runtime_shell
# fi

# cat << EOF
# BASH_SOURCE[0]: ${BASH_SOURCE[0]}
# 0: ${0}
# EOF

# typeset -p | grep -i 'pypi'

# echo "${0}"
# export -f pypi_get_pkg_data_from_api
# export -f pypi_fuzzy_search
# export -f pypi_ls_pkgs
# export -f pypi_get_pkg_data

# alias pypi-ls=pypi_ls_pkgs
# alias pypi-get=pypi_get_pkg_data_from_api
# alias pypi-search=pypi_fuzzy_search
