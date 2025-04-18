#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# bat-extras | Copyright (C) 2019 eth-p | MIT License
#
# Repository: https://github.com/eth-p/bat-extras
# Issues:     https://github.com/eth-p/bat-extras/issues
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090 disable=SC2155
SELF_NC="${BASH_SOURCE:-$0}"
SELF="$(cd "$(dirname "${SELF_NC}")" && cd "$(dirname "$(readlink "${SELF_NC}" || echo ".")")" && pwd)/$(basename "$(readlink "${SELF_NC}" || echo "${SELF_NC}")")"
# --- BEGIN LIBRARY FILE: pager.sh ---
is_pager_less() {
  [[ "$(pager_name)" == "less" ]]
  return $?
}
is_pager_bat() {
  [[ "$(pager_name)" == "bat" ]]
  return $?
}
is_pager_disabled() {
  [[ -z "$(pager_name)" ]]
  return $?
}
pager_name() {
  _detect_pager 1>&2
  echo "$_SCRIPT_PAGER_NAME"
}
pager_version() {
  _detect_pager 1>&2
  echo "$_SCRIPT_PAGER_VERSION"
}
pager_exec() {
  if [[ -n $SCRIPT_PAGER_CMD ]]; then
    "$@" | pager_display
    return $?
  else
    "$@"
    return $?
  fi
}
pager_display() {
  if [[ -n $SCRIPT_PAGER_CMD ]]; then
    if [[ -n $SCRIPT_PAGER_ARGS ]]; then
      "${SCRIPT_PAGER_CMD[@]}" "${SCRIPT_PAGER_ARGS[@]}"
      return $?
    else
      "${SCRIPT_PAGER_CMD[@]}"
      return $?
    fi
  else
    cat
    return $?
  fi
}
_detect_pager() {
  if [[ $_SCRIPT_PAGER_DETECTED == "true" ]]; then return; fi
  _SCRIPT_PAGER_DETECTED=true
  if [[ -z ${SCRIPT_PAGER_CMD[0]} ]]; then
    _SCRIPT_PAGER_VERSION=0
    _SCRIPT_PAGER_NAME=""
    return
  fi
  local output
  local output1
  output="$("${SCRIPT_PAGER_CMD[0]}" --version 2>&1)"
  output1="$(head -n 1 <<< "$output")"
  if [[ $output1 =~ ^less[[:blank:]]([[:digit:]]+) ]]; then
    _SCRIPT_PAGER_VERSION="${BASH_REMATCH[1]}"
    _SCRIPT_PAGER_NAME="less"
  elif [[ $output1 =~ ^bat(cat)?[[:blank:]]([[:digit:]]+) ]]; then
    __BAT_VERSION="${BASH_REMATCH[2]}"
    _SCRIPT_PAGER_VERSION="${BASH_REMATCH[2]}"
    _SCRIPT_PAGER_NAME="bat"
  else
    _SCRIPT_PAGER_VERSION=0
    _SCRIPT_PAGER_NAME="$(basename "${SCRIPT_PAGER_CMD[0]}")"
  fi
}
_configure_pager() {
  SCRIPT_PAGER_ARGS=()
  if [[ -n ${PAGER+x} ]]; then
    SCRIPT_PAGER_CMD=($PAGER)
  else
    SCRIPT_PAGER_CMD=("less")
  fi
  if [[ -n ${BAT_PAGER+x} ]]; then
    SCRIPT_PAGER_CMD=($BAT_PAGER)
    SCRIPT_PAGER_ARGS=()
    return
  fi
  if is_pager_bat; then
    SCRIPT_PAGER_CMD=("less")
    SCRIPT_PAGER_ARGS=()
  fi
  if is_pager_less; then
    SCRIPT_PAGER_CMD=("${SCRIPT_PAGER_CMD[0]}" -R --quit-if-one-screen)
    if [[ "$(pager_version)" -lt 500 ]]; then
      SCRIPT_PAGER_CMD+=(--no-init)
    fi
  fi
}
if [[ -t 1 ]]; then
  _configure_pager
