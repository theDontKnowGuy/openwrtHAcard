#!/bin/sh

CPU_LINE=$(top -bn1 | grep '[C]PU:')
CPU_IDLE=$(echo "$CPU_LINE" | sed 's/.*idle\s\+\([0-9]\+\)%.*$/\1/')
CPU_USAGE=$(( 100 - CPU_IDLE ))

RAW_UPTIME=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}' | sed 's/^ *//;s/ *$//')

# Convert uptime to seconds:
if echo "$RAW_UPTIME" | grep -q "min"; then

    minutes=$(echo "$RAW_UPTIME" | awk '{print $1}')
    UPTIME_SECONDS=$(( minutes * 60 ))
elif echo "$RAW_UPTIME" | grep -q "day"; then

    days=$(echo "$RAW_UPTIME" | awk '{print $1}')
    hm=$(echo "$RAW_UPTIME" | awk -F',' '{print $2}' | sed 's/^ *//')
    hours=$(echo "$hm" | cut -d: -f1)
    minutes=$(echo "$hm" | cut -d: -f2)
    UPTIME_SECONDS=$(( days * 86400 + hours * 3600 + minutes * 60 ))
elif echo "$RAW_UPTIME" | grep -q ":"; then

    hours=$(echo "$RAW_UPTIME" | cut -d: -f1)
    minutes=$(echo "$RAW_UPTIME" | cut -d: -f2)
    UPTIME_SECONDS=$(( hours * 3600 + minutes * 60 ))
else
    UPTIME_SECONDS=0
fi

WAN_IP=$(wget -qO- https://api.ipify.org | tr -d '\n')

# --- Memory Statistics ---
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_FREE=$(grep MemFree /proc/meminfo | awk '{print $2}')

# --- WiFi Networks and Clients ---
WIFI_NETWORKS_JSON="["

for iface in $(iwinfo 2>/dev/null | grep 'ESSID:' | awk '{print $1}'); do
    # Get the SSID for the interface
    ssid=$(iwinfo "$iface" info | grep 'ESSID' | awk -F: '{print $2}' | tr -d '"' | sed 's/^[[:space:]]*//')
    # Get MAC addresses of connected clients from iw dev station dump
    clients=$(iw dev "$iface" station dump | awk '/Station/ {print $2}')
    client_count=$(echo "$clients" | grep -c .)
    # Build a JSON array for the client MAC addresses
    clients_array="["
    for mac in $clients; do
         clients_array="${clients_array}\"$mac\","
    done
    # Remove the trailing comma (if any) and close the JSON array
    clients_array=$(echo "$clients_array" | sed 's/,$//')
    clients_array="${clients_array}]"

    WIFI_NETWORKS_JSON="${WIFI_NETWORKS_JSON}{\"interface\": \"$iface\", \"ssid\": \"$ssid\", \"client_count\": $client_count, \"clients\": $clients_array},"
done
# Remove the trailing comma and close the WiFi networks JSON array
WIFI_NETWORKS_JSON=$(echo "$WIFI_NETWORKS_JSON" | sed 's/,$//')
WIFI_NETWORKS_JSON="${WIFI_NETWORKS_JSON}]"

RX=$(awk '/br-lan:/{print $2}' /proc/net/dev | tr -d ' ')
TX=$(awk '/br-lan:/{print $10}' /proc/net/dev | tr -d ' ')

ERRORS=$(logread | grep -i 'error' | wc -l | tr -d ' ')

# --- Build JSON Payload ---
JSON=$(cat <<EOF
{
  "cpu": {
    "raw": "$CPU_LINE",
       "idle_percent": $CPU_IDLE,
    "usage_percent": $CPU_USAGE
  },
  "uptime_seconds": $UPTIME_SECONDS,
  "wan_ip": "$WAN_IP",
  "memory": {
    "total_kb": $MEM_TOTAL,
    "free_kb": $MEM_FREE
  },
  "wifi_networks": $WIFI_NETWORKS_JSON,
  "network_stats": {
    "br-lan": {
      "rx_bytes": $RX,
      "tx_bytes": $TX
    }
  },
  "system_errors": $ERRORS
}
EOF
)

ROUTER_NAME=$(uci get system.@system[0].hostname)
mosquitto_pub -h 192.168.22.252 -u mqttuser -P xxxxxxxx -t "openwrt/$ROUTER_NAME/status" -m "$JSON"

