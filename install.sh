#!/bin/bash

# Set up variables
MAIN_SCRIPT_NAME="reboot_counter.sh"
MAIN_SCRIPT_PATH="/usr/local/bin/$MAIN_SCRIPT_NAME"
MONITOR_SCRIPT_NAME="monitor.sh"
MONITOR_SCRIPT_PATH="/usr/local/bin/$MONITOR_SCRIPT_NAME"
REBOOT_COUNT_FILE="/etc/rbcount/reboot_count.conf" # Centralized reboot count file
MEMORY_THRESHOLD_FILE="/etc/rbcount/memory_threshold.conf" # Memory threshold configuration
DESKTOP_FILE="/home/oem/Desktop/rbcount_is_installed.desktop" # Keeping for potential future use of desktop icon function

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Function to create the main script
create_main_script() {
    echo "#!/bin/bash
# Path to the monitor script
MONITOR_SCRIPT_PATH=\"$MONITOR_SCRIPT_PATH\"
REBOOT_COUNT_FILE=\"$REBOOT_COUNT_FILE\"

# Execute the monitor script
\"\$MONITOR_SCRIPT_PATH\"

# Read the current reboot count after monitor.sh has potentially updated it
# A value of 0 in REBOOT_COUNT_FILE means stop reboots.
current_reboot_count=\$(cat \"\$REBOOT_COUNT_FILE\")

echo \"Current reboot count after monitor check: \$current_reboot_count\"

# If the reboot count is 0, it means reboots should stop (due to low memory or other condition)
if [ \"\$current_reboot_count\" -eq 0 ]; then
    echo \"Reboots halted as per monitor script instructions. Check /var/log/rbcount_memory.log for details.\"
    exit 0
fi

# Check if we've reached a specific number of reboots (e.g., 100)
if [ \"\$current_reboot_count\" -ge 100 ]; then # Changed to >= to ensure it stops after 100
    echo \"Successfully rebooted 100 times! Halting further reboots.\"
    exit 0
else
    echo \"System has rebooted \$current_reboot_count times. Rebooting in 5 seconds...\"
    sleep 5
    # Reboot the system again
    reboot
fi" > "$MAIN_SCRIPT_PATH"

    chmod +x "$MAIN_SCRIPT_PATH"
}

# Function to create systemd service file
create_service_file() {
    SERVICE_FILE="/etc/systemd/system/reboot_counter.service"
    echo "[Unit]
Description=Reboot Counter Service
After=network.target

[Service]
ExecStart=$MAIN_SCRIPT_PATH
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target" > "$SERVICE_FILE"

    chmod 644 "$SERVICE_FILE"
}

# Function to create desktop icon
#create_desktop_icon() {
#    echo "[Desktop Entry]
#Version=1.0
#Type=Application
#Name=Reboot Counter
#Exec=sudo $MAIN_SCRIPT_PATH
#Icon=system-run
#Terminal=false
#StartupWMClass=reboot_counter" > "$DESKTOP_FILE"
#
#    chmod +x "$DESKTOP_FILE"
#}

# Function to configure sudoers for password-less execution
configure_sudoers() {
    echo "$MAIN_SCRIPT_PATH ALL=(ALL) NOPASSWD: $MAIN_SCRIPT_PATH" | sudo EDITOR='tee -a' visudo
    echo "$MONITOR_SCRIPT_PATH ALL=(ALL) NOPASSWD: $MONITOR_SCRIPT_PATH" | sudo EDITOR='tee -a' visudo
}

# Main installation process
echo "Installing Reboot Counter System..."

# Create necessary directories if they don't exist
mkdir -p /usr/local/bin

# Install the main script
create_main_script
echo "Main script installed at: $MAIN_SCRIPT_PATH"

# Create the systemd service file and enable it
create_service_file
systemctl daemon-reload
systemctl enable reboot_counter.service
systemctl start reboot_counter.service
echo "Systemd service created and enabled."

# Create necessary directories for monitor.sh and config files
mkdir -p "$(dirname "$REBOOT_COUNT_FILE")" # This creates /etc/rbcount
mkdir -p "$(dirname "$MONITOR_SCRIPT_PATH")" # This ensures /usr/local/bin exists (redundant with line 68, but harmless)

# Copy and make monitor.sh executable
cp "C:\\Users\\joshu\\work\\rbcount\\monitor.sh" "$MONITOR_SCRIPT_PATH"
chmod +x "$MONITOR_SCRIPT_PATH"
echo "Monitor script installed at: $MONITOR_SCRIPT_PATH"

# Initialize the reboot count file if it doesn't exist
if [ ! -f "$REBOOT_COUNT_FILE" ]; then
    echo "1" > "$REBOOT_COUNT_FILE" # Start count at 1 for the first boot after install
    chown root:root "$REBOOT_COUNT_FILE"
    chmod 644 "$REBOOT_COUNT_FILE"
    echo "Reboot count file created and initialized at: $REBOOT_COUNT_FILE"
fi

# Initialize the memory threshold file if it doesn't exist
if [ ! -f "$MEMORY_THRESHOLD_FILE" ]; then
    echo "1024" > "$MEMORY_THRESHOLD_FILE" # Default to 1GB (1024 MB)
    chown root:root "$MEMORY_THRESHOLD_FILE"
    chmod 644 "$MEMORY_THRESHOLD_FILE"
    echo "Memory threshold file created and initialized to 1024MB at: $MEMORY_THRESHOLD_FILE"
fi

# The original COUNT_FILE logic is now handled by REBOOT_COUNT_FILE and monitor.sh,
# so the lines related to "$COUNT_FILE" are removed.

# Create desktop icon (if this function is enabled and desired)
# create_desktop_icon # Keeping this commented out as it was in the original script
# echo "Desktop icon created at: $DESKTOP_FILE"

# Configure sudoers for password-less execution of the scripts
configure_sudoers
echo "Sudoers configured to allow password-less execution for main and monitor scripts."

echo "Installation completed successfully."
