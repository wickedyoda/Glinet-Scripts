#!/bin/bash

# Source dependencies
source "$(dirname "$0")/custom_logging.sh"
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/run_ip_geolocation.sh"
source "$(dirname "$0")/run_ping_test.sh"
source "$(dirname "$0")/run_traceroute.sh"
source "$(dirname "$0")/run_mtu_discovery.sh"
source "$(dirname "$0")/run_speedtest.sh"

# Create log file
log_path="./logs/diagnostics_$(date '+%Y%m%d_%H%M%S').log"
mkdir -p ./logs

# Display menu
echo "Network Diagnostics Menu"
echo "1. Run full diagnostics"
echo "2. Run ping test"
echo "3. Run traceroute"
echo "4. Run speed test"
echo "5. Run MTU discovery"
echo "6. Run IP geolocation"
echo "0. Exit"
read -p "Select an option: " choice

# Prompt for target if needed
if [[ "$choice" != "0" ]]; then
    read -p "Enter target IP or URL (default: $DEFAULT_TARGET): " target
    target=${target:-$DEFAULT_TARGET}
fi

# Execute selected diagnostics
case "$choice" in
    1)
        write_log_entry "Running full diagnostics on $target" "$log_path" "$COLOR_CYAN"
        run_ip_geolocation_test "$log_path"
        run_ping_test "$target" "$log_path"
        run_traceroute_test "$target" "$log_path"
        mtu_value=$(run_mtu_discovery "$target" "$log_path")
        run_speedtest "$log_path"
        ;;
    2)
        run_ping_test "$target" "$log_path"
        ;;
    3)
        run_traceroute_test "$target" "$log_path"
        ;;
    4)
        run_speedtest "$log_path"
        ;;
    5)
        mtu_value=$(run_mtu_discovery "$target" "$log_path")
        ;;
    6)
        run_ip_geolocation_test "$log_path"
        ;;
    0)
        echo "Exiting diagnostics."
        exit 0
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac

# Summary block
write_log_entry "--- Summary ---" "$log_path" "$COLOR_CYAN"
write_log_entry "Target: $target" "$log_path" "$COLOR_GRAY"
[[ -n "$mtu_value" ]] && write_log_entry "MTU: ${mtu_value} bytes" "$log_path" "$COLOR_GREEN"

echo "Diagnostics complete. Results saved to $log_path"
