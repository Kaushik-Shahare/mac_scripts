#!/bin/bash

INTERFACE="en0"  # Change if needed
SCAN_FILE="$HOME/.arp_scan_baseline.txt"

# Function to run scan
run_scan() {
    sudo arp-scan -I "$INTERFACE" --localnet | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | sort
}

# First time setup
if [ ! -f "$SCAN_FILE" ]; then
    echo "[*] Creating baseline scan..."
    run_scan > "$SCAN_FILE"
    terminal-notifier -title "ARP Watchdog" -message "Baseline ARP scan saved."
    exit 0
fi

# Current scan
CURRENT=$(mktemp)
run_scan > "$CURRENT"

# Compare with baseline
if ! diff "$SCAN_FILE" "$CURRENT" >/dev/null; then
    terminal-notifier -title "ARP Watchdog" -message "ARP table change detected!"
    echo "[!] Change detected at $(date)" >> "$HOME/arp_watchdog.log"
    diff "$SCAN_FILE" "$CURRENT" >> "$HOME/arp_watchdog.log"
    cp "$CURRENT" "$SCAN_FILE"
fi

rm "$CURRENT"
