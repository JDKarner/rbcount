#!/bin/bash

# Set up variables
MAIN_SCRIPT_NAME="reboot_counter.sh"
MAIN_SCRIPT_PATH="/usr/local/bin/$MAIN_SCRIPT_NAME"
COUNT_FILE="/home/oem/Desktop/boot-count.log"
DESKTOP_FILE="/home/oem/Desktop/rbcount_is_installed.desktop"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Function to create the main script
create_main_script() {
    cat << 'EOF' > "$MAIN_SCRIPT_PATH"
#!/bin/bash
# Path to the reboot count file
COUNT_FILE="/home/oem/Desktop/boot-count.log"
MEMORY_LOG_FILE="/home/oem/Desktop/memory-log.log"
LAST_MEMORY_FILE="/home/oem/Desktop/last-memory.log"

# Function to check and increment reboot count
check_reboots() {
    # Check if the count file exists, initialize if not
    if [ ! -f "$COUNT_FILE" ]; then
        echo "0" > "$COUNT_FILE"
    fi
    # Read current count from file and increment it
    current_count=$(cat "$COUNT_FILE" 2>/dev/null | grep -Eo '^[0-9]+' || echo 0)
    reboot_count=$((current_count + 1))
    # Display the current reboot count
    echo "System has rebooted $reboot_count times."
    # Wait for 5 seconds
    sleep 5
    # Update the count in the file
    echo "$reboot_count" > "$COUNT_FILE"
    return $reboot_count
}

# Function to check and log memory
check_memory() {
    echo "Checking system memory..."
    current_memory_kb=$(free -k | awk '/Mem:/ {print $2}')
    current_memory_gb=$(echo "scale=2; $current_memory_kb / (1024*1024)" | bc -l)

    # Log current memory
    echo "Boot $reboot_count: $(date): Total Memory: $current_memory_gb GB" >> "$MEMORY_LOG_FILE"

    # Read last known memory
    if [ -f "$LAST_MEMORY_FILE" ]; then
        last_memory_kb=$(cat "$LAST_MEMORY_FILE" 2>/dev/null | grep -Eo '^[0-9]+' || echo 0)
        # Only check if last_memory_kb is greater than 0 to avoid false positives on first boot
        if [ "$last_memory_kb" -gt 0 ]; then
            if (( $(echo "$current_memory_kb < $last_memory_kb" | bc -l) )); then
                last_memory_gb=$(echo "scale=2; $last_memory_kb / (1024*1024)" | bc -l)
                echo "Memory discrepancy detected!"
                echo "Previous total memory: $last_memory_gb GB"
                echo "Current total memory: $current_memory_gb GB"
                read -p "WARNING: Total memory decreased. Press Enter to continue rebooting, or Ctrl+C to abort."
            fi
        fi
    fi

    # Update last memory file with current memory (always update after check)
    echo "$current_memory_kb" > "$LAST_MEMORY_FILE"
}

# Main script execution
# Get the current reboot count after incrementing
check_reboots
reboot_count=$?

# Perform memory check
check_memory

# Check if we've reached X reboots
if [ "$reboot_count" -eq 100 ]; then
    echo "Successfully rebooted X times!"
else
    # Reboot the system again
    reboot
fi
EOF

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
    echo "$MAIN_SCRIPT_PATH ALL=(ALL) NOPASSWD: $MAIN_SCRIPT_PATH" >> /etc/sudoers
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

# Create the log file if it doesn't exist
touch "$COUNT_FILE"
chown root:root "$COUNT_FILE"
chmod 644 "$COUNT_FILE"

# Initialize memory log files
MEMORY_LOG_FILE="/home/oem/Desktop/memory-log.log"
LAST_MEMORY_FILE="/home/oem/Desktop/last-memory.log"
if [ ! -f "$MEMORY_LOG_FILE" ]; then
    touch "$MEMORY_LOG_FILE"
fi
if [ ! -f "$LAST_MEMORY_FILE" ]; then
    echo "0" > "$LAST_MEMORY_FILE" # Initialize with 0KB on first run
fi
chown root:root "$MEMORY_LOG_FILE"
chmod 644 "$MEMORY_LOG_FILE"
chown root:root "$LAST_MEMORY_FILE"
chmod 644 "$LAST_MEMORY_FILE"

# Create desktop icon
create_desktop_icon
echo "Desktop icon created at: $DESKTOP_FILE"

# Configure sudoers for password-less execution of the script
configure_sudoers
echo "Sudoers configured to allow password-less execution."

echo "Installation completed successfully."
