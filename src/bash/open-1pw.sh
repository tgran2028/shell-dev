#!/usr/bin/env bash
#
# activate-1pw.sh
# Open 1Password application. Check if 1Password window is already open, and if not, open 1Password in detached process.
set -e

start_1password() {
  # start detached 1Password process
  nohup /opt/1Password/1password > /dev/null 2>&1 &
}

cp_1password_key() {
  if [[ -z $ONEPW_KEY ]]; then
    printf "1password environment variable not now. Set \$ONEPW_KEY\n"
    return 1
  fi
  xsel --input --clipboard --trim <<< "$ONEPW_KEY"
}

open_1password() {
  # Check if 1Password is already running
  ONEPW_PID=$(pgrep -f "/opt/1Password/1password" 2> /dev/null)

  if [ -n "$ONEPW_PID" ]; then
    WIN="$(wmctrl -lp | grep $ONEPW_PID | awk '{print $1}')"
    if [ -n "$WIN" ]; then
      # If the window is found, activate it
      wmctrl -ia "$WIN"
    else
      # If the window is not found, open 1Password in detached mode
      start_1password
    fi
  fi
}

cp_1password_key
open_1password 2>/dev/null
