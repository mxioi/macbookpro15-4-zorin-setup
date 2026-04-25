#!/bin/bash
# Auto-enable USB ethernet based on Zorin UI connection state
# Only enables if "Wired connection 1" is set to enabled in NetworkManager

ETH_DEV="enxacde48001122"
CONN_NAME="Wired connection 1"

# Check if connection is enabled in NetworkManager
if nmcli -f NAME,AUTOCONNECT connection show | grep -q "$CONN_NAME.*yes"; then
    echo "Wired connection enabled - enabling auto-connect for $ETH_DEV"
    sudo nmcli device set $ETH_DEV autoconnect yes
else
    echo "Wired connection disabled - keeping auto-connect off"
    sudo nmcli device set $ETH_DEV autoconnect no
fi

# Create udev rule that respects UI state
sudo tee /etc/udev/rules.d/70-usb-ethernet-auto.rules > /dev/null << EOF
# Enable USB ethernet only if connection is enabled in Zorin/NM UI
# On add: check if connection is enabled, then enable this device
# On remove: disable device auto-connect
SUBSYSTEM=="net", ATTR{address}=="ac:de:48:00:11:22", ACTION=="add", RUN+="/usr/bin/sudo -n /usr/bin/nmcli -t -f NAME,AUTOCONNECT connection show | /usr/bin/grep -q 'Wired connection 1.*yes' && /usr/bin/nmcli device set $ETH_DEV autoconnect yes || /usr/bin/nmcli device set $ETH_DEV autoconnect no"
SUBSYSTEM=="net", ATTR{address}=="ac:de:48:00:11:22", ACTION=="remove", RUN+="/usr/bin/nmcli device set $ETH_DEV autoconnect no"
EOF
sudo chmod 644 /etc/udev/rules.d/70-usb-ethernet-auto.rules
sudo udevadm control --reload-rules

echo "Done! Ethernet auto-connect follows 'Wired connection 1' UI setting."