else
  SCRIPT_PAGER_CMD=()
  SCRIPT_PAGER_ARGS=()
fi
# --- END LIBRARY FILE ---
# --- BEGIN LIBRARY FILE: print.sh ---
printc() {
  printf "$(sed "$_PRINTC_PATTERN" <<< "$1")" "${@:2}"
}
printc_init() {
  case "$1" in
    true) _PRINTC_PATTERN="$_PRINTC_PATTERN_ANSI" ;;
    false) _PRINTC_PATTERN="$_PRINTC_PATTERN_PLAIN" ;;
    "[DEFINE]") {
      _PRINTC_PATTERN_ANSI=""
      _PRINTC_PATTERN_PLAIN=""
      local name
      local ansi
      while read -r name ansi; do
        if [[ -z $name && -z $ansi ]] || [[ ${name:0:1} == "#" ]]; then
          continue
        fi
        ansi="${ansi/\\/\\\\}"
        _PRINTC_PATTERN_PLAIN="${_PRINTC_PATTERN_PLAIN}s/%{$name}//g;"
        _PRINTC_PATTERN_ANSI="${_PRINTC_PATTERN_ANSI}s/%{$name}/$ansi/g;"
      done
      if [[ -t 1 && -z ${NO_COLOR+x} ]]; then
        _PRINTC_PATTERN="$_PRINTC_PATTERN_ANSI"
      else
        _PRINTC_PATTERN="$_PRINTC_PATTERN_PLAIN"
      fi
    } ;;
  esac
}
print_warning() {
  printc "%{YELLOW}[%s warning]%{CLEAR}: $1%{CLEAR}\n" "batman" "${@:2}" 1>&2
}
print_error() {
  printc "%{RED}[%s error]%{CLEAR}: $1%{CLEAR}\n" "batman" "${@:2}" 1>&2
}
printc_init "[DEFINE]" << END
	CLEAR	\x1B[0m
	RED		\x1B[31m
	GREEN	\x1B[32m
	YELLOW	\x1B[33m
	BLUE	\x1B[34m
	MAGENTA	\x1B[35m
	CYAN	\x1B[36m

	DEFAULT \x1B[39m
	DIM		\x1B[2m
END
# --- END LIBRARY FILE ---
# --- BEGIN LIBRARY FILE: opt.sh ---
SHIFTOPT_HOOKS=()
SHIFTOPT_SHORT_OPTIONS="VALUE"
setargs() {
  _ARGV=("$@")
  _ARGV_LAST="$((${#_ARGV[@]} - 1))"
  _ARGV_INDEX=0
  _ARGV_SUBINDEX=1
}
getargs() {
  if [[ $1 == "-a" || $1 == "--append" ]]; then
    if [[ $_ARGV_INDEX -ne "$((_ARGV_LAST + 1))" ]]; then
      eval "$2=(\"\${$2[@]}\" $(printf '%q ' "${_ARGV[@]:_ARGV_INDEX}"))"
    fi
  else
    if [[ $_ARGV_INDEX -ne "$((_ARGV_LAST + 1))" ]]; then
      eval "$1=($(printf '%q ' "${_ARGV[@]:_ARGV_INDEX}"))"
    else
      eval "$1=()"
    fi
  fi
}
resetargs() {
  setargs "${_ARGV_ORIGINAL[@]}"
}
_shiftopt_next() {
  _ARGV_SUBINDEX=1
  ((_ARGV_INDEX++)) || true
}
shiftopt() {
  [[ $_ARGV_INDEX -gt $_ARGV_LAST ]] && return 1
  OPT="${_ARGV[$_ARGV_INDEX]}"
  unset OPT_VAL
  if [[ $OPT =~ ^-[a-zA-Z0-9_-]+=.* ]]; then
    OPT_VAL="${OPT#*=}"
    OPT="${OPT%%=*}"
  fi
  if [[ $OPT =~ ^-[^-]{2,} ]]; then
    case "$SHIFTOPT_SHORT_OPTIONS" in
      PASS) _shiftopt_next ;;
      CONV)
        OPT="-$OPT"
        _shiftopt_next
        ;;
      VALUE) {
        OPT="${_ARGV[$_ARGV_INDEX]}"
        OPT_VAL="${OPT:2}"
        OPT="${OPT:0:2}"
        _shiftopt_next
      } ;;
      SPLIT) {
        OPT="-${OPT:_ARGV_SUBINDEX:1}"
        ((_ARGV_SUBINDEX++)) || true
        if [[ $_ARGV_SUBINDEX -gt ${#OPT} ]]; then
          _shiftopt_next
        fi
      } ;;
      *)
        printf "shiftopt: unknown SHIFTOPT_SHORT_OPTIONS mode '%s'" \
          "$SHIFTOPT_SHORT_OPTIONS" 1>&2
        _shiftopt_next
        ;;
    esac
  else
    _shiftopt_next
  fi
  local hook
  for hook in "${SHIFTOPT_HOOKS[@]}"; do
    if "$hook"; then
      shiftopt
      return $?
    fi
  done
  return 0
}
shiftval() {
  if [[ -n ${OPT_VAL+x} ]]; then
    return 0
  fi
  if [[ $_ARGV_SUBINDEX -gt 1 && $SHIFTOPT_SHORT_OPTIONS == "SPLIT" ]]; then
    OPT_VAL="${_ARGV[$((_ARGV_INDEX + 1))]}"
  else
    OPT_VAL="${_ARGV[$_ARGV_INDEX]}"
    _shiftopt_next
  fi
  if [[ $OPT_VAL =~ -.* ]]; then
    printc "%{RED}%s: '%s' requires a value%{CLEAR}\n" "batman" "$ARG"
    exit 1
  fi
}
setargs "$@"
_ARGV_ORIGINAL=("$@")
# --- END LIBRARY FILE ---
# --- BEGIN LIBRARY FILE: opt_hook_color.sh ---
hook_color() {
  SHIFTOPT_HOOKS+=("__shiftopt_hook__color")
  __shiftopt_hook__color() {
    case "$OPT" in
      --no-color) OPT_COLOR=false ;;
      --color) {
        case "$OPT_VAL" in
          "") OPT_COLOR=true ;;
          always | true) OPT_COLOR=true ;;
          never | false) OPT_COLOR=false ;;
          auto) return 0 ;;
          *)
            printc "%{RED}%s: '--color' expects value of 'auto', 'always', or 'never'%{CLEAR}\n" "batman"
            exit 1
            ;;
        esac
      } ;;
      *) return 1 ;;
    esac
    printc_init "$OPT_COLOR"
    return 0
  }
  if [[ -z $OPT_COLOR ]]; then
    if [[ -t 1 ]]; then
      OPT_COLOR=true
    else
      OPT_COLOR=false
    fi
    printc_init "$OPT_COLOR"
  fi
}
# --- END LIBRARY FILE ---
# --- BEGIN LIBRARY FILE: opt_hook_version.sh ---
hook_version() {
  SHIFTOPT_HOOKS+=("__shiftopt_hook__version")
  __shiftopt_hook__version() {
    if [[ $OPT == "--version" ]]; then
      printf "%s %s\n\n%s\n%s\n" \
        "batman" \
        "2024.08.24" \
        "Copyright (C) 2019-2021 eth-p | MIT License" \
        "https://github.com/eth-p/bat-extras"
      exit 0
    fi
    return 1
  }
}
# --- END LIBRARY FILE ---
# -----------------------------------------------------------------------------
hook_color
hook_version
# -----------------------------------------------------------------------------
FORWARDED_ARGS=()
MAN_ARGS=()
BAT_ARGS=()
OPT_EXPORT_ENV=false

