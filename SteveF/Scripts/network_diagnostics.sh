#!/bin/bash

# ===============================
# Network Diagnostics Script (Linux)
# ===============================

# === Config ===
TARGET="1.1.1.1"
PING_COUNT=4
PING_CYCLES=3
PING_DELAY=2
BUFFER_PACKET_SIZE=1500

ENABLE_PING=true
ENABLE_TRACEROUTE=true
ENABLE_BUFFERBLOAT=true

LOG_DIR="$HOME/network_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/NetworkTest_$(date +%Y%m%d_%H%M%S).log"

# === Color Echo ===
function color_echo {
    local color="$1"; shift
    case "$color" in
        red) echo -e "\e[31m$*\e[0m" ;;
        green) echo -e "\e[32m$*\e[0m" ;;
        yellow) echo -e "\e[33m$*\e[0m" ;;
        cyan) echo -e "\e[36m$*\e[0m" ;;
        gray) echo -e "\e[90m$*\e[0m" ;;
        *) echo "$*" ;;
    esac
    echo "$*" >> "$LOG_FILE"
}

# === Ping Test ===
function run_ping_test {
    local all_pings=()
    local success_count=0
    local total_pings=$((PING_COUNT * PING_CYCLES))

    color_echo cyan "\n--- Ping Test ---"

    for ((i=1; i<=PING_CYCLES; i++)); do
        color_echo cyan "--- Cycle $i ---"
        output=$(ping -c "$PING_COUNT" "$TARGET")
        while IFS= read -r line; do
            if [[ "$line" =~ time=([0-9.]+) ]]; then
                latency=${BASH_REMATCH[1]}
                all_pings+=("$latency")
                success_count=$((success_count + 1))
                [[ $(echo "$latency > 200" | bc) -eq 1 ]] && color="yellow" || color="green"
            elif [[ "$line" =~ "100% packet loss" ]]; then
                color="red"
            else
                color="gray"
            fi
            color_echo "$color" "$line"
        done <<< "$output"
        sleep "$PING_DELAY"
    done

    if (( ${#all_pings[@]} > 0 )); then
        min=$(printf '%s\n' "${all_pings[@]}" | sort -n | head -1)
        max=$(printf '%s\n' "${all_pings[@]}" | sort -n | tail -1)
        sum=0
        for val in "${all_pings[@]}"; do sum=$(echo "$sum + $val" | bc); done
        avg=$(echo "scale=2; $sum / ${#all_pings[@]}" | bc)

        jitter=0
        if (( ${#all_pings[@]} > 1 )); then
            diffs=()
            for ((j=1; j<${#all_pings[@]}; j++)); do
                diff=$(echo "${all_pings[j]} - ${all_pings[j-1]}" | bc | awk '{print ($1>=0)?$1:-$1}')
                diffs+=("$diff")
            done
            jitter_sum=0
            for d in "${diffs[@]}"; do jitter_sum=$(echo "$jitter_sum + $d" | bc); done
            jitter=$(echo "scale=2; $jitter_sum / ${#diffs[@]}" | bc)
        fi
    else
        min=max=avg=jitter=0
    fi

    success_rate=$(echo "scale=2; $success_count / $total_pings * 100" | bc)
    color_echo cyan "Ping Summary: Success Rate = $success_rate% ($success_count/$total_pings), Latency (ms) => Min=$min, Max=$max, Avg=$avg, Jitter=$jitter"
}

# === Traceroute ===
function run_traceroute_test {
    color_echo cyan "\n--- Traceroute ---"
    traceroute "$TARGET" | while read -r line; do
        if [[ "$line" =~ ([0-9]+)\s*ms ]]; then
            latency="${BASH_REMATCH[1]}"
            [[ "$latency" -gt 200 ]] && color="yellow" || color="cyan"
        elif [[ "$line" =~ \* ]]; then
            color="red"
        else
            color="gray"
        fi
        color_echo "$color" "$line"
    done
}

# === Bufferbloat Test ===
function run_bufferbloat_test {
    local packet_size="$BUFFER_PACKET_SIZE"
    local fragment_detected=false

    color_echo cyan "--- Bufferbloat Test ---"
    while true; do
        output=$(ping -c 4 -s "$packet_size" -M do "$TARGET" 2>&1)
        fragment_detected=false
        while IFS= read -r line; do
            if [[ "$line" =~ "Message too long" ]]; then
                fragment_detected=true
                color="yellow"
            elif [[ "$line" =~ "100% packet loss" ]]; then
                color="red"
            else
                color="green"
            fi
            color_echo "$color" "$line"
        done <<< "$output"

        if $fragment_detected; then
            color_echo yellow "Fragmentation detected at $packet_size bytes. Retesting with smaller size..."
            packet_size=$((packet_size - 20))
        else
            color_echo cyan "No fragmentation detected at $packet_size bytes."
            break
        fi
    done
}

# === Diagnostics Orchestrator ===
function run_diagnostics {
    $ENABLE_PING && run_ping_test
    $ENABLE_TRACEROUTE && run_traceroute_test
    $ENABLE_BUFFERBLOAT && run_bufferbloat_test
    color_echo cyan "\nFull log saved to $LOG_FILE"
}

# === Menu ===
while true; do
    echo -e "\n=== Network Diagnostic Menu ==="
    echo "1. Full Diagnostic"
    echo "2. Ping Only"
    echo "3. Traceroute Only"
    echo "4. Bufferbloat Test"
    echo "5. Exit"
    read -p "Select an option (default 5): " choice
    choice=${choice:-5}

    [[ "$choice" == "5" ]] && color_echo green "Exiting script..." && break

    read -p "Enter domain/IP to test (default $TARGET): " input_target
    TARGET=${input_target:-$TARGET}

    case "$choice" in
        1)
            ENABLE_PING=true
            ENABLE_TRACEROUTE=true
            ENABLE_BUFFERBLOAT=true
            ;;
        2)
            ENABLE_PING=true
            ENABLE_TRACEROUTE=false
            ENABLE_BUFFERBLOAT=false
            ;;
        3)
            ENABLE_PING=false
            ENABLE_TRACEROUTE=true
            ENABLE_BUFFERBLOAT=false
            ;;
        4)
            ENABLE_PING=false
            ENABLE_TRACEROUTE=false
            ENABLE_BUFFERBLOAT=true
            ;;
        *) color_echo red "Invalid choice."; continue ;;
    esac

    run_diagnostics
done
