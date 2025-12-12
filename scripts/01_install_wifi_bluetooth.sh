#!/bin/bash
# Install WiFi and Bluetooth Firmware for BCM4377b3
# For MacBookPro15,4 T2 Models

set -e

echo "Installing WiFi and Bluetooth firmware..."
echo ""

# Install required tools
apt-get update
apt-get install -y curl git

# Create firmware directory
mkdir -p /lib/firmware/brcm

# Download firmware files
echo "Downloading BCM4377b3 WiFi firmware..."
curl -sL -o /lib/firmware/brcm/brcmfmac4377b3-pcie.bin \
    "https://packages.aunali1.com/apple/wifi-fw/18G2022/brcmfmac4377b3-pcie.bin"

curl -sL -o /lib/firmware/brcm/brcmfmac4377b3-pcie.apple,tahiti-SPPR-m-4c.txt \
    "https://packages.aunali1.com/apple/wifi-fw/18G2022/brcmfmac4377b3-pcie.apple,tahiti-SPPR-m-4c.txt"

curl -sL -o /lib/firmware/brcm/brcmfmac4377b3-pcie.clm_blob \
    "https://packages.aunali1.com/apple/wifi-fw/18G2022/brcmfmac4377b3-pcie.clm_blob"

echo "Downloading Bluetooth firmware..."
curl -sL -o /lib/firmware/brcm/BCM4377B3.hcd \
    "https://packages.aunali1.com/apple/wifi-fw/18G2022/BCM4377B3.hcd"

echo "✓ WiFi and Bluetooth firmware installed"
echo ""

# Load kernel modules
echo "Loading WiFi module..."
modprobe -r brcmfmac 2>/dev/null || true
modprobe brcmfmac

echo "✓ WiFi firmware loaded"
echo ""
echo "You can connect to WiFi now!"
echo ""
