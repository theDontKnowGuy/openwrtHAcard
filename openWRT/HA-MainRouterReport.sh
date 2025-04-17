#!/bin/sh


LEASES_FILE="/tmp/dhcp.leases"
if [ -f "$LEASES_FILE" ]; then
    DHCP_LEASES_JSON="["
    while read expiry mac ip hostname clientid; do
        # If hostname is missing, it will be an empty string.
        DHCP_LEASES_JSON="${DHCP_LEASES_JSON}{\"mac\": \"$mac\", \"ip\": \"$ip\", \"hostname\": \"$hostname\"},"
    done < "$LEASES_FILE"
    DHCP_LEASES_JSON=$(echo "$DHCP_LEASES_JSON" | sed 's/,$//')
    DHCP_LEASES_JSON="${DHCP_LEASES_JSON}]"
else
    DHCP_LEASES_JSON="[]"
fi

# --- Build JSON Payload ---
JSON=$(cat <<EOF
{
  "dhcp_leases": $DHCP_LEASES_JSON
}
EOF
)
echo "$JSON"
# --- Publish the JSON payload via MQTT ---
mosquitto_pub -h 192.168.22.252 -u mqttuser -P xxxxxxxx -t "openwrt/Groute1/status" -m "$JSON"



