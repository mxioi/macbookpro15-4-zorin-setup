#!/bin/bash
# Setup T2 Audio Configuration for Microphone
# Source: https://github.com/kekrby/t2-better-audio

set -e

echo "Setting up T2 audio configuration..."
echo ""

# Clone and install t2-better-audio
cd /tmp
rm -rf t2-better-audio
git clone https://github.com/kekrby/t2-better-audio.git
cd t2-better-audio

# Run installation
./install.sh

echo "✓ T2 audio configuration installed"
echo ""

# Restart audio services
REAL_USER=${SUDO_USER:-$USER}
if [ "$REAL_USER" != "root" ]; then
    echo "Restarting PipeWire..."
    sudo -u "$REAL_USER" systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || true
fi

echo "✓ Audio services restarted"
echo ""
echo "Microphone should work after reboot"
echo ""
