#!/bin/bash
# Shared helpers for the install scripts. Source this file; do not run it.
# Every function takes its paths as optional arguments so tests can point
# them at fixture files instead of the real system.

# Ubuntu release codenames that have a T2 kernel repo upstream:
# https://github.com/AdityaGarg8/t2-ubuntu-repo#adding-the-release-specific-apt-repo
T2_SUPPORTED_CODENAMES="jammy noble resolute stonking"

# Print the Ubuntu codename this system is based on (jammy, noble, ...).
# Zorin, Mint, Pop!_OS and other derivatives set UBUNTU_CODENAME; plain
# Ubuntu also sets VERSION_CODENAME. Set T2_CODENAME to override.
# Returns 1 if no Ubuntu base can be found (Debian, Arch, Fedora, ...).
detect_ubuntu_codename() {
    local os_release="${1:-/etc/os-release}"
    local id="" ubuntu_codename="" version_codename=""

    if [ -n "${T2_CODENAME:-}" ]; then
        echo "$T2_CODENAME"
        return 0
    fi
    [ -r "$os_release" ] || return 1

    # Read only the keys we need instead of sourcing the file.
    id=$(sed -n 's/^ID=//p' "$os_release" | tr -d '"')
    ubuntu_codename=$(sed -n 's/^UBUNTU_CODENAME=//p' "$os_release" | tr -d '"')
    version_codename=$(sed -n 's/^VERSION_CODENAME=//p' "$os_release" | tr -d '"')

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
