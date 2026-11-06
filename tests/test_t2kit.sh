#!/bin/bash
# Self-check for t2kit against fake installed systems. No root, no network:
#   bash tests/test_t2kit.sh
# Commands t2kit would run inside the target are recorded, not run.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T2KIT="$REPO_DIR/t2kit/t2kit"

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

# --- stubs ---------------------------------------------------------------
# Records commands run "inside" the target; installing linux-t2-lts drops a
# fake T2 kernel into the target like the real package would.
cat > "$TMP/chroot" << 'EOF'
#!/bin/bash
target="$1"; shift
echo "$*" >> "$target/chroot.log"
if [ "$*" = "apt-get install -y linux-t2-lts" ]; then
    mkdir -p "$target/usr/lib/modules/6.18.60-1-t2-jammy/kernel/drivers/t2bce"
    touch "$target/usr/lib/modules/6.18.60-1-t2-jammy/kernel/drivers/t2bce/t2bce_vhci.ko.zst"
fi
EOF
cat > "$TMP/fetch" << EOF
#!/bin/bash
case "\$1" in
    */KEY.gpg) printf 'test key' | gpg --enarmor > "\$2" 2>/dev/null ;;
    */t2.list) echo 'deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://adityagarg8.github.io/t2-ubuntu-repo ./' > "\$2" ;;
    *) exit 22 ;;
esac
EOF
cat > "$TMP/mount" << 'EOF'
#!/bin/bash
echo "mount $2" >> "$1/chroot.log"
EOF
chmod +x "$TMP/chroot" "$TMP/fetch" "$TMP/mount"

export T2KIT_ALLOW_NONROOT=1 T2KIT_CHROOT="$TMP/chroot" T2KIT_FETCH="$TMP/fetch" T2KIT_MOUNT="$TMP/mount"
export T2KIT_FIRMWARE_DIR="$TMP/kit-firmware"

# --- capture ---------------------------------------------------------------
mkdir -p "$TMP/src/brcm"
touch "$TMP/src/brcm/brcmfmac4377b3-pcie.apple,tahiti.bin" \
      "$TMP/src/brcm/brcmfmac4377b3-pcie.apple,tahiti.clm_blob" \
      "$TMP/src/brcm/brcmbt4377b3-apple,formosa.bin" \
      "$TMP/src/brcm/unrelated.bin"
bash "$T2KIT" capture --from-system "$TMP/src/brcm" >/dev/null
check "capture saves only *apple* files" "3" "$(tar -tf "$T2KIT_FIRMWARE_DIR/firmware.tar" | wc -l)"
check "capture writes a checksum" "0" "$(cd "$T2KIT_FIRMWARE_DIR" && sha256sum -c --quiet firmware.tar.sha256; echo $?)"

mkdir -p "$TMP/e" && touch "$TMP/e/x" && tar -cf "$TMP/evil.tar" -C "$TMP/e" --transform 's|^|../|' x
check "capture refuses tarball with ../ paths" "1" "$(T2KIT_FIRMWARE_DIR="$TMP/other" bash "$T2KIT" capture --from-tar "$TMP/evil.tar" >/dev/null 2>&1; echo $?)"

if command -v zstd >/dev/null; then
    mkdir -p "$TMP/pkg/usr/lib/firmware/brcm"
    touch "$TMP/pkg/usr/lib/firmware/brcm/brcmfmac4377b3-pcie.apple,tahiti.bin" "$TMP/pkg/.PKGINFO"
    tar --zstd -cf "$TMP/apple-bcm-firmware-14.0-1-any.pkg.tar.zst" -C "$TMP/pkg" .PKGINFO usr
    check "capture rejects known package name with wrong checksum" "1" \
        "$(T2KIT_FIRMWARE_DIR="$TMP/other" bash "$T2KIT" capture --from-pkg "$TMP/apple-bcm-firmware-14.0-1-any.pkg.tar.zst" >/dev/null 2>&1; echo $?)"
    cp "$TMP/apple-bcm-firmware-14.0-1-any.pkg.tar.zst" "$TMP/my-firmware.pkg.tar.zst"
    T2KIT_FIRMWARE_DIR="$TMP/pkgkit" bash "$T2KIT" capture --from-pkg "$TMP/my-firmware.pkg.tar.zst" >/dev/null 2>&1
    check "capture extracts firmware from a package" "brcmfmac4377b3-pcie.apple,tahiti.bin" "$(tar -tf "$TMP/pkgkit/firmware.tar")"
