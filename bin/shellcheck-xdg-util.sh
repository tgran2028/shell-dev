#!/bin/sh
#---------------------------------------------
#
#   shellcheck-xdg-util.sh
#
#	Shell script for shellchecking the xdg-utils scripts as a whole
#	translating line numbers back to the source files.
#
#   Copyright 2024, Slatian <baschdel@disroot.org>
#
#   LICENSE:
#
#   Permission is hereby granted, free of charge, to any person obtaining a
#   copy of this software and associated documentation files (the "Software"),
#   to deal in the Software without restriction, including without limitation
#   the rights to use, copy, modify, merge, publish, distribute, sublicense,
#   and/or sell copies of the Software, and to permit persons to whom the
#   Software is furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included
#   in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#   OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#   ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#   OTHER DEALINGS IN THE SOFTWARE.
#
#---------------------------------------------

set -e

if [ -z "$1" ] || [ "$1" = "--help" ] ; then
	echo "Usage: $(basename "$0") <script-name> [<shellcheck-option> ...]"
	exit
fi

if ! command -v shellcheck >/dev/null 2>/dev/null ; then
	echo "Please install shellcheck for this script to work!"
	exit 2
fi

SCRIPT="$(printf "%s" "$1" | sed 's/.in$//')"
shift 1

if ! [ -e "$SCRIPT.in" ] ; then
	echo "$SCRIPT.in source file was not found."
	exit 1
fi

SCRIPT_DIR="$(printf "%s" "$SCRIPT" | sed 's|[^/]*$||' )"
SCRIPT="$(printf "%s" "$SCRIPT" | grep -o '[^/]*$' )"

cd "$SCRIPT_DIR"

make "$SCRIPT"

# (pattern, nth_result=1)
find_line() {
	line="$(grep -Pn "^$1$" "$SCRIPT"  | cut -d: -f1 | head -n "${2:-1}" | tail -n 1)"
	echo "$line"
	printf 'Found \33[32m"%s"\33[00m at line %s\n' "$1" "$line" >&2
}

XDG_UTILS_COMMON_INCLUDE_LINE="$(find_line "#@xdg-utils-common@")"
XDG_UTILS_COMMON_LINES="$(wc -l ./xdg-utils-common.in | cut -d' ' -f1)"

#TODO: Remove the questionmarks here when the quoted sections are merged

XDG_UTILS_MANUALPAGE_BLOCK_START="$(find_line 'cat <<'" '?_MANUALPAGE'?")"
XDG_UTILS_MANUALPAGE_BLOCK_END="$(find_line '_MANUALPAGE')"

XDG_UTILS_USAGE_BLOCK_START="$(find_line 'cat <<'" '?_USAGE'?")"
XDG_UTILS_USAGE_BLOCK_END="$(find_line '_USAGE')"

XDG_UTILS_LICENSE_LINES="$(wc -l ../LICENSE)"

if [ -z "$XDG_UTILS_COMMON_INCLUDE_LINE" ] ; then
	echo "No '#@xdg-utils-common@' include found …"
	exit 1
fi

echo ""
echo "Running Shellcheck ..."

# Note on shellchecks ran diectly against the .in file:
# SC1111 is for Unicode quotes wich appear in the manual page sections
# SC2317 is unreachable code wich is caused by functions in the
#  xdg-utils-common.in file not being called.
#  This one should be updated once shellcheck gets a
#  "function never gets called" check with its own id.

shellcheck --color=always "./$SCRIPT.in" \
	-i SC2317

shellcheck --color=always "./$SCRIPT" \
	-e SC2317 \
	"$@" |
	awk \
	-v"source_name=$SCRIPT.in" \
	-v"include_start_line=$XDG_UTILS_COMMON_INCLUDE_LINE" \
	-v"manualpage_block_start=$XDG_UTILS_MANUALPAGE_BLOCK_START" \
	-v"manualpage_block_end=$XDG_UTILS_MANUALPAGE_BLOCK_END" \
	-v"usage_block_start=$XDG_UTILS_USAGE_BLOCK_START" \
	-v"usage_block_end=$XDG_UTILS_USAGE_BLOCK_END" \
	-v"include_lines=$XDG_UTILS_COMMON_LINES" \
	-v"license_lines=$XDG_UTILS_LICENSE_LINES" \
	'

BEGIN {
	after_include_offset = include_start_line + include_lines
}
/In [^ ]+ line [0-9]+:/ {
	line = $4+0
	in_file = source_name

	if ( line > manualpage_block_start+0 && line < manualpage_block_end+0) {
		line = line-manualpage_block_start
		in_file = "[_MANUALPAGE]"
	} else if (line > usage_block_start+0 && line < usage_block_end+0) {
		line = line-usage_block_start
		in_file = "[_USAGE]"
	} else if (line > include_start_line+0 && line < after_include_offset+0) {
		in_file="xdg-utils-common.in"
		line = line-include_start_line
	}

	if (in_file == source_name) {
		orig_line = line
		if (orig_line > manualpage_block_end+0) {
			line = line - (manualpage_block_end - manualpage_block_start)+1
		}
		if (orig_line > usage_block_end+0) {
			line = line - (usage_block_end - usage_block_start)+1
		}
		if (orig_line > after_include_offset+0) {
			line = line - include_lines
		}
		line = line - license_lines
	}
	print "\x1b[01;34mIn " in_file " line " line  ":\x1b[00m\x1b[09m"
}

{
	// Pass everything from shellcheck through
	print
}
	'



echo "Shellcheck done."
