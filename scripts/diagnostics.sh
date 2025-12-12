#!/bin/bash
# MacBookPro T2 Hardware Diagnostics
# Checks status of all hardware components

echo "============================================================"
echo "  MacBookPro T2 Hardware Diagnostics"
echo "============================================================"
echo ""

echo "[System Information]"
echo "  Model: $(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown')"
echo "  Kernel: $(uname -r)"
echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
echo ""

echo "[T2 Kernel Check]"
if uname -r | grep -q "t2"; then
    echo "  ✓ Running T2-patched kernel"
else
    echo "  ✗ NOT running T2 kernel - trackpad won't work!"
    echo "    Current: $(uname -r)"
    echo "    Expected: 6.12.x-x-t2-noble"
fi
echo ""

echo "[Kernel Modules]"
echo "  apple-bce:      $(lsmod | grep -q apple_bce && echo '✓ Loaded' || echo '✗ Not loaded')"
echo "  brcmfmac (WiFi):$(lsmod | grep -q brcmfmac && echo '✓ Loaded' || echo '✗ Not loaded')"
echo "  i915 (GPU):     $(lsmod | grep -q i915 && echo '✓ Loaded' || echo '✗ Not loaded')"
echo ""

echo "[Keyboard]"
if cat /proc/bus/input/devices 2>/dev/null | grep -q "Apple Internal Keyboard"; then
    echo "  ✓ Internal keyboard detected"
else
    echo "  ✗ Internal keyboard NOT detected"
fi
echo ""

echo "[Trackpad]"
if uname -r | grep -q "t2"; then
    echo "  ✓ T2 kernel running (trackpad should work)"
else
    echo "  ✗ Stock kernel - trackpad WILL NOT work"
fi
echo ""

echo "[Touch Bar]"
if [ -e /dev/input/by-id/*Apple*Touch*Bar* ] 2>/dev/null; then
    echo "  ✓ Touch Bar detected"
else
    echo "  ℹ Touch Bar status unknown (check if visible)"
fi
echo ""

echo "[Camera]"
if [ -e /dev/video0 ]; then
    echo "  ✓ Camera device found (/dev/video0)"
else
    echo "  ✗ Camera NOT detected"
fi
echo ""

echo "[Microphone]"
MIC_COUNT=$(arecord -l 2>/dev/null | grep -c "Digital Mic" || echo "0")
if [ "$MIC_COUNT" -gt 0 ]; then
    echo "  ✓ Microphone detected ($MIC_COUNT device(s))"
else
    echo "  ✗ Microphone NOT detected"
fi
echo ""

echo "[WiFi]"
if iwconfig 2>/dev/null | grep -q "ESSID"; then
    SSID=$(iwconfig 2>/dev/null | grep ESSID | cut -d'"' -f2)
    echo "  ✓ WiFi connected: $SSID"
elif ip link show | grep -q "wl"; then
    echo "  ✓ WiFi adapter present (not connected)"
else
    echo "  ✗ WiFi NOT detected"
fi
echo ""

echo "[Bluetooth]"
if systemctl is-active bluetooth >/dev/null 2>&1; then
    echo "  ✓ Bluetooth service running"
else
    echo "  ✗ Bluetooth service NOT running"
fi
echo ""

echo "[Display/GPU]"
if command -v glxinfo >/dev/null 2>&1; then
    RENDERER=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2 | xargs)
    if [ -n "$RENDERER" ]; then
        echo "  ✓ GPU: $RENDERER"
    else
        echo "  ✗ GPU info unavailable"
    fi
else
    echo "  ℹ Install mesa-utils for GPU info: sudo apt install mesa-utils"
fi
echo ""

echo "[Thunderbolt/USB-C]"
if command -v boltctl >/dev/null 2>&1; then
    DOMAINS=$(boltctl domains 2>/dev/null | grep -c "Domain" || echo "0")
    echo "  ✓ Thunderbolt: $DOMAINS domain(s)"
else
    echo "  ℹ Thunderbolt status unknown"
fi
echo ""

echo "[Kernel Parameters]"
CMDLINE=$(cat /proc/cmdline)
echo "  intel_iommu=on:  $(echo $CMDLINE | grep -q 'intel_iommu=on' && echo '✓' || echo '✗')"
echo "  iommu=pt:        $(echo $CMDLINE | grep -q 'iommu=pt' && echo '✓' || echo '✗')"
echo "  pcie_ports=compat: $(echo $CMDLINE | grep -q 'pcie_ports=compat' && echo '✓' || echo '✗')"
echo ""

echo "============================================================"
echo "  Diagnostics Complete"
echo "============================================================"
echo ""
echo "If any hardware shows as NOT working:"
echo "  1. Check you rebooted after installation"
echo "  2. Verify T2 kernel is running: uname -r"
echo "  3. Run: sudo modprobe apple-bce"
echo "  4. See: docs/TROUBLESHOOTING.md"
echo ""
