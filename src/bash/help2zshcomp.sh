#!/usr/bin/env bash
#
# help2zshcomp.sh
#
# Generates z shell completion script from help text.
set -e

TMPD=$(mktemp -d)

declare CMD                  # name of command to gen completions. Is last arg
declare OPT_HELP2MAN_ARGS    # additional arguments to pass to help2man
declare OPT_CMD_HELP_FLAG    # manually set command help flag
declare OPT_CMD_VERSION_FLAG # manually set command version flag
declare OPT_CMD_VERSION      # manually set command version
declare OPT_INSTALL=0        # install completions to ~/.zfunc
# usage: {0} [--help2man-args <arg_string>] [--cmd-help-flag <flag>] [--cmd-version-flag <flag>] [--cmd-version <version>] <command>
#
# --help2man-args <arg_string>
#     Arguments to pass to help2man
# --cmd-help-flag <flag>
#     Flag to pass to command to get help text
# --cmd-version-flag <flag>
#     Flag to pass to command to get version

show_help() {
  echo "usage: $0 [--help2man-args <arg_string>] [--cmd-help-flag <flag>] [--cmd-version-flag <flag>] [--cmd-version <version>] <command>"
  echo ""
  echo "  --help2man-args <arg_string>"
  echo "      Arguments to pass to help2man"
  echo "  --cmd-help-flag <flag>"
  echo "      Flag to pass to command to get help text"
  echo "  --cmd-version-flag <flag>"
  echo "      Flag to pass to command to get version"
  echo "  --cmd-version <version>"
  echo "      Version of command"
  echo "  -i, --install"
  echo "      Install completions to ~/.zfunc. Otherwise it will write to stdout"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help2man-args)
      shift
      OPT_HELP2MAN_ARGS=($1)
      shift
      ;;
    --cmd-help-flag)
      shift
      OPT_CMD_HELP_FLAG=$1
      shift
      ;;
    --cmd-version-flag)
      shift
      OPT_CMD_VERSION_FLAG=$1
      shift
      ;;
    --cmd-version)
      shift
      OPT_CMD_VERSION=$1
      shift
      ;;
    -i | --install)
      OPT_INSTALL=1
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      [[ -n $CMD ]] && echo "Error: command already specified" && exit 1
      CMD=$1
      shift
      ;;
  esac
done

if [[ -z $CMD ]]; then
  echo "Error: command not specified"
  show_help
  exit 1
fi

# dirs to generate completions into
mkdir -p "$TMPD/fish"
mkdir -p "$TMPD/zsh"

if ! command -v help2man &> /dev/null; then
  echo "Error: help2man not found"
  exit 1
fi
if ! command -v fish &> /dev/null; then
  echo "Error: fish not found"
  exit 1
fi
if ! command -v $CMD &> /dev/null; then
  echo "Error: $CMD not found"
  exit 1
fi

# check for generate_man_completion.py command
if ! command -v create_manpage_completions.py &> /dev/null; then
  if [[ -x /usr/share/fish/tools/create_manpage_completions.py ]]; then
    alias -- create_manpage_completions.py=/usr/share/fish/tools/create_manpage_completions.py
  else
    echo "Error: create_manpage_completions.py not found"
    exit 1
  fi
fi

if ! command -v zsh-manpage-completion-generator &> /dev/null; then
  echo "Error: zsh-manpage-completion-generator not found"
  exit 1
fi

declare -a help2man_args=()
if [[ -n $OPT_CMD_HELP_FLAG ]]; then
  help2man_args+=("--help-option=$OPT_CMD_HELP_FLAG")
fi
if [[ -n $OPT_CMD_VERSION_FLAG ]]; then
  help2man_args+=("--version-option=$OPT_CMD_VERSION_FLAG")
fi
if [[ -n $OPT_CMD_VERSION ]]; then
  help2man_args+=("--version-string=$OPT_CMD_VERSION")
fi
if [[ -n $OPT_HELP2MAN_ARGS ]]; then
  help2man_args+="$OPT_HELP2MAN_ARGS"
fi

help2man_expr="${help2man_args[@]} -o '$TMPD/$CMD.1' --no-discard-stderr $CMD"
# echo "help2man $help2man_expr"
bash -c "help2man $help2man_expr"
[[ $? -ne 0 ]] && echo "Error: help2man failed" && exit 1

create_manpage_completions.py -d "$TMPD/fish" "$TMPD/$CMD.1" > /dev/null
zsh-manpage-completion-generator -src "$TMPD/fish" -dst "$TMPD/zsh" > /dev/null

if [[ (-f "$HOME/.zfunc/_$CMD") && ($OPT_INSTALL -eq 1) ]]; then
  echo "Error: zsh completion file already exists at $HOME/.zfunc/_$CMD"
  exit 1
elif [[ $OPT_INSTALL -eq 1 ]]; then
  cp "$TMPD/zsh/_$CMD" "$HOME/.zfunc/_$CMD"
  echo "Installed zsh completion to $HOME/.zfunc/_$CMD"
  exit 0
else
  cat "$TMPD/zsh/_$CMD"
fi
