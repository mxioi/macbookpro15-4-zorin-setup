#!/bin/bash
# Shared helpers for t2kit and the Zorin/Ubuntu scripts. Source this file;
# do not run it. Every function takes its paths as arguments so tests can
# point them at fixture files, and so t2kit can inspect an installed system
# mounted under another directory.

# Ubuntu release codenames that have a T2 kernel repo upstream:
# https://github.com/AdityaGarg8/t2-ubuntu-repo#adding-the-release-specific-apt-repo
T2_SUPPORTED_CODENAMES="jammy noble resolute stonking"

# Kernel parameters from the t2linux post-install guide (used by callers).
# shellcheck disable=SC2034
T2_KERNEL_PARAMS="intel_iommu=on iommu=pt pm_async=off"

# Print the value of KEY from an os-release file (quotes stripped).
os_release_value() {
    local os_release="$1" key="$2"
    sed -n "s/^$key=//p" "$os_release" 2>/dev/null | head -1 | tr -d '"'
}

# Print the Ubuntu codename this system is based on (jammy, noble, ...).
# Zorin, Mint, Pop!_OS and other derivatives set UBUNTU_CODENAME; plain
# Ubuntu also sets VERSION_CODENAME. Set T2_CODENAME to override.
# Returns 1 if no Ubuntu base can be found (Debian, Arch, Fedora, ...).
detect_ubuntu_codename() {
    local os_release="${1:-/etc/os-release}"
    local id ubuntu_codename version_codename

    if [ -n "${T2_CODENAME:-}" ]; then
        echo "$T2_CODENAME"
        return 0
    fi
    [ -r "$os_release" ] || return 1

    id=$(os_release_value "$os_release" ID)
    ubuntu_codename=$(os_release_value "$os_release" UBUNTU_CODENAME)
    version_codename=$(os_release_value "$os_release" VERSION_CODENAME)

    if [ -n "$ubuntu_codename" ]; then
        echo "$ubuntu_codename"
    elif [ "$id" = "ubuntu" ] && [ -n "$version_codename" ]; then
        echo "$version_codename"
    else
        return 1
    fi
}

# Return 0 if the codename has a T2 kernel repo.
is_supported_codename() {
    local codename="$1" c
    for c in $T2_SUPPORTED_CODENAMES; do
        [ "$c" = "$codename" ] && return 0
    done
    return 1
}

# Print the package-manager family t2kit supports for this system:
# "apt" (Ubuntu and derivatives) or "pacman" (Arch-based). Prints nothing
# and returns 1 for anything else.
detect_family() {
    local os_release="$1" ids
    ids=" $(os_release_value "$os_release" ID) $(os_release_value "$os_release" ID_LIKE) "
    if detect_ubuntu_codename "$os_release" >/dev/null; then
        echo "apt"
    elif [[ "$ids" == *" arch "* ]]; then
        echo "pacman"
    else
        return 1
    fi
}

# Print the newest installed kernel release whose name contains "t2".
newest_t2_kernel() {
    local modules_dir="${1:-/lib/modules}"
    find "$modules_dir" -mindepth 1 -maxdepth 1 -type d -name '*t2*' -printf '%f\n' 2>/dev/null \
        | sort -V | tail -1
}

# Print the newest installed kernel release that is NOT a T2 kernel.
newest_other_kernel() {
    local modules_dir="${1:-/lib/modules}"
    find "$modules_dir" -mindepth 1 -maxdepth 1 -type d ! -name '*t2*' -printf '%f\n' 2>/dev/null \
        | sort -V | tail -1
}

# Print which BCE driver a kernel ships: "t2bce" (current kernels),
# "apple-bce" (older T2 kernels) or nothing if neither is present.
bce_driver_for_kernel() {
    local kernel_modules="$1"
    if find "$kernel_modules" -name 't2bce_vhci.ko*' 2>/dev/null | grep -q .; then
        echo "t2bce"
    elif find "$kernel_modules" -name 'apple[-_]bce.ko*' 2>/dev/null | grep -q .; then
        echo "apple-bce"
    fi
}

# Print the kernel modules directory of a system root (merged /usr first).
target_modules_dir() {
    local root="$1"
    if [ -d "$root/usr/lib/modules" ]; then
        echo "$root/usr/lib/modules"
    else
        echo "$root/lib/modules"
    fi
}

# Print the newest kernel under a modules dir that has a T2 bridge driver,
# whatever it is called (CachyOS kernels have no "t2" in their name).
newest_t2_capable_kernel() {
    local modules_dir="$1" k found=""
    for k in $(find "$modules_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V); do
        [ -n "$(bce_driver_for_kernel "$modules_dir/$k")" ] && found="$k"
    done
    echo "$found"
}

# Print a kernel command line with any missing parameters appended.
cmdline_add_params() {
    local cmdline="$1" p
    shift
    for p in "$@"; do
        [[ " $cmdline " == *" $p "* ]] || cmdline="$cmdline $p"
    done
    echo "$cmdline" | tr -s ' ' | sed 's/^ //; s/ $//'
}

# Add kernel parameters to GRUB_CMDLINE_LINUX_DEFAULT in a grub defaults file.
grub_add_params() {
    local grub_file="$1" current new
    shift
    current=$(sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT=//p' "$grub_file" | head -1 | sed "s/^[\"']//; s/[\"']\$//")
    new=$(cmdline_add_params "$current" "$@")
    if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub_file"; then
        sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$new\"|" "$grub_file"
    else
        echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$new\"" >> "$grub_file"
    fi
}

# Replace this toolkit's block of early-boot modules in an initramfs-tools
# modules file. Safe to run repeatedly.
T2_INITRAMFS_MARKER="# T2 MacBook keyboard (added by macbook T2 setup)"
initramfs_tools_set_modules() {
    local file="$1" m
    shift
    mkdir -p "$(dirname "$file")"
    touch "$file"
    sed -i "/^$T2_INITRAMFS_MARKER\$/,/^# end T2\$/d" "$file"
    {
        echo "$T2_INITRAMFS_MARKER"
        for m in "$@"; do echo "$m"; done
        echo "# end T2"
    } >> "$file"
}
