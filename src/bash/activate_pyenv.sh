#!/usr/bin/env bash

# ensures PYENV_ROOT is set and pyenv bin is in PATH
# also unsets and functions masking 'pyenv'
function ensure_pyenv_init_cmd {
  local pyenv_root

  [[ -x "$HOME/.pyenv/bin/pyenv" ]] && export PYENV_ROOT="$($HOME/.pyenv/bin/pyenv root)"

  pyenv_root=${PYENV_ROOT:-"$HOME/.pyenv"}

  # check pyenv dir
  [[ ! -d "$pyenv_root" ]] && echo "no directory found at $pyenv_root"
  [[ ! -x $pyenv_root/bin/pyenv ]] && echo 'pyenv executable not found' && return 1

  # Unset pyenv if it's a function
  unset -f pyenv > /dev/null 2>&1

  # Add $PYENV_ROOT/bin to PATH if not already present
  if [[ ! "$PATH" =~ "$pyenv_root/bin" ]]; then
    export PATH="$pyenv_root/bin:$PATH"
  fi

  if ! command -v pyenv > /dev/null 2>&1; then
    echo "pyenv command not found"
    return 1
  fi

  # Set PYENV_ROOT and initialize pyenv
  export PYENV_ROOT="$(pyenv root)"

  # echo "$(which pyenv) init -" | sed "s|$HOME|~|g"
}

function get_pyenv_init_script {
  local CMD
  CMD="$(ensure_pyenv_init_cmd)"
  eval "$CMD"
}

function init_pyenv {
  source <(get_pyenv_init_script)
}

# if script is sourced, activate pyenv
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  declare -f activate_pyenv
  init_pyenv > /dev/null
else
  echo "$(get_pyenv_init_script)"
fi
