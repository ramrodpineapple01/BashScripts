#!/bin/bash
# SETTINGS
TEST="8.8.8.8"       # TEST PING
ADAPTER1="enp4s0"    # EXTERNAL ETHERNET ADAPTER

# Report
LOGFILE=~/Documents/ReportInternet.log

# Messages
MESSAGE1="Restoring Connectivity..."
MESSAGE2="Wait a moment please..."
MESSAGE3="No Internet connectivity."
MESSAGE4="Yes, there is Internet connectivity."
#################################################################################

# Time and Date
TODAY=$(date "+%r %d-%m-%Y")

# Show IP Public Address
IPv4ExternalAddr1=$(ip addr list $ADAPTER1 |grep "inet " |cut -d' ' -f6|cut -d/ -f1)
IPv6ExternalAddr1=$(ip addr list $ADAPTER1 |grep "inet6 " |cut -d' ' -f6|cut -d/ -f1)

# Alarm
alarm() {
    beep -f 1500 -l 200;beep -f 1550 -l 200;beep -f 1500 -l 200;beep -f 1550 -l 200;beep -f 1500 -l 200;beep -f 1550 -l 200;beep -f 1500 -l 200;beep -f 1550$
}

# Restoring Connectivity
resolve() {
    clear
    echo "$MESSAGE1"
    sudo ifconfig $ADAPTER1 up;sudo dhclient -r $ADAPTER1;sleep 5;sudo dhclient $ADAPTER1
    echo "$MESSAGE2"
    sleep 120
}

# Execution of work
while true; do
    if [[ "$(fping -I $ADAPTER1 $TEST | grep 'unreachable' )" != "" ]]; then
        alarm
        clear
        echo "================================================================================" >> ${LOGFILE}
        echo "$MESSAGE3 - $TODAY"                                                               >> ${LOGFILE}
        echo "$MESSAGE3 - $TODAY"
        echo "================================================================================" >> ${LOGFILE}
        sleep 10
        resolve
    else
        clear
        echo "================================================================================"   >> ${LOGFILE}
        echo "$MESSAGE4 - $TODAY - IPv4 Addr: $IPv4ExternalAddr1 - IPv6 Addr: $IPv6ExternalAddr1" >> ${LOGFILE}
        echo "$MESSAGE4 - $TODAY - IPv4 Addr: $IPv4ExternalAddr1 - IPv6 Addr: $IPv6ExternalAddr1"
        echo "================================================================================"   >> ${LOGFILE}
        sleep 120
    fi
done