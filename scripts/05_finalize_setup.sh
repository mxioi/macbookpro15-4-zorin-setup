#!/bin/bash
# Finalize T2 MacBook Setup
# Configure kernel parameters and cleanup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib_os.sh
source "$SCRIPT_DIR/lib_os.sh"

echo "Finalizing setup..."
echo ""

# ============================================================
# Configure Kernel Parameters
# ============================================================

echo "Configuring kernel parameters..."

# Backup GRUB config
cp /etc/default/grub /etc/default/grub.backup.t2

# Update kernel parameters
CURRENT_LINE=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub | head -1)
CURRENT_OPTS=$(echo "$CURRENT_LINE" | sed 's/GRUB_CMDLINE_LINUX_DEFAULT=//' | sed 's/"//g')

# Add T2-required parameters
NEW_OPTS="$CURRENT_OPTS"
echo "$NEW_OPTS" | grep -q "intel_iommu=on" || NEW_OPTS="$NEW_OPTS intel_iommu=on"
echo "$NEW_OPTS" | grep -q "iommu=pt" || NEW_OPTS="$NEW_OPTS iommu=pt"
echo "$NEW_OPTS" | grep -q "pm_async=off" || NEW_OPTS="$NEW_OPTS pm_async=off"
echo "$NEW_OPTS" | grep -q "pcie_ports=compat" || NEW_OPTS="$NEW_OPTS pcie_ports=compat"

# Clean up extra spaces
NEW_OPTS=$(echo "$NEW_OPTS" | tr -s ' ')

# Update GRUB
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$NEW_OPTS\"|" /etc/default/grub

echo "✓ Kernel parameters configured"

# ============================================================
# Update GRUB
# ============================================================

echo "Updating GRUB..."
update-grub
echo "✓ GRUB updated"

# ============================================================
# Update initramfs
# ============================================================

echo "Updating initramfs..."
update-initramfs -u -k all
echo "✓ Initramfs updated"

# ============================================================
# Summary
# ============================================================

echo ""
echo "Finalization complete!"
echo ""
echo "Kernel parameters added:"
echo "  - intel_iommu=on"
echo "  - iommu=pt"
echo "  - pm_async=off"
echo "  - pcie_ports=compat"
echo ""

# ============================================================
# Check which kernel GRUB will boot by default
# ============================================================

# The stock kernel is kept as a fallback, and GRUB boots the highest
# version by default. Warn if that is not the T2 kernel.
T2_KERNEL=$(newest_t2_kernel)
OTHER_KERNEL=$(newest_other_kernel)
if [ -n "$OTHER_KERNEL" ] && [ -n "$T2_KERNEL" ] && \
   [ "$(printf '%s\n%s\n' "$T2_KERNEL" "$OTHER_KERNEL" | sort -V | tail -1)" != "$T2_KERNEL" ]; then
    echo "WARNING: stock kernel $OTHER_KERNEL is newer than $T2_KERNEL."
    echo "  GRUB will boot the stock kernel by default. At boot, hold Shift"
    echo "  (or press Esc) for the GRUB menu, open 'Advanced options' and pick"
    echo "  the -t2- kernel. Once it works, run 06_remove_stock_kernel.sh."
    echo ""
fi
