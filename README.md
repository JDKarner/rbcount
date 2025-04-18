install into `usr/local/bin/` and run from that location
variables can be edited for where you want the count log as well as how many reboots.
```
# Check if we've reached X reboots
if [ "$reboot_count" -eq 200 ]; then
    echo "Successfully rebooted X times!"
```
Change the number after -eq to adjust number of reboots.


`cp -r reboot_counter.sh /usr/local/bin`
`./usr/local/bin/reboot_counter.sh`

