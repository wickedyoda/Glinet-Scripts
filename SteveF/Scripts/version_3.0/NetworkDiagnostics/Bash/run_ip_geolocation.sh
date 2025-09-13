#!/bin/bash
source "$(dirname "$0")/custom_logging.sh"
source "$(dirname "$0")/config.sh"

run_ip_geolocation_test() {
    local logpath="$1"

    write_log_entry "--- IP Geolocation ---" "$logpath" "$COLOR_CYAN"

    local response
    response=$(curl -s --max-time 5 http://ip-api.com/json)

    if [ -z "$response" ]; then
        write_log_entry "Failed to retrieve IP geolocation: No response" "$logpath" "$COLOR_RED"
        return 1
    fi

    local status
    status=$(echo "$response" | jq -r '.status')
    if [ "$status" != "success" ]; then
        write_log_entry "Failed to retrieve IP geolocation: $(echo "$response" | jq -r '.message')" "$logpath" "$COLOR_RED"
        return 1
    fi

    local ip country region city isp org lat lon
    ip=$(echo "$response" | jq -r '.query')
    country=$(echo "$response" | jq -r '.country')
    region=$(echo "$response" | jq -r '.regionName')
    city=$(echo "$response" | jq -r '.city')
    isp=$(echo "$response" | jq -r '.isp')
    org=$(echo "$response" | jq -r '.org')
    lat=$(echo "$response" | jq -r '.lat')
    lon=$(echo "$response" | jq -r '.lon')

    write_log_entry "IP:      $ip" "$logpath" "$COLOR_GREEN"
    write_log_entry "Country: $country" "$logpath" "$COLOR_GREEN"
    write_log_entry "Region:  $region" "$logpath" "$COLOR_GREEN"
    write_log_entry "City:    $city" "$logpath" "$COLOR_GREEN"
    write_log_entry "ISP:     $isp" "$logpath" "$COLOR_YELLOW"
    write_log_entry "Org:     $org" "$logpath" "$COLOR_YELLOW"
    write_log_entry "Lat:     $lat" "$logpath" "$COLOR_GRAY"
    write_log_entry "Lon:     $lon" "$logpath"
}