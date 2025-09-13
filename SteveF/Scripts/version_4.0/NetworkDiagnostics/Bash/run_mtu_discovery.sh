#!/bin/bash

run_mtu_discovery() {
    local target="$1"
    local log_path="$2"
    local mtu=1500
    local min_mtu=1200
    local step=10
    local found=0

    write_log_entry "--- MTU Discovery ---" "$log_path" "$COLOR_CYAN"
    write_log_entry "Probing MTU to $target with DF flag..." "$log_path" "$COLOR_GRAY"

    while [[ $mtu -ge $min_mtu ]]; do
        if ping -c 1 -M do -s $((mtu - 28)) "$target" &>/dev/null; then
            found=1
            break
        fi
        mtu=$((mtu - step))
    done

    if [[ $found -eq 1 ]]; then
        write_log_entry "MTU discovered: $mtu bytes" "$log_path" "$COLOR_GREEN"
        echo "$mtu"
    else
        write_log_entry "Unable to determine MTU (fragmentation detected at all tested sizes)" "$log_path" "$COLOR_RED"
        echo "Unknown"
    fi
}
