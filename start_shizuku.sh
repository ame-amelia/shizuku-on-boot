#!/data/data/com.termux/files/usr/bin/bash


# Set to 1 to enable debugging mode.
DEBUG=0
LOGFILE=$(dirname $0)/log
MAX_RETRIES=30

debug() {
    (( DEBUG )) && tee -a $LOGFILE <<< "$*"
}

start_shizuku() {

    # Try to start Shizuku
    libshizuku=$(adb shell pm path moe.shizuku.privileged.api | sed 's/^package://;s/base\.apk/lib\/arm64\/libshizuku\.so/')
    shizuku_output=$(adb shell $libshizuku) 
    debug "$shizuku_output"

    # Check if the connection succeeded
    if [ "$shizuku_output" != "" ]; then

        # Tell the user about it
        termux-notification-remove 1 &
        termux-notification -i 1 -t "Shizuku started!" --icon "done" &
        debug "Shizuku has successfully started."

        # Disable wireless debugging, because it is not needed anymore
        adb shell settings put global adb_wifi_enabled 0
        debug "Disabled wireless debugging."
        debug "Exiting with 0!"
    
        exit 0
    elif ((retries<MAX_RETRIES)); then
        ((retries+=1)) 
        debug "Failed to start. Retrying... ($retries)"
        sleep 1
        start_shizuku
    fi 
}

main() {
    debug "$(date "+%Y-%m-%d %T")" 
    termux-notification-remove 1 &
    termux-notification -i 1 -t "Shizuku is starting..." --icon autorenew &

    # Kill the adb server if it's running so it doesn't confuse other open ports for actual adb clients
    adb kill-server

    # Make a list of open ports
    debug "Scanning for open ports..."
    nmap_output=$(nmap -sT -p30000-50000 --open localhost)
    ports=$(grep "open" <<< "$nmap_output" | cut -f1 -d/)
    debug "$nmap_output"
    debug "Found open port(s): $(tr "\n" " " <<< "$ports")"
    debug "I'm going to try to connect to each port."

    # Go through the list of ports
    for port in ${ports}; do
      
        # Try to connect to the port, and save the result
        debug "Trying port $port..." 
        adb_output=$(adb connect "localhost:${port}")
        debug "$adb_output"

        # Check if the connection succeeded
        if [[ "$adb_output" =~ "connected" || "$adb_output" =~ "already" ]];
        then start_shizuku
        else adb disconnect "localhost:${port}"
        fi
    done

    # Error out if no working ports are found
    debug "Either there were no ports, or the open ports I found were not correct."
    debug "Is wireless debugging on? Try turning it off and on again."
    debug "Exiting with 1."

    termux-notification-remove 1 &
    termux-notification \
        -i 1 \
        -t "Shizuku failed to start" \
        --icon warning \
        -c "Is wireless debugging enabled?" \
        --button1 "Retry" \
        --button1-action "bash -l -c  \"termux-notification-remove 1; $HOME/.termux/boot/$(basename $0)\"" &

    exit 1 
}

main "$@"
