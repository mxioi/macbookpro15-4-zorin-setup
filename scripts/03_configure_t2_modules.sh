#!/bin/bash
# Configure the T2 bridge driver to load at boot
#
# The T2 kernels already contain the driver, so nothing is built here.
# Current kernels call it t2bce (t2bce_dma, t2bce_core, t2bce_vhci);
# older ones called it apple-bce. This checks which one the newly
# installed T2 kernel ships, not the kernel that is running now.
# Upstream: https://wiki.t2linux.org/guides/postinstall/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib_os.sh
source "$SCRIPT_DIR/lib_os.sh"

INITRAMFS_MODULES="/etc/initramfs-tools/modules"

T2_KERNEL=$(newest_t2_kernel)
if [ -z "$T2_KERNEL" ]; then
    echo "Error: no T2 kernel installed. Run 02_install_t2_kernel.sh first."
    exit 1
fi

DRIVER=$(bce_driver_for_kernel "/lib/modules/$T2_KERNEL")
case "$DRIVER" in
    t2bce)
        LOAD_MODULES="t2bce_vhci"
        EARLY_MODULES="t2bce_dma t2bce_core t2bce_vhci" ;;
    apple-bce)
        LOAD_MODULES="apple-bce"
        EARLY_MODULES="apple-bce" ;;
    *)
        echo "Error: $T2_KERNEL has neither t2bce nor apple-bce modules."
        echo "Do not build apple-bce from source on a T2 kernel; reinstall linux-t2-lts."
        exit 1 ;;
esac
echo "Kernel $T2_KERNEL uses: $DRIVER"

# Load at boot. Replaces the apple-bce.conf written by older versions of
# this repo, which fails on kernels that only have t2bce.
rm -f /etc/modules-load.d/apple-bce.conf
printf '# T2 bridge driver\n%s\n' "$LOAD_MODULES" > /etc/modules-load.d/t2.conf

# Load early so the internal keyboard works at a LUKS password prompt
if [ -f "$INITRAMFS_MODULES" ]; then
    # shellcheck disable=SC2086
    initramfs_tools_set_modules "$INITRAMFS_MODULES" $EARLY_MODULES
fi

# applespi drives pre-T2 SPI keyboards and is not needed on T2 Macs
cat > /etc/modprobe.d/blacklist-applespi.conf << 'EOF'
# Blacklist applespi - not used on T2 Macs
blacklist applespi
EOF

echo "✓ $DRIVER configured to load at boot (takes effect after reboot)"
echo ""
