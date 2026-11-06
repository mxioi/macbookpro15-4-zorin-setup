#!/bin/bash
# Install Wi-Fi and Bluetooth firmware for T2 MacBooks
# Uses the upstream t2linux firmware script:
#   https://wiki.t2linux.org/guides/wifi-bluetooth/
#
# The firmware is Apple's and cannot be redistributed, so it is extracted
# from your own macOS install, its EFI partition copy, or an Apple recovery
# image. The script asks which method to use.

set -e

FIRMWARE_SCRIPT_URL="https://wiki.t2linux.org/tools/firmware.sh"

echo "Installing Wi-Fi and Bluetooth firmware..."
echo ""

# python3 is used by the firmware script to rename the files
apt-get update
apt-get install -y curl python3

mkdir -p /lib/firmware/brcm

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "Downloading the t2linux firmware script..."
# -f makes HTTP errors (404, 500) fail instead of saving an error page
if ! curl -fL --retry 3 -o "$WORKDIR/firmware.sh" "$FIRMWARE_SCRIPT_URL"; then
    echo "Error: could not download $FIRMWARE_SCRIPT_URL"
    echo "See docs/drivers-and-firmware.md for other ways to get the firmware."
    exit 1
fi

# Refuse to run anything that is not a bash script that parses cleanly
if ! head -1 "$WORKDIR/firmware.sh" | grep -q '^#!.*bash' || ! bash -n "$WORKDIR/firmware.sh"; then
    echo "Error: the downloaded file is not a valid bash script. Not running it."
    exit 1
fi
echo "firmware.sh sha256: $(sha256sum "$WORKDIR/firmware.sh" | cut -d' ' -f1)"
echo ""
echo "Choose a method in the next menu:"
echo "  - macOS still installed:      'Retrieve the firmware directly from macOS'"
echo "  - ran copy_to_efi in macOS:   'Retrieve the firmware from the EFI partition'"
echo "  - macOS removed:              'Download a macOS Recovery Image' (Monterey to Sonoma)"
echo ""

bash "$WORKDIR/firmware.sh"

if ls /lib/firmware/brcm/brcmfmac*apple* >/dev/null 2>&1; then
    echo "✓ Apple Wi-Fi firmware present in /lib/firmware/brcm"
else
    echo "Error: no Apple Wi-Fi firmware found in /lib/firmware/brcm after running the script."
    exit 1
fi

# Reload the drivers; on a stock kernel Wi-Fi may only appear after
# rebooting into the T2 kernel.
modprobe -r brcmfmac_wcc 2>/dev/null || true
modprobe -r brcmfmac 2>/dev/null || true
modprobe brcmfmac 2>/dev/null || true
modprobe -r hci_bcm4377 2>/dev/null || true
modprobe hci_bcm4377 2>/dev/null || true

echo ""
echo "✓ Firmware installed. Wi-Fi may not appear until you boot the T2 kernel."
echo ""
