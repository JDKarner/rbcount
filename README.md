Find this line in the installer
```
# Check if we've reached X reboots
if [ "$reboot_count" -eq 100 ]; then
    echo "Successfully rebooted x times!"
```
Change the number after -eq to adjust number of reboots.
Default is 100.

Run the installer with sudo, this also starts the service for the reboots, don't install until ready.
