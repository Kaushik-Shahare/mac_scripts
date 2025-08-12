#!/bin/bash

INTERFACE="en0"  # Change to your network interface
SCAN_FILE=$(mktemp)
PREVIOUS_FILE=$(mktemp)

echo "[*] Starting ARP Guard on $INTERFACE"
echo "[*] Press Ctrl+C to stop."

# First baseline scan
sudo arp-scan -I "$INTERFACE" --localnet \
    | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" \
    | sort > "$PREVIOUS_FILE"

while true; do
    sudo arp-scan -I "$INTERFACE" --localnet \
        | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" \
        | sort > "$SCAN_FILE"

    if ! diff "$PREVIOUS_FILE" "$SCAN_FILE" >/dev/null; then
        # Desktop notification with timestamp
        terminal-notifier -title "ARP Guard Alert $(date +%H:%M:%S)" \
            -message "Possible ARP spoof or new device detected!"

        echo -e "\n[!] Change detected at $(date)"
        echo "---- Previous ARP Table ----"
        cat "$PREVIOUS_FILE"
        echo "---- Current ARP Table ----"
        cat "$SCAN_FILE"
        echo "---- Differences ----"
        diff "$PREVIOUS_FILE" "$SCAN_FILE"

        # Update baseline
        cp "$SCAN_FILE" "$PREVIOUS_FILE"
    fi

    sleep 10  # Scan every 10 seconds
done
