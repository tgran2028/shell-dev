#!/usr/bin/env bash

declare -i INDENT=2

# check to make sure shfmt is installed
if ! command -v shfmt &> /dev/null; then
  echo "shfmt is not installed. Please install it first."
  exit 1
fi

__show_help() {
  cat << 'EOF' | bat -l help -P --plain -f
usage: shfmt [flags] [path ...]

shfmt formats shell programs. If the only argument is a dash ('-') or no
arguments are given, standard input will be used. If a given path is a
directory, all shell scripts found under that directory will be used.

  --version  show version and exit

  -l,  --list      list files whose formatting differs from shfmt's
  -w,  --write     write result to file instead of stdout
  -d,  --diff      error with a diff when the formatting differs
  -s,  --simplify  simplify the code
  -mn, --minify    minify the code to reduce its size (implies -s)
  --apply-ignore   always apply EditorConfig ignore rules

Parser options:

  -ln, --language-dialect str  bash/posix/mksh/bats, default "auto"
  -p,  --posix                 shorthand for -ln=posix
  --filename str               provide a name for the standard input file

Printer options:

  -i,  --indent uint       0 for tabs (default), >0 for number of spaces
  -bn, --binary-next-line  binary ops like && and | may start a line
  -ci, --case-indent       switch cases will be indented
  -sr, --space-redirects   redirect operators will be followed by a space
  -kp, --keep-padding      keep column alignment paddings
  -fn, --func-next-line    function opening braces are placed on a separate line

Utilities:

  -f, --find   recursively find all shell files and print the paths
  --to-json    print syntax tree to stdout as a typed JSON
  --from-json  read syntax tree from stdin as a typed JSON

For more information, see 'man shfmt' and https://github.com/mvdan/sh.

EOF

  return 0
}

# parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      __show_help
      exit 0
      ;;
    -i | --indent)
      INDENT=$2
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

declare -a DEFAULT_OPTS=(
  '--indent' $INDENT
  '--case-indent'
  '--space-redirects'
  '--simplify'
)

# if script ran directly and not sourced
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  if [[ $# -eq 0 ]]; then
    __show_help
    exit $?
  else
    shfmt "${DEFAULT_OPTS[@]}" "$@"
  fi
fi
