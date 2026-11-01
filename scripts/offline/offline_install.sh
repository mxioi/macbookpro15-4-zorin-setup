#!/bin/bash
# MacBookPro15,4 T2 - OFFLINE installer
#
# Installs everything from a bundle created by build_offline_bundle.sh.
# No network connection is required - use this when the MacBook has no
# working WiFi yet and no Ethernet/USB network adapter.
#
# Usage (from inside the extracted bundle directory):
#   sudo bash install.sh            # interactive
#   sudo bash install.sh -y         # no prompt

set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBS_DIR="$BUNDLE_DIR/debs"
FW_DIR="$BUNDLE_DIR/firmware"
SRC_DIR="$BUNDLE_DIR/src"
REPO_SCRIPTS="$BUNDLE_DIR/repo/scripts"

T2_KERNEL_PKG="${T2_KERNEL_PKG:-linux-t2-lts}"
CODENAME="${CODENAME:-noble}"
INSTALL_PACKAGES=("$T2_KERNEL_PKG" build-essential git curl ca-certificates gpg)

die() { echo "Error: $*" >&2; exit 1; }

if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo"
    echo "Usage: sudo bash $0"
    exit 1
fi

for d in "$DEBS_DIR" "$FW_DIR" "$SRC_DIR/apple-bce-drv" "$SRC_DIR/t2-better-audio"; do
    [ -e "$d" ] || die "Bundle is incomplete: missing $d
  Run this script from inside the extracted t2-offline-bundle directory."
done

echo "============================================================"
echo "  MacBookPro15,4 OFFLINE Setup for Zorin OS 17"
echo "============================================================"
echo ""
[ -f "$BUNDLE_DIR/BUNDLE_INFO" ] && cat "$BUNDLE_DIR/BUNDLE_INFO" && echo ""
echo "This installs WiFi/Bluetooth firmware, the T2 kernel, apple-bce,"
echo "T2 audio config and kernel parameters - WITHOUT internet."
echo ""

if [ "${1:-}" != "-y" ]; then
    read -p "Continue with offline installation? (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || { echo "Installation cancelled."; exit 0; }
fi

LOG_FILE="/var/log/macbook-t2-offline-install-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1
echo "Installation log: $LOG_FILE"
echo ""

# ------------------------------------------------------------
# 0. Verify bundle integrity
# ------------------------------------------------------------
if [ -f "$BUNDLE_DIR/SHA256SUMS" ]; then
    echo "Verifying bundle checksums..."
    (cd "$BUNDLE_DIR" && sha256sum --quiet -c SHA256SUMS) \
        || die "Checksum verification failed - re-copy the bundle"
    echo "✓ Bundle verified"
    echo ""
fi

