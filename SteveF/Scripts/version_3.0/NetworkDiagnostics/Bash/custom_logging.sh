#!/bin/bash

# ANSI color codes
COLOR_RESET="\033[0m"
COLOR_CYAN="\033[0;36m"
COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[1;33m"
COLOR_GRAY="\033[1;30m"

# Log entry function
write_log_entry() {
    local message="$1"
    local logpath="$2"
    local color="${3:-$COLOR_RESET}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Format output
    local formatted="${color}[${timestamp}] $message${COLOR_RESET}"

    # Print to console and append to log file
    echo -e "$formatted" | tee -a "$logpath"

    # Optional debug mode
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${COLOR_YELLOW}[DEBUG] Logged: $message${COLOR_RESET}"
    fi
}
