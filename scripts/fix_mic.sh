#!/bin/bash
# Install t2-better-audio for Apple T2 MacBook microphone support

set -e

echo "Installing t2-better-audio configuration..."

# Clone repo if not exists
if [ ! -d "/tmp/t2-better-audio" ]; then
    git clone --depth 1 https://github.com/kekrby/t2-better-audio.git /tmp/t2-better-audio
fi

# Copy configuration files
echo "Copying profile-sets and paths..."
sudo cp -rv /tmp/t2-better-audio/files/profile-sets /usr/share/alsa-card-profile/mixer/
sudo cp -rv /tmp/t2-better-audio/files/paths /usr/share/alsa-card-profile/mixer/
sudo cp -v /tmp/t2-better-audio/files/91-audio-custom.rules /usr/lib/udev/rules.d/

# Restart PipeWire using user systemctl
echo "Restarting PipeWire (via systemctl)..."
systemctl --user restart pipewire.service 2>/dev/null || sudo -u mikeyadm systemctl --user restart pipewire.service

sleep 2

echo "Done! Check if mic is available:"
systemctl --user status pipewire.service 2>/dev/null || echo "Run in new terminal: wpctl status"