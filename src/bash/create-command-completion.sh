#!/usr/bin/env bash

set -e

# cmd="$1"
version_sting=${2:-}
cmd="$1"

if [[ -z $cmd ]]; then
  echo "Usage: $0 <command> [version_string]"
  exit 1
fi
if ! command -v "$cmd" &> /dev/null; then
  echo "$cmd not found, please install it first"
  exit 1
fi

tmpd=$(mktemp -d)

declare -A _d
_d[man]=$tmpd/man
_d[fish]=$tmpd/fish
_d[zsh]=$tmpd/zsh

# iter through to get k,v
for k in "${!_d[@]}"; do
  mkdir -p "${_d[$k]}"
done

#######################################
# check dependencies
#########################################

if ! command -v help2man &> /dev/null; then
  echo "help2man not found, please install it first"
  exit 1
fi

create_fish_compeltion='/usr/share/fish/tools/create_manpage_completions.py'
[[ -x $create_fish_compeltion ]] || {
  echo "create_fish_compeltion not found at $create_fish_compeltion"
  exit 1
}

create_zsh_completion='/usr/local/bin/zsh-manpage-completion-generator'
[[ -x $create_zsh_completion ]] || {
  echo "create_zsh_completion not found at $create_zsh_completion"
  exit 1
}

# create temp directories
for d in "${_d[@]}"; do
  mkdir -p "$d"
done

if man -w 1 "$cmd" >&/dev/null; then
  manpage_path=$(man -w 1 "$cmd")
else
  # create manpage from help
  manpage_path="${_d['man']}/${cmd}.1"
  _args=(
    --name "$cmd"
    --section 1
    --output "$manpage_path"
    --no-discard-stderr
  )
  if [[ -n $version_sting ]]; then
    _args+=("--version-string" "$version_sting")
  fi
  help2man "${_args[@]}" "$cmd" > "$manpage_path"
fi
if [[ ! -f $manpage_path ]]; then
  echo "Failed to create manpage for $cmd"
  exit 1
fi
echo "$manpage_path"
"$create_fish_compeltion" --directory "${_d[fish]}" "$manpage_path" &> /dev/null
"$create_zsh_completion" -dst "${_d['zsh']}" -src "${_d['fish']}" &> /dev/null
 
# copy manpage
man_target="$HOME/.local/share/man/man1/$cmd.1.gz"
[[ -f $man_target ]] || {
  if [[ $(file --mime-type -b "$manpage_path") != 'application/gzip' ]]; then
    gzip -q "$manpage_path"
    cp "$manpage_path.gz" "$man_target"
  else
    cp "$manpage_path" "$man_target"
  fi
}
echo "man: $man_target"

# copy fish completion
fish_target="$HOME/.config/fish/completions/$cmd.fish"
[[ -f $fish_target ]] || {
  cp "${_d[fish]}/$cmd.fish" "$fish_target"
}
echo "fish: $fish_target"

# copy zsh completion
zsh_target="$HOME/.zfunc/_$cmd"
[[ -f $zsh_target ]] || {
  cp "${_d[zsh]}/_$cmd" "$zsh_target"
}

echo 
echo "zsh: $zsh_target"
echo
bat -l zsh -u -P -f "$zsh_target"


