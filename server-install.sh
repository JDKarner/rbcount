#!/bin/bash

# Set up variables
MAIN_SCRIPT_NAME="reboot_counter.sh"
MAIN_SCRIPT_PATH="/usr/local/bin/$MAIN_SCRIPT_NAME"
COUNT_FILE="/var/log/boot-count.log"
NVME_LOG_CMD="lspci | grep -i -c samsung"
DESKTOP_FILE="/home/oem/Desktop/rbcount_is_installed.desktop"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Function to create the main script
create_main_script() {
    echo "#!/bin/bash
# Path to the reboot count file
COUNT_FILE=\"$COUNT_FILE\"
NVME_LOG_CMD=\"$NVME_LOG_CMD\"

# Function to check and increment reboot count
check_reboots() {
    # Check if the count file exists, initialize if not
    if [ ! -f \"$COUNT_FILE\" ]; then
        echo \"0\" > \"$COUNT_FILE\"
    fi
    # Read current count from file and increment it
    current_count=\$(head -n 1 \"$COUNT_FILE\" 2>/dev/null | grep -Eo '^[0-9]+' || echo 0)
    reboot_count=\$((current_count + 1))
    # Display the current reboot count
    echo \"System has rebooted \$reboot_count times.\"
    # Wait for 5 seconds
    sleep 5
    # Update the count in the file (overwrite first line)
    tmpfile=\$(mktemp)
    echo \"\$reboot_count\" > \"$tmpfile\"
    # Count Samsung NVMe drives and append to log
    nvme_count=\$(eval \"$NVME_LOG_CMD\")
    echo \"$(date): Samsung NVMe drives: \$nvme_count\" >> \"$tmpfile\"
    # Append any previous log entries except the old first line
    tail -n +2 \"$COUNT_FILE\" 2>/dev/null >> \"$tmpfile\"
    mv \"$tmpfile\" \"$COUNT_FILE\"
    return \$reboot_count
}

# Main script execution
# Get the current reboot count after incrementing
check_reboots
reboot_count=\$?
# Check if we've reached 100 reboots
if [ \"\$reboot_count\" -eq 100 ]; then
    echo \"Successfully rebooted 100 times!\"
else
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
if [ ! -f "$COUNT_FILE" ]; then
    echo "0" > "$COUNT_FILE"
fi
chown root:root "$COUNT_FILE"
chmod 644 "$COUNT_FILE"


# Desktop icon creation skipped for Ubuntu Server (no GUI)
echo "Desktop icon creation skipped (Ubuntu Server)."

# Configure sudoers for password-less execution of the script
configure_sudoers
echo "Sudoers configured to allow password-less execution."

echo "Installation completed successfully."
