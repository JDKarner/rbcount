#!/bin/bash
# Path to the monitor script
MONITOR_SCRIPT_PATH="/usr/local/bin/monitor.sh"
REBOOT_COUNT_FILE="/etc/rbcount/reboot_count.conf"

# Execute the monitor script
"$MONITOR_SCRIPT_PATH"

# Read the current reboot count after monitor.sh has potentially updated it
# A value of 0 in REBOOT_COUNT_FILE means stop reboots.
current_reboot_count=$(cat "$REBOOT_COUNT_FILE")

echo "Current reboot count after monitor check: $current_reboot_count"

# If the reboot count is 0, it means reboots should stop (due to low memory or other condition)
if [ "$current_reboot_count" -eq 0 ]; then
    echo "Reboots halted as per monitor script instructions. Check /var/log/rbcount_memory.log for details."
    exit 0
fi

# Check if we've reached a specific number of reboots (e.g., 100)
if [ "$current_reboot_count" -ge 100 ]; then # Changed to >= to ensure it stops after 100
    echo "Successfully rebooted 100 times! Halting further reboots."
    exit 0
else
    echo "System has rebooted $current_reboot_count times. Rebooting in 5 seconds..."
    sleep 5
    # Reboot the system again
    reboot
fi
