#!/usr/bin/env bash


BROWSER=${CHROME_BROWSER:-google-chrome-beta}

if [ ! -x "$(command -v "$BROWSER")" ]; then
   printf '%s\n' "Browser $BROWSER not found, Set env CHROME_BROWSER to overwrite it"
    exit 1
fi

PROFILE_DEFAULT='Default'




# chrome://memory-internals/
# --restore-last-session ⊗
# --no-experiments
# --renderer-cmd-prefix   # The contents of this flag are prepended to the renderer command line. Useful values might be "valgrind" or "xterm -e gdb --args". 
