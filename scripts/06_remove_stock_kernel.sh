#!/bin/bash
# Remove the stock Ubuntu kernel metapackages, AFTER the T2 kernel works
#
# Run this only once you have booted the T2 kernel and checked keyboard,
# trackpad and Wi-Fi. It refuses to run from any other kernel.
# Removing the metapackages stops newer stock kernels being installed and
# booted ahead of the T2 kernel.

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Error: run with sudo: sudo bash $0"
    exit 1
fi

if ! uname -r | grep -q 't2'; then
    echo "Error: you are running $(uname -r), not a T2 kernel."
    echo "Boot the -t2- kernel and check the hardware first."
    exit 1
fi
if ! lsmod | grep -qE '^(t2bce_vhci|apple_bce) '; then
    echo "Error: the T2 bridge driver (t2bce_vhci or apple_bce) is not loaded."
    echo "Fix that before removing the fallback kernel: see docs/troubleshooting.md"
    exit 1
fi

# Stock kernel metapackages, including HWE ones such as linux-generic-hwe-22.04
METAS=$(dpkg-query -W -f='${Package} ${Status}\n' 'linux-*generic*' 2>/dev/null \
    | awk '$NF == "installed" {print $1}' \
    | grep -E '^linux-(image-|headers-)?generic(-hwe-[0-9.]+)?$' || true)

if [ -z "$METAS" ]; then
    echo "No stock kernel metapackages installed. Nothing to do."
    exit 0
fi

echo "Running kernel: $(uname -r)"
echo "These stock kernel metapackages will be removed:"
echo "$METAS" | sed 's/^/  /'
echo "The kernels they pulled in are then removed by apt autoremove."
read -p "Continue? (y/n) " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

# shellcheck disable=SC2086
apt-get remove -y $METAS
apt-get autoremove -y --purge
update-grub

echo ""
echo "✓ Stock kernel removed. Installed kernels:"
dpkg-query -W -f='${Package}\n' 'linux-image-*' | grep -v '^linux-image-generic' | sed 's/^/  /'
