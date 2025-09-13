run_traceroute_test() {
    local target="$1"
    local log_path="$2"

    write_log_entry "--- Traceroute Test ---" "$log_path" "$COLOR_CYAN"

    local traceroute_cmd=""
    if command -v traceroute &>/dev/null; then
        traceroute_cmd="traceroute"
    elif [[ -x "/mnt/c/Windows/System32/tracert.exe" ]]; then
        traceroute_cmd="/mnt/c/Windows/System32/tracert.exe"
    else
        write_log_entry "Traceroute command not found." "$log_path" "$COLOR_RED"
        return 1
    fi

    # Run traceroute and log each line
    "$traceroute_cmd" "$target" | while IFS= read -r line; do
        write_log_entry "$line" "$log_path" "$COLOR_GRAY"
    done
}
