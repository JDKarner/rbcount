#!/bin/bash

# Set up variables for paths
MAIN_SCRIPT_PATH="/usr/local/bin/reboot_counter.sh"
SERVICE_FILE="/etc/systemd/system/reboot_counter.service"
COUNT_FILE="/home/oem/Desktop/boot-count.log"
DESKTOP_FILE="/home/oem/Desktop/reboot_counter.desktop"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

echo "Uninstalling Reboot Counter System..."

# Stop and disable the systemd service
systemctl stop reboot_counter.service
systemctl disable reboot_counter.service
rm -f $SERVICE_FILE

# Remove the main script
if [ -f "$MAIN_SCRIPT_PATH" ]; then
    rm -f $MAIN_SCRIPT_PATH
    echo "Removed: $MAIN_SCRIPT_PATH"
else
    echo "File not found: $MAIN_SCRIPT_PATH"
fi

# Delete log file
if [ -f "$COUNT_FILE" ]; then
    rm -f $COUNT_FILE
    echo "Removed: $COUNT_FILE"
else
    echo "File not found: $COUNT_FILE"
fi

# Remove desktop icon
#if [ -f "$DESKTOP_FILE" ]; then
#    rm -f $DESKTOP_FILE
#    echo "Removed: $DESKTOP_FILE"
#else
#    echo "File not found: $DESKTOP_FILE"
#fi

# Reload systemd daemon to apply changes
systemctl daemon-reload

echo "Uninstallation completed successfully."
