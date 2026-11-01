#!/bin/bash
# Build an OFFLINE installation bundle for MacBookPro15,4 (T2) on Zorin OS 17 / Ubuntu 24.04
#
# Run this on ANY internet-connected Debian/Ubuntu machine (a second PC, a VM,
# WSL, or the Zorin live USB on another computer). It does NOT modify that
# machine's apt sources or installed packages - it uses a private apt state.
#
# It collects everything the normal installer would download:
#   - WiFi / Bluetooth firmware (BCM4377b3)
#   - T2 kernel (linux-t2-lts) + all .deb dependencies
#   - Build tools (build-essential, ...) + dependencies, for apple-bce
#   - apple-bce-drv source
#   - t2-better-audio configuration
#   - A copy of this repository's scripts
#
# and packs them into a single tarball you copy to a USB stick.
#
# Usage:
#   bash scripts/offline/build_offline_bundle.sh [output-dir]
#
# Environment overrides:
#   CODENAME=noble          Ubuntu release of the TARGET machine
#   ARCH=amd64              Architecture of the TARGET machine
#   T2_KERNEL_PKG=linux-t2-lts
#   UBUNTU_MIRROR=http://archive.ubuntu.com/ubuntu
#   EXTRA_PACKAGES="pkg1 pkg2"   Additional packages to include
#   STOCK_KERNEL=6.8.0-xx-generic  Also include headers for this stock kernel

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CODENAME="${CODENAME:-noble}"
ARCH="${ARCH:-amd64}"
T2_KERNEL_PKG="${T2_KERNEL_PKG:-linux-t2-lts}"
UBUNTU_MIRROR="${UBUNTU_MIRROR:-http://archive.ubuntu.com/ubuntu}"
T2_REPO_URL="https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/${CODENAME}"
T2_KEY_URL="${T2_KEY_URL:-https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg}"
FW_BASE_URL="${FW_BASE_URL:-https://packages.aunali1.com/apple/wifi-fw/18G2022}"
UBUNTU_KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"

# Packages the online scripts install with apt-get
BASE_PACKAGES=(
    "$T2_KERNEL_PKG"
    build-essential
    make
    gcc
    git
    curl
    ca-certificates
    gpg
)

OUT_DIR="${1:-$PWD}"
BUNDLE_NAME="t2-offline-bundle-${CODENAME}-${ARCH}"
WORK_DIR="$(mktemp -d)"
BUNDLE_DIR="$WORK_DIR/$BUNDLE_NAME"
APT_DIR="$WORK_DIR/apt"

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

die() { echo "Error: $*" >&2; exit 1; }

echo "============================================================"
echo "  Building T2 offline bundle ($CODENAME / $ARCH)"
echo "============================================================"
echo ""

for tool in apt-get apt-cache curl git gpg dpkg-scanpackages gzip tar; do
    command -v "$tool" >/dev/null 2>&1 || die "'$tool' is required on the build machine.
  On Ubuntu/Debian: sudo apt-get install -y apt curl git gpg dpkg-dev"
done
[ -f "$UBUNTU_KEYRING" ] || die "$UBUNTU_KEYRING not found.
  Install it with: sudo apt-get install -y ubuntu-keyring"

mkdir -p "$BUNDLE_DIR"/{debs,firmware,src,keys}

# ------------------------------------------------------------
# 1. Firmware
# ------------------------------------------------------------
echo "[1/5] Downloading WiFi/Bluetooth firmware..."
FW_FILES=(
    "brcmfmac4377b3-pcie.bin"
    "brcmfmac4377b3-pcie.apple,tahiti-SPPR-m-4c.txt"
    "brcmfmac4377b3-pcie.clm_blob"
    "BCM4377B3.hcd"
)
for f in "${FW_FILES[@]}"; do
    curl -fsSL -o "$BUNDLE_DIR/firmware/$f" "$FW_BASE_URL/$f" \
        || die "Failed to download firmware: $FW_BASE_URL/$f"
    echo "  ✓ $f"
done

# ------------------------------------------------------------
# 2. Private apt configuration (does not touch the host system)
# ------------------------------------------------------------
echo ""
echo "[2/5] Preparing private apt configuration..."
mkdir -p "$APT_DIR"/{lists/partial,archives/partial,etc/sources.list.d,etc/preferences.d,etc/trusted.gpg.d}
touch "$APT_DIR/status"

curl -fsSL --compressed "$T2_KEY_URL" | gpg --dearmor > "$BUNDLE_DIR/keys/t2-ubuntu-repo.gpg" \
    || die "Failed to download T2 repository key"

cat > "$APT_DIR/etc/sources.list" << EOF
deb [arch=$ARCH signed-by=$UBUNTU_KEYRING] $UBUNTU_MIRROR $CODENAME main restricted universe
deb [arch=$ARCH signed-by=$UBUNTU_KEYRING] $UBUNTU_MIRROR $CODENAME-updates main restricted universe
deb [arch=$ARCH signed-by=$UBUNTU_KEYRING] $UBUNTU_MIRROR $CODENAME-security main restricted universe
deb [arch=$ARCH signed-by=$BUNDLE_DIR/keys/t2-ubuntu-repo.gpg] $T2_REPO_URL ./
EOF

