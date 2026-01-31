# This script starts Shizuku. It is to be used with Termux:Boot to start Shizuku on boot.
# 
# Requires packages: nmap openssl android-tools
# 
# Also install package termux-api and Termux:API from F-Droid to provide status notifications.
#
# How to pair ADB server with device:
# 1. Turn on Wireless debugging in settings
# 2. Press "Pair device with pairing code"
# 3. Open Termux in floating window/split-screen and enter the following command: adb pair localhost:[PORT] [CODE]
#
# I did not write this script, it was modified from a longer script by OP-san: https://github.com/RikkaApps/Shizuku/discussions/462



#!/data/data/com.termux/files/usr/bin/bash

# Make a list of open ports
echo Scanning ports...
termux-notification-remove 1
termux-notification -i 1 -t "Shizuku is starting..." --icon autorenew

ports=$( nmap -sT -p30000-50000 --open localhost | grep "open" | cut -f1 -d/ )

# Go through the list of ports
for port in ${ports}; do
  
    # Try to connect to the port, and save the result
    result=$( adb connect "localhost:${port}" )

    # Remove starting status notification
    termux-notification-remove 1

    # Try to start Shizuku even if connection wasn't established because Bash is fucky when run as a Termux task
    adb shell "$( adb shell pm path moe.shizuku.privileged.api | sed 's/^package://;s/base\.apk/lib\/arm64\/libshizuku\.so/' )"

    # Check if the connection succeeded
    if [ $? = "0" ]; then

        # Tell the user about it
        echo "${result}"
        termux-notification -i 1 -t "Shizuku started!" --icon "done"
    
        # Disable wireless debugging, because it is not needed anymore
        adb shell settings put global adb_wifi_enabled 0
    
        exit 0
    fi 
done

# Error out if no working ports are found
echo "I did not find any open ports. Maybe wireless debugging is disabled?"
termux-notification \
    -i 1 \
    -t "Shizuku failed to start" \
    --icon warning \
    -c "Is wireless debugging enabled?" \
    --button1 "Retry" \
    --button1-action "bash -l -c \"termux-notification-remove 1; $HOME/.termux/boot/$(basename $0)\" "

exit 1