fi

# --- Ubuntu / Zorin target (GRUB, initramfs-tools, stock kernel only) ------
U="$TMP/ubuntu"
mkdir -p "$U/etc/default" "$U/etc/initramfs-tools" "$U/usr/sbin" "$U/usr/lib/modules/6.8.0-90-generic"
cat > "$U/etc/os-release" << 'EOF'
PRETTY_NAME="Zorin OS 17.3"
ID=zorin
ID_LIKE="ubuntu debian"
UBUNTU_CODENAME=jammy
EOF
echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' > "$U/etc/default/grub"
echo "# modules" > "$U/etc/initramfs-tools/modules"
touch "$U/usr/sbin/update-initramfs" "$U/usr/sbin/update-grub"
chmod +x "$U/usr/sbin/"*
echo "UUID=abcd /boot/efi vfat umask=0077 0 1" > "$U/etc/fstab"
mkdir -p "$U/etc/modules-load.d" && echo apple-bce > "$U/etc/modules-load.d/apple-bce.conf"

bash "$T2KIT" install "$U" > "$TMP/u.out" 2>&1 || { cat "$TMP/u.out"; FAILS=$((FAILS + 1)); }
check "ubuntu: firmware copied" "3" "$(find "$U/usr/lib/firmware/brcm" -type f | wc -l)"
check "ubuntu: release repo uses detected codename" "1" "$(grep -c 'releases/download/jammy ./' "$U/etc/apt/sources.list.d/t2.list")"
check "ubuntu: key installed" "0" "$(test -s "$U/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg"; echo $?)"
check "ubuntu: T2 kernel installed" "1" "$(grep -c '^apt-get install -y linux-t2-lts$' "$U/chroot.log")"
check "ubuntu: boot partition mounted from fstab" "1" "$(grep -c '^mount /boot/efi$' "$U/chroot.log")"
check "ubuntu: t2bce loads at boot" "t2bce_vhci" "$(grep -v '^#' "$U/etc/modules-load.d/t2.conf")"
check "ubuntu: old apple-bce.conf removed" "1" "$(test -e "$U/etc/modules-load.d/apple-bce.conf"; echo $?)"
check "ubuntu: initramfs modules" "t2bce_dma t2bce_core t2bce_vhci" "$(sed -n '/^# T2 MacBook/,/^# end T2/p' "$U/etc/initramfs-tools/modules" | grep -v '^#' | xargs)"
check "ubuntu: grub params kept + added" 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on iommu=pt pm_async=off"' "$(cat "$U/etc/default/grub")"
check "ubuntu: initramfs rebuilt then grub" "update-initramfs -u -k all|update-grub" "$(grep -E '^update-' "$U/chroot.log" | paste -sd'|')"

# Second run must not duplicate anything
bash "$T2KIT" install "$U" >/dev/null 2>&1
check "ubuntu rerun: one release repo line" "1" "$(grep -c 'releases/download/jammy' "$U/etc/apt/sources.list.d/t2.list")"
check "ubuntu rerun: one initramfs block" "1" "$(grep -c '^# T2 MacBook' "$U/etc/initramfs-tools/modules")"
check "ubuntu rerun: kernel not reinstalled" "1" "$(grep -c '^apt-get install -y linux-t2-lts$' "$U/chroot.log")"
check "ubuntu rerun: grub params not duplicated" "1" "$(grep -o 'iommu=pt' "$U/etc/default/grub" | wc -l)"

