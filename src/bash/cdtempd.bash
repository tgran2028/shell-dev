#!/bin/bash
#
# cdtempd.sh

function cdtempd {
  declare -g tempd
  tempd="$(mktemp -d tempd.XXXXXX)"
  cd "$tempd" || exit 1
  echo "$tempd"
}
