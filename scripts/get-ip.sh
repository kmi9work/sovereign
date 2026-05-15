#!/bin/bash
# Helper script to detect a LAN-reachable IP address for device development.
# Sources: sets DEV_IP variable

# Primary: get the source IP used for the default route.
# This reliably returns the WiFi/ethernet LAN address, ignoring VPN tunnels.
DEV_IP=$(ip -4 route get 1 | awk '{for (i=1; i<NF; i++) if ($i == "src") print $(i+1); exit}')

# Fallback: list non-loopback IPs, excluding Docker default bridge (172.17.x.x)
if [ -z "$DEV_IP" ]; then
    DEV_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | grep -v '^172\.17\.' | head -1)
fi

# Fallback: try hostname
if [ -z "$DEV_IP" ]; then
    DEV_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