# ------------------------------------------------------------
# STEP 1: WiFi / Bluetooth firmware
# ------------------------------------------------------------
echo "============================================================"
echo "STEP 1/6: Installing WiFi and Bluetooth firmware"
echo "============================================================"
mkdir -p /lib/firmware/brcm
cp -v "$FW_DIR"/* /lib/firmware/brcm/
modprobe -r brcmfmac 2>/dev/null || true
modprobe brcmfmac 2>/dev/null || echo "ℹ brcmfmac will load after reboot into the T2 kernel"
echo "✓ Firmware installed"
echo ""

# ------------------------------------------------------------
# STEP 2: Install packages from the local repository
# ------------------------------------------------------------
echo "============================================================"
echo "STEP 2/6: Installing T2 kernel and build tools (offline)"
echo "============================================================"
APT_TMP="$(mktemp -d)"
trap 'rm -rf "$APT_TMP"' EXIT
mkdir -p "$APT_TMP"/{lists/partial,sources.list.d}
echo "deb [trusted=yes] file:$DEBS_DIR ./" > "$APT_TMP/sources.list"

# Use ONLY the local bundle as a package source; keep the real dpkg status so
# apt installs just what is missing on this machine.
APT_OPTS=(
    -o "Dir::Etc::SourceList=$APT_TMP/sources.list"
    -o "Dir::Etc::SourceParts=$APT_TMP/sources.list.d"
    -o "Dir::State::Lists=$APT_TMP/lists"
    -o "APT::Get::List-Cleanup=0"
    -o "APT::Sandbox::User=root"
    -o "Acquire::Languages=none"
)

apt-get "${APT_OPTS[@]}" update
DEBIAN_FRONTEND=noninteractive apt-get "${APT_OPTS[@]}" install -y --no-install-recommends \
    "${INSTALL_PACKAGES[@]}"
echo "✓ Packages installed"
echo ""

# Register the online T2 repository for future updates (used once WiFi works)
if [ -f "$BUNDLE_DIR/keys/t2-ubuntu-repo.gpg" ]; then
    mkdir -p /etc/apt/keyrings
    cp "$BUNDLE_DIR/keys/t2-ubuntu-repo.gpg" /etc/apt/keyrings/t2-ubuntu-repo.gpg
    echo "deb [signed-by=/etc/apt/keyrings/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/${CODENAME} ./" \
        > /etc/apt/sources.list.d/t2.list
    echo "✓ T2 apt repository configured for future online updates"
fi

echo "Removing stock Ubuntu kernel meta-packages..."
apt-get remove -y --purge linux-image-generic linux-headers-generic 2>/dev/null || true
apt-get "${APT_OPTS[@]}" autoremove -y --purge || true
echo ""

# ------------------------------------------------------------
# STEP 3: apple-bce driver
# ------------------------------------------------------------
echo "============================================================"
echo "STEP 3/6: Apple BCE driver (keyboard / trackpad)"
echo "============================================================"
T2_KVER="$(find /lib/modules -mindepth 1 -maxdepth 1 -type d -name '*t2*' -printf '%f\n' | sort -V | tail -1)"
[ -n "$T2_KVER" ] || die "No T2 kernel found in /lib/modules after install"
echo "T2 kernel: $T2_KVER"
mkdir -p /etc/modules-load.d /etc/modprobe.d

if find "/lib/modules/$T2_KVER" \( -name 't2bce_core.ko*' -o -name 'apple[-_]bce.ko*' \) | grep -q .; then
    # Current T2 kernels ship the BCE driver in-tree (t2bce_* modules, loaded
    # automatically by PCI alias). Building the external apple-bce on top of
    # it would make two drivers compete for the same device.
    echo "✓ BCE driver is already included in the T2 kernel - no build needed"
    rm -f /etc/modules-load.d/apple-bce.conf
else
    [ -d "/lib/modules/$T2_KVER/build" ] || die "Kernel headers for $T2_KVER missing"
    BUILD_DIR="$(mktemp -d)"
    cp -r "$SRC_DIR/apple-bce-drv/." "$BUILD_DIR/"
    make -C "$BUILD_DIR" KERNELRELEASE="$T2_KVER"
    make -C "$BUILD_DIR" KERNELRELEASE="$T2_KVER" install
    depmod -a "$T2_KVER"
    rm -rf "$BUILD_DIR"
    echo "✓ apple-bce built and installed for $T2_KVER"
    cat > /etc/modules-load.d/apple-bce.conf << 'EOF'
# Apple BCE Driver - T2 Chip Support
apple-bce
EOF
fi

cat > /etc/modprobe.d/blacklist-applespi.conf << 'EOF'
# Blacklist applespi - conflicts with apple-bce
blacklist applespi
EOF
echo ""

# ------------------------------------------------------------
# STEP 4: T2 audio
# ------------------------------------------------------------
echo "============================================================"
echo "STEP 4/6: T2 audio configuration (microphone)"
echo "============================================================"
AUDIO_SRC="$SRC_DIR/t2-better-audio/files"
mkdir -p /usr/share/alsa-card-profile/mixer /usr/lib/udev/rules.d
cp -r "$AUDIO_SRC/profile-sets" /usr/share/alsa-card-profile/mixer/
cp -r "$AUDIO_SRC/paths" /usr/share/alsa-card-profile/mixer/
cp "$AUDIO_SRC/91-audio-custom.rules" /usr/lib/udev/rules.d/
echo "✓ Audio profiles installed (active after reboot)"
echo ""

# ------------------------------------------------------------
# STEP 5: Kernel parameters / GRUB / initramfs
# ------------------------------------------------------------
echo "============================================================"
echo "STEP 5/6: Finalizing (kernel parameters, GRUB, initramfs)"
echo "============================================================"
bash "$REPO_SCRIPTS/05_finalize_setup.sh"

# ------------------------------------------------------------
# STEP 6: Done
# ------------------------------------------------------------
echo ""
echo "============================================================"
echo "STEP 6/6: Offline installation complete!"
echo "============================================================"
echo ""
echo "Log: $LOG_FILE"
echo ""
echo "  1. Reboot:            sudo reboot"
echo "  2. Verify kernel:     uname -r   (should include -t2-)"
echo "  3. Connect to WiFi from the system tray"
echo "  4. Run diagnostics:   bash $REPO_SCRIPTS/diagnostics.sh"
echo "  5. Once online:       sudo apt update && sudo apt upgrade"
echo ""
