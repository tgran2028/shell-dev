#!/usr/bin/env bash

copy-1password() {
  echo -n "$ONEPW_KEY" | sed 's/^[ \t]*//;s/[ \t]*$//' | xclip -selection clipboard
}

alias cp1pw='copy-1password'
