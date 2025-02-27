#!/bin/bash

# set -e

# shellcheck source=/etc/os-release
declare -l dist_codename="$(lsb_release -cs 2> /dev/null)"

BASE_URL='https://manpages.ubuntu.com/manpages.gz/'

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

test_url() {
  local url="$1"
  local target_status_code=${2:-"200"}
  local actual_status_code
  local tmpf=$(mktemp)
  local -i retcode

  actual_status_code=$(
    curl \
      -o /dev/null \
      --silent \
      --head \
      --write-out '%{http_code}\n' "$url"
  )
  echo "$actual_status_code" | grep -q "$target_status_code" &> /dev/null
  retcode=$?
  if [ $retcode -ne 0 ]; then
    log_error "Failed to download '$url'. Expected status code: $target_status_code, Actual status code: $actual_status_code"
  fi
  return $retcode
}

dl_url() {
  local url="$1"
  local test=${2:-false}
  local tmpf

  if [ "$test" = true ]; then
    test_url "$url" || return 1
  fi

  test_url "$url" || return 1

  trap 'rm -f "$tmpf" &> /dev/null' EXIT

  local -l file_suffix
  file_suffix=$(awk -F'.' '{print ($2 ? $2 : "")}' <<< "$url")
  if [ -z "$file_suffix" ]; then
    tmpf=$(mktemp --suffix ".html")
  else
    tmpf=$(mktemp --suffix ".$file_suffix")
  fi

  wget -qO "$tmpf" "$url" > /dev/null
  cat "$tmpf" && rm -f "$tmpf" &> /dev/null
}

logfile=/tmp/outpu.txt
if [[ -r $logfile ]]; then
  rm -f $logfile
fi
touch $logfile

# Debug logging functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $*" #&>> "$logfile"
}

log_debug() {
  if [ "${DEBUG:-false}" = true ]; then
    echo -e "${BLUE}[DEBUG]${NC} $*"
  fi
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

# Build sections array correctly
sections=($(seq 1 9))

json_array="[]" # Initialize an empty JSON array

# Properly assign temp directory
# tempd="$(mktemp -d)"
tempd="${TEMPDIR}/manpages"
mkdir -p "$tempd"

log_info "temp manpages dir: $tempd"

for sec in "${sections[@]}"; do
  man_dir_name="man${sec}"
  man_dir="$(echo "${tempd}/${man_dir_name}" | sed -e 's/\/\//\//g')"
  mkdir -p "$man_dir"

  # log_info "man_dir_name: ${man_dir_name}"
  # log_info "man_dir: ${man_dir}"

  sec_url="${BASE_URL}${dist_codename}/${man_dir_name}/"
  # log_info "sections url: ${sec_url}"

  # Retrieve the list of files with .gz extension and log the debug info
  declare -a filenames=($(curl -fsSL https://manpages.ubuntu.com/manpages.gz/noble/man1/ | htmlq -a href a | grep -E '\.gz$' | xargs))
  log_info "Fetched number of files for ${man_dir_name}: ${#filenames[@]}"
  # log_info "# of files: ${#filenames[@]}"

  for name in "${filenames[@]}"; do
    # log_info "name: $name"
    # dl_url="${sec_url}${name}"
    dl_outfile="${man_dir}/${name}"

    pkg_name=$(cut -d'.' -f1 <<< "$name")

    url="$(echo "${sec_url}${name}" | sed -e 's/\/\//\//g')"

    if [[ ! -f "$dl_outfile" ]]; then
      wget -qO "$dl_outfile" "$url" &> /dev/null
    fi

    json_data="$(jq -n \
      --arg section "$sec" \
      --arg manpage_dir_name "$man_dir_name" \
      --arg manpage_dir_path "$man_dir" \
      --arg pkg "$pkg_name" \
      --arg filename "$name" \
      --arg url "$url" \
      '{
            section: $section, 
            manpage_dir_name: $manpage_dir_name, 
            manpage_dir_path: $manpage_dir_path, 
            pkg_name: $pkg, 
            filename: $filename, 
            url: $url
        }' | jq -M)"

    # append $json_data (object) to $json_array (array)
    json_array=$(jq --argjson new_obj "$json_data" '. += [$new_obj]' <<< "$json_array")
    echo "$json_array" | jq -M | tee "${tempd}/processed_manpages.json" > /dev/null

    echo "$json_data" | jq

    # log_info "json_data: $json_data"

    # with jq, get length of array
    # log_info "array length: $(jq '. | length' <<< "$json_array")"

    # # Function to convert associative array to JSON
    # convert_to_json() {
    #     local -n array=$1
    #     local json="{"
    #     local key
    #     local value

    #     for key in "${!array[@]}"; do
    #         value=$(printf '%s' "${array[$key]}" | jq -R .)  # Ensure proper escaping
    #         json+="\"$key\": $value,"
    #     done

    #     # Remove trailing comma and close the JSON object
    #     json="${json%,}}"

    #     echo "$json"
    # }

    #     json='{'
    #     for key in "${!dat[@]}"; do
    #         value=$(printf '%s' "${array[$key]}" | jq -R .)  # Ensure proper escaping
    #         json+="\"$key\": $value,"
    #     done
    #     echo "$json_string" | jq .

    # # Convert the $data associative array to JSON
    # json_string=$(convert_to_json data)

    # # Optionally, use jq to format the JSON string
    # echo "$json_string" | jq .

    # # convert $data to json obj with jq
    # declare -a jq_args=()
    # for k in "${!data[@]}"; do
    #     v="${data[$k]}"
    #     jq_args+=("--arg" "$k" "$v")
    # done
    # json_data="$(jq -n "${jq_args[@]}" '{
    #     section: $section,
    #     manpage_dir: $manpage_dir,
    #     pkg: $pkg,
    #     filename: $filename,
    #     url: $url
    # }')"
    # log_info "json_data: $json_data"

    # Example download command; remove 'break' and uncomment to download all files.
    # break
    # curl -fsSL "$url" | gunzip > "/usr/share/man/..."
  done
done
