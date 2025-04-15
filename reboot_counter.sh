#!/bin/bash
#Needs to be named reboot_counter.sh, move into /usr/local/bin
#File edits may be needed to run this in other location.
# Path to the reboot count file
COUNT_FILE="/home/oem/Desktop/boot-count.log"

# Function to initialize the service if not already done
initialize_service() {
    # Check if the service file exists
    if [ ! -f "/etc/systemd/system/reboot_counter.service" ]; then
        # Create the systemd service file
        echo "[Unit]
Description=Reboot Counter Service
After=network.target

[Service]
ExecStart=$0
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target" > "/etc/systemd/system/reboot_counter.service"

        # Reload systemd daemon and enable the service
        systemctl daemon-reload
        systemctl enable reboot_counter.service
    fi
}

# Function to check and increment reboot count
check_reboots() {
    # Check if the count file exists, initialize if not
    if [ ! -f "$COUNT_FILE" ]; then
        echo "0" > "$COUNT_FILE"
    fi

    # Read current count from file and increment it
    current_count=$(cat "$COUNT_FILE")
    reboot_count=$((current_count + 1))

    # Display the current reboot count
    echo "System has rebooted $reboot_count times."

    # Wait for 10 seconds
    sleep 5

    # Update the count in the file
    echo "$reboot_count" > "$COUNT_FILE"

    return $reboot_count
}

# Main script execution
initialize_service

# Get the current reboot count after incrementing
check_reboots
reboot_count=$?

# Check if we've reached X reboots
if [ "$reboot_count" -eq 200 ]; then
    echo "Successfully rebooted X times!"
    
    # Disable and stop the service
    systemctl disable reboot_counter.service
    systemctl stop reboot_counter.service
    
    exit 0
else
    # Reboot the system again
    reboot
fi

# End of script
