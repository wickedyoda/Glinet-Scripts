#!/bin/sh

# Usage:
# ./bufferbloat-test.sh <target> <start_size> <log_file> <min_size> <step_size>
#
# Example:
# ./bufferbloat-test.sh 1.1.1.1 1472 /root/bufferbloat.log 500 10

TARGET="$1"
START_SIZE="$2"
LOGFILE="$3"
MIN_SIZE="$4"
STEP_SIZE="$5"

log() {
    echo "$1" | tee -a "$LOGFILE"
}

log "-------------------------------------------" 
log "            Bufferbloat Test                "
log "-------------------------------------------"

packet_size=$START_SIZE

while [ "$packet_size" -ge "$MIN_SIZE" ]; do
    log "Testing packet size: $packet_size bytes"

    # OpenWrt ping flags:
    # -s = packet size
    # -M do = Don't fragment
    # -c = count
    result="$(ping -c 4 -s "$packet_size" -M do "$TARGET" 2>&1)"
    echo "$result" >> "$LOGFILE"

    echo "$result" | grep -q "Frag needed"
    FRAG=$?

    if [ "$FRAG" -eq 0 ]; then
        log "Fragmentation detected at $packet_size bytes. Reducing..."
        packet_size=$((packet_size - STEP_SIZE))
    else
        log "No fragmentation at $packet_size bytes. Bufferbloat unlikely."
        log "Using MTU: $packet_size bytes"
        break
    fi
done

if [ "$packet_size" -lt "$MIN_SIZE" ]; then
    log "Unable to find non-fragmented size above $MIN_SIZE bytes."
fi

log "Bufferbloat test completed."