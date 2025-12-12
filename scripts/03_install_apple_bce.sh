#!/bin/bash
# Install Apple BCE Driver for T2 Keyboard and Trackpad
# Source: https://github.com/t2linux/apple-bce-drv

set -e

echo "Installing Apple BCE driver..."
echo ""

# Install build dependencies
apt-get update
apt-get install -y git build-essential linux-headers-$(uname -r)

# Clone repository
cd /tmp
rm -rf apple-bce-drv
git clone https://github.com/t2linux/apple-bce-drv.git
cd apple-bce-drv

# Build and install
echo "Building apple-bce module..."
make clean 2>/dev/null || true
make
make install
depmod -a

# Configure auto-load
cat > /etc/modules-load.d/apple-bce.conf << 'EOF'
# Apple BCE Driver - T2 Chip Support
apple-bce
EOF

# Blacklist conflicting applespi
cat > /etc/modprobe.d/blacklist-applespi.conf << 'EOF'
# Blacklist applespi - conflicts with apple-bce
blacklist applespi
EOF

# Load module now
modprobe apple-bce && echo "✓ apple-bce module loaded" || echo "Will load on reboot"

echo "✓ Apple BCE driver installed"
echo ""
