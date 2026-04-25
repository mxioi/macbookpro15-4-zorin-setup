#!/bin/bash
# Enable USB ethernet auto-connect based on physical presence

sudo tee /etc/udev/rules.d/70-usb-ethernet-auto.rules > /dev/null << 'EOF'
# Enable USB ethernet only when device is physically connected
# Matches device by MAC address: ac:de:48:00:11:22
ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="ac:de:48:00:11:22", RUN+="/usr/bin/nmcli device set enxacde48001122 autoconnect yes"
ACTION=="remove", SUBSYSTEM=="net", ATTR{address}=="ac:de:48:00:11:22", RUN+="/usr/bin/nmcli device set enxacde48001122 autoconnect no"
EOF
sudo chmod 644 /etc/udev/rules.d/70-usb-ethernet-auto.rules
sudo udevadm control --reload-rules

echo "Done! USB ethernet will auto-enable when plugged in, disable when unplugged."