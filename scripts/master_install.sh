#!/bin/bash
# MacBookPro15,4 T2 Complete Setup - Master Installer
# Automated installation of all drivers and firmware
# For Zorin OS 17 / Ubuntu 24.04

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"

echo "============================================================"
echo "  MacBookPro15,4 Complete Setup for Zorin OS 17"
echo "============================================================"
echo ""
echo "This will install ALL drivers and firmware for your T2 MacBook:"
echo ""
echo "  ✓ WiFi and Bluetooth (BCM4377b3)"
echo "  ✓ T2 Kernel (trackpad, Touch Bar, camera support)"
echo "  ✓ Apple BCE Driver (keyboard, trackpad)"
echo "  ✓ T2 Audio (microphone, speakers)"
echo "  ✓ Kernel parameters (IOMMU, PCIe)"
echo ""
echo "REQUIREMENTS:"
echo "  - Fresh Zorin OS 17 installation"
echo "  - External USB keyboard and mouse connected"
echo "  - Internet connection (Ethernet or USB WiFi dongle)"
echo ""
echo "TIME: Approximately 15-20 minutes + 2 reboots"
echo ""
read -p "Continue with installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo"
    echo "Usage: sudo bash $0"
    exit 1
fi

# Log file
LOG_FILE="/tmp/macbook-t2-install-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo ""
echo "Installation log: $LOG_FILE"
echo ""

# ============================================================
# STEP 1: WiFi and Bluetooth Firmware
# ============================================================

echo ""
echo "============================================================"
echo "STEP 1/5: Installing WiFi and Bluetooth Firmware"
echo "============================================================"
echo ""

if [ -f "$SCRIPTS_DIR/01_install_wifi_bluetooth.sh" ]; then
    bash "$SCRIPTS_DIR/01_install_wifi_bluetooth.sh"
else
    echo "Warning: WiFi/Bluetooth script not found, skipping..."
fi

# ============================================================
# STEP 2: T2 Kernel Installation
# ============================================================

echo ""
echo "============================================================"
echo "STEP 2/5: Installing T2-Patched Kernel"
echo "============================================================"
echo ""

if [ -f "$SCRIPTS_DIR/02_install_t2_kernel.sh" ]; then
    bash "$SCRIPTS_DIR/02_install_t2_kernel.sh"
else
    echo "Error: T2 kernel installation script not found!"
    exit 1
fi

# ============================================================
# STEP 3: Apple BCE Driver
# ============================================================

echo ""
echo "============================================================"
echo "STEP 3/5: Installing Apple BCE Driver"
echo "============================================================"
echo ""

if [ -f "$SCRIPTS_DIR/03_install_apple_bce.sh" ]; then
    bash "$SCRIPTS_DIR/03_install_apple_bce.sh"
else
    echo "Error: Apple BCE installation script not found!"
    exit 1
fi

# ============================================================
# STEP 4: T2 Audio Configuration
# ============================================================

echo ""
echo "============================================================"
echo "STEP 4/5: Configuring T2 Audio (Microphone)"
echo "============================================================"
echo ""

if [ -f "$SCRIPTS_DIR/04_setup_t2_audio.sh" ]; then
    bash "$SCRIPTS_DIR/04_setup_t2_audio.sh"
else
    echo "Warning: T2 audio script not found, skipping..."
fi

# ============================================================
# STEP 5: Finalize Setup
# ============================================================

echo ""
echo "============================================================"
echo "STEP 5/5: Finalizing Setup"
echo "============================================================"
echo ""

if [ -f "$SCRIPTS_DIR/05_finalize_setup.sh" ]; then
    bash "$SCRIPTS_DIR/05_finalize_setup.sh"
else
    echo "Warning: Finalize script not found, skipping..."
fi

# ============================================================
# Installation Complete
# ============================================================

echo ""
echo "============================================================"
echo "  Installation Complete!"
echo "============================================================"
echo ""
echo "Installation log saved to: $LOG_FILE"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. REBOOT your MacBook:"
echo "   sudo reboot"
echo ""
echo "2. After reboot, verify kernel:"
echo "   uname -r"
echo "   (should show: 6.12.x-x-t2-noble)"
echo ""
echo "3. Test hardware:"
echo "   - Internal keyboard should work"
echo "   - Trackpad should work"
echo "   - Touch Bar should display"
echo "   - WiFi should connect"
echo ""
echo "4. Run diagnostics:"
echo "   bash $SCRIPTS_DIR/diagnostics.sh"
echo ""
echo "5. Configure touchpad gestures:"
echo "   Settings → Mouse & Touchpad → Touchpad"
echo ""
echo "6. Test microphone:"
echo "   Settings → Sound → Input → Test"
echo ""
echo "7. Test camera:"
echo "   cheese (install with: sudo apt install cheese)"
echo ""
echo "============================================================"
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  REBOOT NOW: sudo reboot                               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
