#!/usr/bin/env bash
#
# Description:
#   Checks if the atuin daemon is running. If not, starts it detached from the terminal and
#   appends the output to a log file. It uses the atuin command (found on PATH or from a known location).
#
# Usage:
#   $(basename "$0") [OPTIONS]
#
# Options:
#   -q, --quiet       Suppress informational output.
#   -h, --help        Show this help message and exit.
#
# Exit Codes:
#   0   On success
#   1   When an error occurs

set -euo pipefail

OPT_QUIET=0
OPT_STATUS_ONLY=0
OPT_GET_INFO=0
OPT_START=0
DEBUG="${DEBUG:-}"

usage() {
    local _pager=cat
    if command -v bat &>/dev/null; then
        _pager='bat -l help -P --plain'
    fi
    $_pager <<EOF
Usage: $(basename "$0") [OPTIONS]

Commands:

status - Check if the atuin daemon is running. If not, start it.
start - Start the atuin daemon if it is not already running.
info - Get the atuin daemon configuration and status.

Options:
  -q, --quiet       Suppress informational output.
  -h, --help        Show this help message and exit.

EOF
}
if [[ $# -eq 0 ]]; then
    usage
    exit 1
# parse subcommand
elif [[ $# -gt 0 ]]; then
    case "$1" in
    status)
        OPT_STATUS_ONLY=1
        shift
        ;;
    start)
        OPT_START=1
        shift
        ;;
    info)
        OPT_GET_INFO=1
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown subcommand: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
fi

# Process command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
    -q | --quiet)
        OPT_QUIET=1
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
done

if [[ -n $DEBUG ]]; then
    set -x
fi

get_logfile_path() {
    local LOGDIR="${XDG_DATA_HOME:-$HOME/.local/share}/atuin/logs"
    local logfile="${LOGDIR}/atuin-daemon.log"
    if [[ ! -d $LOGDIR ]]; then
        mkdir -p "$LOGDIR"
    fi
    if [[ ! -e $logfile ]]; then
        touch -- "$logfile"
    fi
    echo "$logfile"
}

__log() {
    local -u level="$1"
    # check if in 'debug', 'info', 'warn', 'error', 'fatal'
    [[ "$level" =~ ^(DEBUG|INFO|WARN|ERROR|FATAL)$ ]] || echo "Invalid log level: $level" >&2 && return 1
    shift
    local _pager=cat
    if command -v bat &>/dev/null; then
        _pager='bat -l help -P --plain'
    fi
    [[ $OPT_QUIET -eq 0 ]] && echo "$level:" "$@" | $_pager >&2
}

log::info() {
    #   [[ $OPT_QUIET -eq 0 ]] && echo "INFO:" "$@" >&2
    __log INFO "$@"
}

log::debug() {
    if [[ -n $DEBUG && $OPT_QUIET -eq 0 ]]; then
        # echo "DEBUG:" "$@" >&2
        __log DEBUG "$@"
    fi
}

log::error() {
    #   echo "ERROR:" "$@" >&2
    __log ERROR "$@"
}

get_atuin_cmd() {
    if command -v atuin &>/dev/null; then
        echo "atuin"
    elif [[ -x "$HOME/.cargo/bin/atuin" ]]; then
        echo "$HOME/.cargo/bin/atuin"
    else
        return 1
    fi
}

check_atuin_daemon_status() {
    # Check if a process containing "atuin daemon" is running
    pgrep -f "atuin daemon" >/dev/null 2>&1
}

start_atuin_daemon() {
    local atuin_cmd
    atuin_cmd="$(get_atuin_cmd)" || {
        log::error "Could not find atuin command"
        return 1
    }

    log::info "Starting atuin daemon"
    # Start using nohup; append output to the log file.
    nohup "$atuin_cmd" daemon >>"$LOG_FILE" 2>&1 &
    disown

    # Allow the daemon a moment to start before checking.
    sleep 1

    if ! check_atuin_daemon_status; then
        log::error "Failed to start atuin daemon"
        return 1
    fi

    log::info "Atuin daemon started"
    return 0
}

get_atuin_daemon_info() {
    local atuin_cmd
    local atuin_config_file
    local atuin_status
    atuin_cmd="$(get_atuin_cmd)" || {
        log::error "Could not find atuin command"
        return 1
    }
    if ! command -v yq &>/dev/null; then
        log::error "yq is required to parse the atuin daemon config"
        return 1
    fi
    atuin_config_file="$("$atuin_cmd" info | grep 'client config' | awk '{print $NF}' | sed 's/"//g')"
    if [[ ! -f $atuin_config_file ]]; then
        log::error "Atuin daemon config file not found"
        return 1
    fi
    atuin_status="$(check_atuin_daemon_status && echo "true" || echo "false")"
    yq -p toml -o json -PM '.daemon' "$atuin_config_file" | jq -r -M --arg config_path "$atuin_config_file" --arg status "$atuin_status" '{path: $config_path, status: $status | tobool, daemon_config: .}'
}

#######################
# Main
#######################
LOG_FILE=$(get_logfile_path)

if [[ $OPT_STATUS_ONLY -eq 1 ]]; then
    if check_atuin_daemon_status; then
        log::info "Atuin daemon is running"
        exit 0
    else
        log::info "Atuin daemon is not running"
        exit 1
    fi
elif [[ $OPT_START -eq 1 ]]; then
    if check_atuin_daemon_status; then
        log::info "Atuin daemon is already running"
        exit 0
    else
        start_atuin_daemon
        if ! check_atuin_daemon_status; then
            log::error "Atuin daemon is not running"
            exit 1
        fi
        exit 0
    fi
elif [[ $OPT_GET_INFO -eq 1 ]]; then
    get_atuin_daemon_info
    exit $?
else
    log::error "No subcommand specified"
    usage
    exit 1
fi

exit 0