# --- CachyOS target (mkinitcpio, systemd-boot, kernel without "t2" in name) --
C="$TMP/cachyos"
K=6.18.50-3-cachyos-lts
mkdir -p "$C/etc/mkinitcpio.conf.d" "$C/usr/bin" "$C/boot/loader/entries" "$C/usr/lib/modules/$K/kernel/drivers/t2bce"
touch "$C/usr/lib/modules/$K/kernel/drivers/t2bce/t2bce_vhci.ko.zst"
cat > "$C/etc/os-release" << 'EOF'
PRETTY_NAME="CachyOS"
ID=cachyos
ID_LIKE=arch
EOF
echo 'MODULES=()' > "$C/etc/mkinitcpio.conf"
echo 'MODULES+=(apple-bce)' > "$C/etc/mkinitcpio.conf.d/11-chwd.conf"
echo "options root=UUID=1234 rw quiet" > "$C/boot/loader/entries/linux-cachyos-lts.conf"
touch "$C/usr/bin/mkinitcpio" && chmod +x "$C/usr/bin/mkinitcpio"

bash "$T2KIT" install "$C" --touchbar > "$TMP/c.out" 2>&1 || { cat "$TMP/c.out"; FAILS=$((FAILS + 1)); }
check "cachyos: no kernel install attempted" "0" "$(grep -c 'linux-t2' "$C/chroot.log" || true)"
check "cachyos: touchbar via pacman" "1" "$(grep -c '^pacman -S --needed --noconfirm tiny-dfr$' "$C/chroot.log")"
check "cachyos: firmware copied" "3" "$(find "$C/usr/lib/firmware/brcm" -type f | wc -l)"
check "cachyos: mkinitcpio -P run" "1" "$(grep -c '^mkinitcpio -P$' "$C/chroot.log")"
check "cachyos: loader entry params" "options root=UUID=1234 rw quiet intel_iommu=on iommu=pt pm_async=off" "$(cat "$C/boot/loader/entries/linux-cachyos-lts.conf")"

# The mkinitcpio drop-in must swap chwd's apple-bce for t2bce on a t2bce
# kernel and keep apple-bce on an older kernel. Source it the way
# mkinitcpio does, with the modules path pointed at the fake target.
mods_for() {
    (
        # shellcheck disable=SC1090,SC1091
        source "$C/etc/mkinitcpio.conf"
        # shellcheck disable=SC1090
        source "$C/etc/mkinitcpio.conf.d/11-chwd.conf"
        # shellcheck disable=SC2034
        KERNELVERSION="$1"
        # shellcheck disable=SC1090
        source <(sed "s|/usr/lib/modules|$C/usr/lib/modules|" "$C/etc/mkinitcpio.conf.d/99-t2kit.conf")
        echo "${MODULES[*]}"
    )
}
mkdir -p "$C/usr/lib/modules/7.1.8-1-cachyos/extra" && touch "$C/usr/lib/modules/7.1.8-1-cachyos/extra/apple-bce.ko.zst"
check "mkinitcpio drop-in: t2bce kernel" "t2bce_dma t2bce_core t2bce_vhci" "$(mods_for "$K")"
check "mkinitcpio drop-in: apple-bce kernel" "apple-bce" "$(mods_for 7.1.8-1-cachyos)"

# --- refusals --------------------------------------------------------------
A="$TMP/arch"
mkdir -p "$A/etc" "$A/usr/lib/modules/6.17.1-arch1-1"
printf 'ID=arch\nPRETTY_NAME="Arch Linux"\n' > "$A/etc/os-release"
check "arch without T2 kernel is refused" "1" "$(bash "$T2KIT" install "$A" >/dev/null 2>&1; echo $?)"

F="$TMP/fedora"
mkdir -p "$F/etc"
printf 'ID=fedora\nPRETTY_NAME="Fedora Linux 43"\n' > "$F/etc/os-release"
check "fedora is refused" "1" "$(bash "$T2KIT" install "$F" >/dev/null 2>&1; echo $?)"

O="$TMP/focal"
mkdir -p "$O/etc"
printf 'ID=ubuntu\nVERSION_CODENAME=focal\n' > "$O/etc/os-release"
check "unsupported ubuntu base is refused" "1" "$(bash "$T2KIT" install "$O" >/dev/null 2>&1; echo $?)"

check "empty directory is refused" "1" "$(mkdir -p "$TMP/empty"; bash "$T2KIT" install "$TMP/empty" >/dev/null 2>&1; echo $?)"

echo ""
if [ "$FAILS" -ne 0 ]; then
    echo "$FAILS check(s) failed"
    exit 1
fi
echo "All checks passed"