SHIFTOPT_SHORT_OPTIONS="SPLIT"
while shiftopt; do
  case "$OPT" in
    --export-env) OPT_EXPORT_ENV=true ;;
    --paging | --pager | --wrap)
      shiftval
      FORWARDED_ARGS+=("${OPT}=${OPT_VAL}")
      BAT_ARGS+=("${OPT}=${OPT_VAL}")
      ;;
    *) MAN_ARGS+=("$OPT") ;;
  esac
done

if "$OPT_COLOR"; then
  BAT_ARGS+=("--color=always" "--decorations=always")
else
  BAT_ARGS+=("--color=never" "--decorations=never")
fi

if [[ -z ${BAT_STYLE+x} ]]; then
  export BAT_STYLE="grid"
fi

# -----------------------------------------------------------------------------
# When called as the manpager, do some preprocessing and feed everything to bat.

if [[ ${BATMAN_IS_BEING_MANPAGER:-} == "yes" ]]; then
  print_manpage() {
    sed -e 's/\x1B\[[0-9;]*m//g; s/.\x08//g' \
      | "batcat" --language=man "${BAT_ARGS[@]}"
    exit $?
  }

  if [[ ${#MAN_ARGS[@]} -eq 1 ]]; then
    # The input was passed as a file.
    cat "${MAN_ARGS[0]}" | print_manpage
  else
    # The input was passed via stdin.
    cat | print_manpage
  fi

  exit
fi

# -----------------------------------------------------------------------------
if [[ -n ${MANPAGER} ]]; then BAT_PAGER="$MANPAGER"; fi
export MANPAGER="env BATMAN_IS_BEING_MANPAGER=yes bash $(printf "%q " "$SELF" "${FORWARDED_ARGS[@]}")"
export MANPAGER="${MANPAGER%"${MANPAGER##*[![:space:]]}"}"
export MANROFFOPT='-c'

# If `--export-env`, print exports to use batman as the manpager directly.
if "$OPT_EXPORT_ENV"; then
  printf "export %s=%q\n" \
    "MANPAGER" "$MANPAGER" \
    "MANROFFOPT" "$MANROFFOPT"
  exit 0
fi

# If no argument is provided and fzf is installed, use fzf to search for man pages.
if [[ ${#MAN_ARGS[@]} -eq 0 ]] && [[ -z $BATMAN_LEVEL ]] && command -v "fzf" &> /dev/null; then
  export BATMAN_LEVEL=1

  selected_page="$(man -k . | "fzf" --delimiter=" - " --reverse -e --preview="
		echo {1} \
		| sed 's/, /\n/g;' \
		| sed 's/\([^(]*\)(\([0-9A-Za-z ]\))/\2\t\1/g' \
		| BAT_STYLE=plain xargs -n2 batman --color=always --paging=never
	")"

  if [[ -z $selected_page ]]; then
    exit 0
  fi

  # Some entries from `man -k .` may include "synonyms" of a man page's title.
  # For example, the manual for kubectl-edit will appear as:
  #
  #   kubectl-edit(1), kubectl edit(1) - Edit a resource on the server
  #
  # `man` only needs one name/title, so we're taking the first one here.
  selected_page_unaliased="$(echo "$selected_page" | cut -d, -f1)"

  # Convert the page(section) format to something that can be fed to the man command.
  while read -r line; do
    if [[ $line =~ ^(.*)\(([0-9a-zA-Z ]+)\) ]]; then
      MAN_ARGS+=("${BASH_REMATCH[2]}" "$(echo ${BASH_REMATCH[1]} | xargs)")
    fi
  done <<< "$selected_page_unaliased"
fi

# Run man.
command man "${MAN_ARGS[@]}"
exit $?
