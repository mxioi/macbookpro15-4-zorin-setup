#!/bin/bash
# Install t2-better-audio for Apple T2 MacBook microphone support

set -e

echo "Installing t2-better-audio configuration..."

REAL_USER=${SUDO_USER:-$USER}

# Clone a fresh copy
rm -rf /tmp/t2-better-audio
git clone --depth 1 https://github.com/kekrby/t2-better-audio.git /tmp/t2-better-audio

# Copy configuration files
echo "Copying profile-sets and paths..."
sudo cp -rv /tmp/t2-better-audio/files/profile-sets /usr/share/alsa-card-profile/mixer/
sudo cp -rv /tmp/t2-better-audio/files/paths /usr/share/alsa-card-profile/mixer/
sudo cp -v /tmp/t2-better-audio/files/91-audio-custom.rules /usr/lib/udev/rules.d/

# Restart PipeWire using user systemctl
echo "Restarting audio services..."
if [ "$REAL_USER" != "root" ]; then
    sudo -u "$REAL_USER" systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || true
fi

sleep 2

echo "Done! Check if mic is available:"
if [ "$REAL_USER" != "root" ]; then
    sudo -u "$REAL_USER" systemctl --user status pipewire.service 2>/dev/null || echo "Run in new terminal: wpctl status"
else
    echo "Run in new terminal: wpctl status"
fi
