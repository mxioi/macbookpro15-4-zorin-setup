#!/bin/bash
# Self-check for scripts/lib_os.sh. Runs anywhere, no root needed:
#   bash tests/test_lib_os.sh

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib_os.sh
source "$REPO_DIR/scripts/lib_os.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
FAILS=0

check() {
    local name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "ok   $name"
    else
        echo "FAIL $name: expected '$expected', got '$actual'"
        FAILS=$((FAILS + 1))
    fi
}

# --- detect_ubuntu_codename ---------------------------------------------
cat > "$TMP/zorin17" << 'EOF'
NAME="Zorin OS"
ID=zorin
ID_LIKE="ubuntu debian"
VERSION_CODENAME=jammy
UBUNTU_CODENAME=jammy
EOF
check "zorin 17 -> jammy" "jammy" "$(detect_ubuntu_codename "$TMP/zorin17")"

cat > "$TMP/mint" << 'EOF'
ID=linuxmint
VERSION_CODENAME=wilma
UBUNTU_CODENAME=noble
EOF
check "derivative uses UBUNTU_CODENAME" "noble" "$(detect_ubuntu_codename "$TMP/mint")"

cat > "$TMP/ubuntu" << 'EOF'
ID=ubuntu
VERSION_CODENAME=resolute
EOF
check "plain ubuntu" "resolute" "$(detect_ubuntu_codename "$TMP/ubuntu")"

cat > "$TMP/cachyos" << 'EOF'
NAME="CachyOS Linux"
ID=cachyos
ID_LIKE=arch
EOF
check "arch-based is rejected" "1" "$(detect_ubuntu_codename "$TMP/cachyos" >/dev/null; echo $?)"

cat > "$TMP/debian" << 'EOF'
ID=debian
VERSION_CODENAME=trixie
EOF
check "debian is rejected" "1" "$(detect_ubuntu_codename "$TMP/debian" >/dev/null; echo $?)"

check "override wins" "noble" "$(T2_CODENAME=noble detect_ubuntu_codename "$TMP/cachyos")"

check "noble supported" "0" "$(is_supported_codename noble; echo $?)"
check "focal unsupported" "1" "$(is_supported_codename focal; echo $?)"

# --- kernel selection ----------------------------------------------------
M="$TMP/modules"
mkdir -p "$M/6.8.0-90-generic" "$M/6.18.9-1-t2-noble" "$M/6.18.60-1-t2-noble" "$M/6.17.0-5-generic"
check "newest t2 kernel (version sort)" "6.18.60-1-t2-noble" "$(newest_t2_kernel "$M")"
check "newest other kernel" "6.17.0-5-generic" "$(newest_other_kernel "$M")"

# --- BCE driver detection ----------------------------------------------
mkdir -p "$M/6.18.60-1-t2-noble/kernel/drivers/staging/t2bce"
touch "$M/6.18.60-1-t2-noble/kernel/drivers/staging/t2bce/t2bce_vhci.ko.zst"
mkdir -p "$M/6.18.9-1-t2-noble/updates"
touch "$M/6.18.9-1-t2-noble/updates/apple-bce.ko"
check "current kernel uses t2bce" "t2bce" "$(bce_driver_for_kernel "$M/6.18.60-1-t2-noble")"
check "older kernel uses apple-bce" "apple-bce" "$(bce_driver_for_kernel "$M/6.18.9-1-t2-noble")"
check "stock kernel has none" "" "$(bce_driver_for_kernel "$M/6.8.0-90-generic")"

echo ""
if [ "$FAILS" -ne 0 ]; then
    echo "$FAILS check(s) failed"
    exit 1
fi
echo "All checks passed"
