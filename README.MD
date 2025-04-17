# OpenWRT HA Card

[![OpenWRT](https://img.shields.io/badge/OpenWRT-00B5E2?style=flat&logo=openwrt&logoColor=white)](https://openwrt.org)
[![Home Assistant](https://img.shields.io/badge/Home%20Assistant-41BDF5?style=flat&logo=homeassistant&logoColor=white)](https://www.home-assistant.io)
[![MQTT](https://img.shields.io/badge/MQTT-660066?style=flat&logo=mqtt&logoColor=white)](https://mqtt.org)

A Home Assistant integration for monitoring OpenWRT routers and access points. Provides real-time statistics, WiFi client tracking, and system health monitoring.

## Features

- Real-time CPU and memory usage monitoring
- WiFi network and client tracking
- System uptime and error logging
- Network traffic statistics
- Automatic discovery of access points
- Beautiful Home Assistant dashboard card

## Prerequisites

- OpenWRT router(s) with:
  - MQTT client (`mosquitto-client`)
  - `iwinfo` package
  - `wget` or `curl`
- MQTT broker (e.g., Mosquitto)
- Home Assistant `HTML Jinja2 Template card` addon

## Setup Instructions

### Main Router (DHCP Server)

1. Install required packages:
   ```bash
   opkg update
   opkg install mosquitto-client iwinfo wget
   ```

2. Edit the MQTT credentials in both scripts:
   ```bash
   # Update these values in both scripts
   MQTT_BROKER="192.168.1.100"  # Your MQTT broker IP
   MQTT_USER="your_username"
   MQTT_PASS="your_password"
   ```

3. Copy scripts to the router:
   ```bash
   scp HA-MainRouterReport.sh HA-AccessPointReport.sh root@router:/root/
   ```

4. Make scripts executable:
   ```bash
   chmod +x /root/*.sh
   ```

5. Configure cron jobs in the router's Luci interface to run every minute:
   ```
   * * * * * /root/HA-MainRouterReport.sh
   * * * * * /root/HA-AccessPointReport.sh
   ```

### Access Points

1. Install required packages (same as main router)
2. Copy only `HA-AccessPointReport.sh` to the access point
3. Update MQTT credentials in the script
4. Make it executable and set up the cron job

### Home Assistant Configuration

1. Install required components:
   - Using HACS, install the `HTML Jinja2 Template card` addon
   - Reload the UI after installation

2. Configure MQTT and templates:
   - Copy the MQTT and template components from `HA/configuration.yaml` to your Home Assistant's `configuration.yaml`
   - Edit the MQTT topic names to match your router names (e.g., `openwrt/your_router_name/status`)

3. Add the reference to the `sensor.yaml` file

```yaml
- platform: template
  sensors: !include templates/wifi_clients_combined.yaml
```

4. Set up templates:
   - Copy files from `HA/Templates` to your Home Assistant's templates directory (usually `config/templates`)
   - Edit both files for list of routers and networks to monitor #todo - do this dynamically 

5. Add the card to your dashboard:

   Copy the content of the `HA Card/wifi-routes-card.yaml` to an empty dashbaord card. Set its width to 100%.

6. Restart Home Assistant (a Quick Restart should do).

