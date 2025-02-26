#/bin/bash

set -e

__apt_search() {
    local QUERY=$1
    apt-cache search --names-only "$QUERY" | awk '{print $1}' | sort | uniq
}

__apt_search "$@"
