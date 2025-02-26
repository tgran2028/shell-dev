#!/usr/bin/env bash

BASEDIR="$HOME/.local/prettier"
cd "$BASEDIR" || exit 1
prettier "$@"
