#!/bin/bash

run_speedtest() {
    local log_path="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local output_file="/tmp/speedtest_output.json"
    local error_file="/tmp/speedtest_error.log"

    write_log_entry "--- Speed Test ---" "$log_path" "$COLOR_CYAN"

    # Determine which CLI is available
    if [[ -x "$SPEEDTEST_PATH/speedtest.exe" ]]; then
        write_log_entry "Using speedtest.exe (Windows CLI)" "$log_path" "$COLOR_GRAY"
        "$SPEEDTEST_PATH/speedtest.exe" --format=json > "$output_file" 2>"$error_file"
    elif command -v speedtest &>/dev/null; then
        write_log_entry "Using speedtest-cli (Python version)" "$log_path" "$COLOR_GRAY"
        speedtest --json > "$output_file" 2>"$error_file"
    else
        write_log_entry "No speedtest CLI found. Skipping speed test." "$log_path" "$COLOR_RED"
        write_log_entry "You can install the Linux-native version with: sudo apt install speedtest-cli" "$log_path" "$COLOR_GRAY"
        return 1
    fi

    # Validate output
    if [[ ! -s "$output_file" ]]; then
        write_log_entry "Speedtest failed or returned no data." "$log_path" "$COLOR_RED"
        write_log_entry "Speedtest error details: $(cat "$error_file")" "$log_path" "$COLOR_GRAY"
        return 1
    fi

    # Auto-detect format and parse accordingly
    local download_mbps upload_mbps ping_latency server_name server_id isp_name

    if jq -e '.download.bandwidth' "$output_file" &>/dev/null; then
        # Ookla CLI format
        download_mbps=$(jq '.download.bandwidth / 125000 | round' "$output_file")
        upload_mbps=$(jq '.upload.bandwidth / 125000 | round' "$output_file")
        ping_latency=$(jq '.ping.latency | round' "$output_file")
        server_name="$(jq -r '.server.name + " (" + .server.location + ")"' "$output_file")"
        server_id=$(jq -r '.server.id' "$output_file")
        isp_name=$(jq -r '.isp' "$output_file")
    elif jq -e '.download' "$output_file" &>/dev/null; then
        # Python CLI format
        download_mbps=$(jq '.download / 1000000 | round' "$output_file")
        upload_mbps=$(jq '.upload / 1000000 | round' "$output_file")
        ping_latency=$(jq '.ping | round' "$output_file")
        server_name="$(jq -r '.server.name + ", " + .server.country' "$output_file")"
        server_id=$(jq -r '.server.id' "$output_file")
        isp_name=$(jq -r '.client.isp' "$output_file")
    else
        write_log_entry "Unrecognized speedtest output format." "$log_path" "$COLOR_RED"
        write_log_entry "Raw output: $(cat "$output_file")" "$log_path" "$COLOR_GRAY"
        return 1
    fi

    # Log results
    write_log_entry "Download Speed: ${download_mbps:-N/A} Mbps" "$log_path" "$COLOR_GREEN"
    write_log_entry "Upload Speed:   ${upload_mbps:-N/A} Mbps" "$log_path" "$COLOR_GREEN"
    write_log_entry "Ping Latency:   ${ping_latency:-N/A} ms" "$log_path" "$COLOR_GREEN"
    write_log_entry "Server:         ${server_name:-Unknown} [ID: ${server_id:-N/A}]" "$log_path" "$COLOR_GRAY"
    write_log_entry "ISP:            ${isp_name:-Unknown}" "$log_path" "$COLOR_GRAY"

    return 0
}
