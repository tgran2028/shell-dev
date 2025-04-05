#!/bin/bash

set -euo pipefail

atuin_daemon::show_help() {
    cat <<EOF | bat -l help -P --plain
Usage: $0 [COMMAND] [OPTIONS]

Controls the atuin daemon process

Commands:
  start              Start the atuin daemon
  stop               Stop the atuin daemon
  restart            Restart the atuin daemon
  status             Show the atuin daemon status

Options:
    -h, --help       Show this help message
}

EOF
}

atuin_daemon::status() {
    local OPT_PID_ONLY=false
    local OPT_QUIET=false

    local is_running

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -p | --pid-only)
            OPT_PID_ONLY=true
            shift
            ;;
        -q | --quiet)
            OPT_RETCODE_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        esac
    done

    if ps aux | grep -q '[a]tuin daemon' 2>&1 >/dev/null; then
        if [[ $OPT_PID_ONLY == true ]]; then
            ps aux | grep '[a]tuin daemon' | awk '{print $2}' | head -n 1
            return 0
        elif [[ $OPT_QUIET == true ]]; then
            return 0
        else
            ps aux | grep '[a]tuin daemon'
        fi
    else
        if [[ $OPT_PID_ONLY == true || $OPT_RETCODE_ONLY == true ]]; then
            return 1
        else
            echo "atuin daemon is not running"
            return 1
        fi
    fi
}

atuin_daemon::start() {

    if atuin_daemon::status -q; then
        echo "atuin daemon is already running"
        return 0
    fi

    nohup atuin daemon >/dev/null 2>&1 &
    echo "atuin daemon started"
}

atuin_daemon::stop() {
    if atuin_daemon::status -q; then
        local pid
        pid=$(atuin_daemon::status -p)
        kill "$pid"
        echo "atuin daemon stopped"
    else
        echo "atuin daemon is not running"
    fi
}

atuin_daemon::restart() {
    atuin_daemon::stop >/dev/null
    atuin_daemon::start >/dev/null
    echo "atuin daemon restarted"
}

atuin_daemon::main() {
    if [[ $# -eq 0 ]]; then
        atuin_daemon::show_help
        exit 1
    fi

    case "$1" in
    -h | --help)
        atuin_daemon::show_help
        exit 0
        ;;
    start)
        atuin_daemon::start
        ;;
    stop)
        atuin_daemon::stop
        ;;
    restart)
        atuin_daemon::restart
        ;;
    status)
        atuin_daemon::status "${@:2}"
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
    esac
}

atuin_daemon::main "$@"
# vim: set ft=sh ts=4 sw=4 et:
