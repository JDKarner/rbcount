#!/bin/bash

LOG_FILE="/var/log/rbcount_memory.log"
MEMORY_THRESHOLD_FILE="/etc/rbcount/memory_threshold.conf"
REBOOT_COUNT_FILE="/etc/rbcount/reboot_count.conf"

# Ensure the log directory and configuration directory exist
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$MEMORY_THRESHOLD_FILE")"

# Function to get total memory in MB
get_total_memory_mb() {
    # On Linux, use free -m to get memory in MB
    # Example output:
    #               total        used        free      shared  buff/cache   available
    # Mem:           7900        1200        5000         200        1700        6500
    free -m | awk '/^Mem:/{print $2}'
}

# Read the memory threshold
if [ -f "$MEMORY_THRESHOLD_FILE" ]; then
    MEMORY_THRESHOLD=$(cat "$MEMORY_THRESHOLD_FILE")
else
    # Default threshold if not set, for example 1024 MB (1GB)
    MEMORY_THRESHOLD=1024
    echo "$MEMORY_THRESHOLD" > "$MEMORY_THRESHOLD_FILE"
    echo "Default memory threshold set to $MEMORY_THRESHOLD MB. You can change it in $MEMORY_THRESHOLD_FILE" | tee -a "$LOG_FILE"
fi

TOTAL_MEMORY=$(get_total_memory_mb)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "$TIMESTAMP - Total Memory: ${TOTAL_MEMORY} MB, Threshold: ${MEMORY_THRESHOLD} MB" | tee -a "$LOG_FILE"

# Check if memory is lower than the set value
if (( TOTAL_MEMORY < MEMORY_THRESHOLD )); then
    echo "$TIMESTAMP - WARNING: Total memory (${TOTAL_MEMORY} MB) is below the configured threshold (${MEMORY_THRESHOLD} MB). Stopping reboots." | tee -a "$LOG_FILE"

    # Logic to stop reboots:
    # This part depends on how 'rbcount' initiates reboots.
    # Assuming 'rbcount' uses a reboot counter, we'll reset it or mark it to stop.
    # For now, I'll assume setting a flag or simply not incrementing a counter is enough.
    # If a specific 'reboot' command is used, it needs to be prevented.

    # Example: If a reboot count file exists and is managed by rbcount,
    # we might set its value to 0 or a specific marker to indicate "stop".
    if [ -f "$REBOOT_COUNT_FILE" ]; then
        echo "0" > "$REBOOT_COUNT_FILE" # Assuming '0' means no more reboots
        echo "$TIMESTAMP - Reboot count set to 0 to prevent further reboots." | tee -a "$LOG_FILE"
    else
        echo "$TIMESTAMP - No reboot count file found ($REBOOT_COUNT_FILE). Manual intervention might be required to stop reboots if they are externally managed." | tee -a "$LOG_FILE"
    fi

    # Exit script to prevent any further reboot logic from this script
    exit 0
else
    echo "$TIMESTAMP - Memory is above threshold. Continuing with normal operation." | tee -a "$LOG_FILE"
    # Logic to continue reboots:
    # This typically involves incrementing a reboot counter or allowing the next reboot.
    if [ -f "$REBOOT_COUNT_FILE" ]; then
        CURRENT_COUNT=$(cat "$REBOOT_COUNT_FILE")
        NEW_COUNT=$((CURRENT_COUNT + 1))
        echo "$NEW_COUNT" > "$REBOOT_COUNT_FILE"
        echo "$TIMESTAMP - Reboot count incremented to $NEW_COUNT." | tee -a "$LOG_FILE"
    else
        echo "$TIMESTAMP - Reboot count file not found ($REBOOT_COUNT_FILE). Creating and initializing to 1." | tee -a "$LOG_FILE"
        echo "1" > "$REBOOT_COUNT_FILE"
    fi
fi

# Additional logic for initiating reboot if necessary would go here,
# after the memory check, and only if memory is sufficient.
# For example, if this script itself is responsible for triggering the next reboot:
# if [ condition_for_next_reboot_met ]; then
#     sudo reboot
# fi
