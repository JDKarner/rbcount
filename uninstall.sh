#!/bin/bash

# Set up variables for paths
MAIN_SCRIPT_PATH="/usr/local/bin/reboot_counter.sh"
MONITOR_SCRIPT_PATH="/usr/local/bin/monitor.sh"
SERVICE_FILE="/etc/systemd/system/reboot_counter.service"
RBCOUNT_CONFIG_DIR="/etc/rbcount"
RBCOUNT_LOG_DIR="/var/log/rbcount"
# The old COUNT_FILE is no longer used by the main system, but might have been created by previous versions.
# For a clean uninstall, we'll focus cleanup on the new config files and directories.
# DESKTOP_FILE="/home/oem/Desktop/reboot_counter.desktop" # This desktop file may no longer be relevant

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

# Remove the monitor script
if [ -f "$MONITOR_SCRIPT_PATH" ]; then
    rm -f "$MONITOR_SCRIPT_PATH"
    echo "Removed: $MONITOR_SCRIPT_PATH"
else
    echo "File not found: $MONITOR_SCRIPT_PATH"
fi

# Delete configuration directory and its contents
if [ -d "$RBCOUNT_CONFIG_DIR" ]; then
    rm -rf "$RBCOUNT_CONFIG_DIR"
    echo "Removed configuration directory: $RBCOUNT_CONFIG_DIR"
else
    echo "Configuration directory not found: $RBCOUNT_CONFIG_DIR"
fi

# Delete log directory and its contents
if [ -d "$RBCOUNT_LOG_DIR" ]; then
    rm -rf "$RBCOUNT_LOG_DIR"
    echo "Removed log directory: $RBCOUNT_LOG_DIR"
else
    echo "Log directory not found: $RBCOUNT_LOG_DIR"
fi

# Remove desktop icon
#if [ -f "$DESKTOP_FILE" ]; then
#    rm -f $DESKTOP_FILE
#    echo "Removed: $DESKTOP_FILE"
#else
#    echo "File not found: $DESKTOP_FILE"
#fi

# Remove sudoers entries for the scripts
echo "Removing sudoers entries..."
sudo sed -i '\%^/usr/local/bin/reboot_counter.sh ALL=(ALL) NOPASSWD: /usr/local/bin/reboot_counter.sh$%d' /etc/sudoers
sudo sed -i '\%^/usr/local/bin/monitor.sh ALL=(ALL) NOPASSWD: /usr/local/bin/monitor.sh$%d' /etc/sudoers
echo "Sudoers entries removed."

# Reload systemd daemon to apply changes
systemctl daemon-reload

echo "Uninstallation completed successfully."
