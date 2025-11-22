#!/bin/bash

run_ping_test() {
    local target="$1"
    local log_path="$2"
    local count=4
    local delay=1

    write_log_entry "--- Ping Test ---" "$log_path" "$COLOR_CYAN"
    write_log_entry "Pinging $target $count times with $delay sec delay" "$log_path" "$COLOR_GRAY"

    local sent=0
    local received=0
    local total_time=0
    local reply_time

    for ((i = 1; i <= count; i++)); do
        reply_time=$(ping -c 1 -W "$delay" "$target" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
        if [[ -n "$reply_time" ]]; then
            write_log_entry "Reply from $target: time=${reply_time}ms" "$log_path" "$COLOR_GREEN"
            ((received++))
            total_time=$(echo "$total_time + $reply_time" | bc)
        else
            write_log_entry "Request timed out." "$log_path" "$COLOR_RED"
        fi
        ((sent++))
        sleep "$delay"
    done

    local loss=0
    if [[ "$sent" -gt 0 ]]; then
        loss=$(( (sent - received) * 100 / sent ))
    fi

    local avg_time="N/A"
    if [[ "$received" -gt 0 ]]; then
        avg_time=$(echo "scale=2; $total_time / $received" | bc)
    fi

    write_log_entry "Ping Summary: Sent=$sent, Received=$received, Lost=$((sent - received)) ($loss%) Avg=${avg_time}ms" "$log_path" "$COLOR_GRAY"
}