APT_OPTS=(
    -o "APT::Architecture=$ARCH"
    -o "APT::Architectures=$ARCH"
    -o "Dir::State=$APT_DIR"
    -o "Dir::State::Lists=$APT_DIR/lists"
    -o "Dir::State::status=$APT_DIR/status"
    -o "Dir::Cache=$APT_DIR"
    -o "Dir::Cache::archives=$APT_DIR/archives"
    -o "Dir::Etc::SourceList=$APT_DIR/etc/sources.list"
    -o "Dir::Etc::SourceParts=$APT_DIR/etc/sources.list.d"
    -o "Dir::Etc::Preferences=$APT_DIR/etc/preferences"
    -o "Dir::Etc::PreferencesParts=$APT_DIR/etc/preferences.d"
    -o "Dir::Etc::TrustedParts=$APT_DIR/etc/trusted.gpg.d"
    -o "Debug::NoLocking=1"
    -o "APT::Sandbox::User=root"
)

apt-get "${APT_OPTS[@]}" -qq update || die "apt update failed (check internet connection)"
echo "  ✓ Package lists downloaded"

# ------------------------------------------------------------
# 3. Resolve and download .deb files
# ------------------------------------------------------------
echo ""
echo "[3/5] Resolving package dependencies..."

PACKAGES=("${BASE_PACKAGES[@]}")
# shellcheck disable=SC2206
[ -n "${EXTRA_PACKAGES:-}" ] && PACKAGES+=(${EXTRA_PACKAGES})
[ -n "${STOCK_KERNEL:-}" ] && PACKAGES+=("linux-headers-${STOCK_KERNEL}")

# Full recursive dependency closure (against an EMPTY dpkg status, so the
# bundle works on a fresh install regardless of what the builder has).
# The target's apt only installs what is actually missing.
mapfile -t ALL_PKGS < <(
    apt-cache "${APT_OPTS[@]}" depends --recurse \
        --no-recommends --no-suggests --no-conflicts --no-breaks \
        --no-replaces --no-enhances "${PACKAGES[@]}" \
    | grep -v '^ ' | grep -v '^<' | sed 's/:.*//' | sort -u
)
[ "${#ALL_PKGS[@]}" -gt 0 ] || die "Dependency resolution returned nothing"
echo "  ✓ ${#ALL_PKGS[@]} packages to download"

echo ""
echo "[4/5] Downloading .deb packages (this can take a while)..."
(
    cd "$BUNDLE_DIR/debs"
    FAILED=()
    for p in "${ALL_PKGS[@]}"; do
        apt-get "${APT_OPTS[@]}" -qq download "$p" 2>/dev/null || FAILED+=("$p")
    done
    if [ "${#FAILED[@]}" -gt 0 ]; then
        echo "  ℹ Skipped (virtual or unavailable): ${FAILED[*]}"
    fi
)
DEB_COUNT=$(find "$BUNDLE_DIR/debs" -name '*.deb' | wc -l)
[ "$DEB_COUNT" -gt 0 ] || die "No packages were downloaded"
find "$BUNDLE_DIR/debs" -name "linux-image-*t2*.deb" | grep -q . \
    || die "T2 kernel image was not downloaded - check the T2 repository"

# Build a local apt repository index
(
    cd "$BUNDLE_DIR/debs"
    dpkg-scanpackages --multiversion . /dev/null 2>/dev/null > Packages
    gzip -9kf Packages
)
echo "  ✓ $DEB_COUNT packages downloaded and indexed"

# ------------------------------------------------------------
# 4. Sources (apple-bce, t2-better-audio) and repo scripts
# ------------------------------------------------------------
echo ""
echo "[5/5] Downloading driver/audio sources..."
git clone -q --depth 1 https://github.com/t2linux/apple-bce-drv.git "$BUNDLE_DIR/src/apple-bce-drv"
git clone -q --depth 1 https://github.com/kekrby/t2-better-audio.git "$BUNDLE_DIR/src/t2-better-audio"
rm -rf "$BUNDLE_DIR/src/apple-bce-drv/.git" "$BUNDLE_DIR/src/t2-better-audio/.git"
echo "  ✓ apple-bce-drv"
echo "  ✓ t2-better-audio"

mkdir -p "$BUNDLE_DIR/repo"
cp -r "$REPO_DIR/scripts" "$REPO_DIR/docs" "$REPO_DIR/README.md" "$BUNDLE_DIR/repo/" 2>/dev/null || true
cp "$REPO_DIR/scripts/offline/offline_install.sh" "$BUNDLE_DIR/install.sh"
chmod +x "$BUNDLE_DIR/install.sh"

cat > "$BUNDLE_DIR/BUNDLE_INFO" << EOF
Built:      $(date -u +%Y-%m-%dT%H:%M:%SZ)
Codename:   $CODENAME
Arch:       $ARCH
Kernel pkg: $T2_KERNEL_PKG
T2 kernel:  $(find "$BUNDLE_DIR/debs" -name 'linux-image-*t2*.deb' -printf '%f\n' | head -1)
Packages:   $DEB_COUNT
EOF

(cd "$BUNDLE_DIR" && find . -type f -print0 | sort -z | xargs -0 sha256sum > "$WORK_DIR/SHA256SUMS")
mv "$WORK_DIR/SHA256SUMS" "$BUNDLE_DIR/SHA256SUMS"

mkdir -p "$OUT_DIR"
TARBALL="$OUT_DIR/$BUNDLE_NAME.tar.gz"
tar -C "$WORK_DIR" -czf "$TARBALL" "$BUNDLE_NAME"

echo ""
echo "============================================================"
echo "  Bundle ready: $TARBALL"
echo "  Size: $(du -h "$TARBALL" | cut -f1)"
echo "============================================================"
echo ""
echo "Copy it to a USB stick, then on the MacBook:"
echo ""
echo "  tar -xzf $BUNDLE_NAME.tar.gz"
echo "  cd $BUNDLE_NAME"
echo "  sudo bash install.sh"
echo ""
