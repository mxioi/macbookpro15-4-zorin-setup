#!/bin/bash
# Install T2-patched kernel for Zorin OS / Ubuntu and derivatives
# Source: https://github.com/t2linux/T2-Debian-and-Ubuntu-Kernel
#
# The stock kernel is kept as a fallback. Remove it only after the T2
# kernel has booted and the hardware works: scripts/06_remove_stock_kernel.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib_os.sh
source "$SCRIPT_DIR/lib_os.sh"

# Paths match the upstream instructions, so upstream's t2.list works as-is
KEYRING_PATH="/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg"
LIST_PATH="/etc/apt/sources.list.d/t2.list"
REPO_BASE="https://adityagarg8.github.io/t2-ubuntu-repo"

if ! CODENAME=$(detect_ubuntu_codename); then
    echo "Error: could not find an Ubuntu base release in /etc/os-release."
    echo "This script is for Zorin OS, Ubuntu and Ubuntu derivatives only."
    echo "For other distros see docs/distros/."
    exit 1
fi
if ! is_supported_codename "$CODENAME"; then
    echo "Error: Ubuntu base '$CODENAME' has no T2 kernel repo."
    echo "Supported: $T2_SUPPORTED_CODENAMES"
    echo "If detection is wrong, rerun with: sudo T2_CODENAME=<codename> bash $0"
    exit 1
fi
echo "Installing T2-patched kernel for Ubuntu base: $CODENAME"
echo ""

apt-get update
apt-get install -y ca-certificates curl gpg

echo "Adding T2 apt repositories..."
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

curl -fsSL --retry 3 --compressed -o "$WORKDIR/KEY.gpg" "$REPO_BASE/KEY.gpg"
gpg --dearmor < "$WORKDIR/KEY.gpg" > "$WORKDIR/t2-ubuntu-repo.gpg"
install -m 644 "$WORKDIR/t2-ubuntu-repo.gpg" "$KEYRING_PATH"

# Common repo (firmware script, audio config, tiny-dfr dependencies)
curl -fsSL --retry 3 --compressed -o "$WORKDIR/t2.list" "$REPO_BASE/t2.list"
grep -q '^deb ' "$WORKDIR/t2.list" || { echo "Error: downloaded t2.list is not an apt source"; exit 1; }
cp "$WORKDIR/t2.list" "$LIST_PATH"
# Release-specific repo (kernels)
echo "deb [signed-by=$KEYRING_PATH] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/${CODENAME} ./" >> "$LIST_PATH"

apt-get update
apt-get install -y linux-t2-lts

T2_KERNEL=$(newest_t2_kernel)
if [ -z "$T2_KERNEL" ]; then
    echo "Error: linux-t2-lts installed but no T2 kernel found in /lib/modules"
    exit 1
fi
echo "✓ T2 kernel installed: $T2_KERNEL"
echo "  Stock kernel kept as a fallback until the T2 kernel has booted."
echo ""
