#!/bin/bash
# Install T2-Patched Kernel for Ubuntu 24.04
# Source: https://github.com/t2linux/T2-Ubuntu-Kernel

set -e

echo "Installing T2-patched kernel..."
echo ""

CODENAME="noble"
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_PATH="$KEYRING_DIR/t2-ubuntu-repo.gpg"
LIST_PATH="/etc/apt/sources.list.d/t2.list"

# Ensure repo tooling is present
apt-get update
apt-get install -y ca-certificates curl gpg

# Add repository GPG key
echo "Adding T2 kernel repository..."
mkdir -p "$KEYRING_DIR"
curl -fsSL --compressed "https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg" | \
    gpg --dearmor -o "$KEYRING_PATH"

# Create sources list
cat > "$LIST_PATH" << EOF
deb [signed-by=$KEYRING_PATH] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/${CODENAME} ./
EOF

# Update and install
apt-get update
apt-get install -y linux-t2-lts

echo "✓ T2 kernel installed"
echo ""

# Remove stock Ubuntu kernels to force T2 kernel boot
echo "Removing stock Ubuntu kernels..."
apt-get remove -y --purge linux-image-generic linux-headers-generic 2>/dev/null || true
apt-get autoremove -y --purge

echo "✓ Stock kernels removed"
echo ""
echo "System will boot T2 kernel on next reboot"
echo ""
