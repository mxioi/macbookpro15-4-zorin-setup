# Drivers vs firmware on T2 MacBooks

A distro can "support T2 Macs" and still give you no Wi-Fi. That is
because two different things are needed, and they come from different
places.

| | Driver | Firmware |
|---|---|---|
| What it is | Kernel code that talks to the hardware | A binary blob the hardware itself runs, loaded by the driver |
| Example | `t2bce` (keyboard, trackpad, audio), `brcmfmac` (Wi-Fi), `hci_bcm4377` (Bluetooth) | `brcmfmac4377b3-pcie.apple,tahiti.bin` |
| Where it comes from | A T2-patched kernel from your distro or t2linux | Apple's macOS, copied by you |
| Can a distro ship it? | Yes | **No.** Apple's licence doesn't allow redistribution |
| Symptom if missing | No keyboard, trackpad, Touch Bar or audio | Keyboard works, but no Wi-Fi or Bluetooth |

So "T2 support" in a distro (CachyOS, T2 Ubuntu ISOs, etc.) normally means
**the drivers**. You still have to supply the Wi-Fi/Bluetooth firmware.

## The T2 bridge driver: `t2bce`, formerly `apple-bce`

The keyboard, trackpad, Touch Bar, camera and audio sit behind the T2
chip. The kernel reaches them through the bridge driver.

- **Current T2 kernels** ship it as `t2bce`, split into `t2bce_dma`,
  `t2bce_core`, `t2bce_vhci` and `t2bce_audio`.
- **Older T2 kernels** shipped one module called `apple-bce`.
- T2 kernels have the driver **built in**. Do not build `apple-bce` from
  source or install the `apple-bce` package on top of `linux-t2` /
  `linux-t2-lts`. [Upstream says not to](https://github.com/AdityaGarg8/t2-ubuntu-repo#adding-the-release-specific-apt-repo).
  Earlier versions of this repo did build it, which was unnecessary.

Check which one your running kernel uses:

```bash
lsmod | grep -E '^(t2bce|apple_bce)'
```

To load it at boot, list `t2bce_vhci` (or `apple-bce` on older kernels) in
`/etc/modules-load.d/t2.conf`. To use the internal keyboard at a LUKS
password prompt, also add `t2bce_dma t2bce_core t2bce_vhci` to the
initramfs. See the
[t2linux post-install guide](https://wiki.t2linux.org/guides/postinstall/).

## Getting the Wi-Fi/Bluetooth firmware

### Main method: the t2linux firmware script

Use the upstream guide:
[wiki.t2linux.org/guides/wifi-bluetooth](https://wiki.t2linux.org/guides/wifi-bluetooth/).
It works on every distro. Its script
(`https://wiki.t2linux.org/tools/firmware.sh`) offers these methods:

| Method | Needs macOS? | When to use |
|---|---|---|
| Copy to EFI partition (`copy_to_efi` in macOS, `get_from_efi` in Linux) | Yes, run once before installing Linux | Best if you'll want Wi-Fi in the installer |
| Tarball / package made in macOS | Yes | Move the firmware on a USB stick |
| Read directly from macOS (`get_from_macos`) | macOS partition still on disk | Already installed Linux next to macOS |
| Apple recovery image (`get_from_online`) | No | macOS has been removed. Needs wired/USB internet. Pick Monterey, Ventura or Sonoma |

`scripts/01_install_wifi_bluetooth.sh` downloads that script with
`curl -fL` (so a 404 fails instead of saving an error page), checks it is
a valid bash script, prints its SHA-256 and runs it.

Methods 4 and 5 don't work on iMac19,1, iMac19,2 or iMacPro1,1.

### Versioned alternative: `apple-bcm-firmware` package (Arch-based distros)

A prebuilt Arch package of the same Apple firmware is on GitHub. Use it
when you can't run the script, e.g. when building a custom ISO.

| | |
|---|---|
| File | `apple-bcm-firmware-14.0-1-any.pkg.tar.zst` |
| Source | [NoaHimesaka1873/apple-bcm-firmware release v14.0](https://github.com/NoaHimesaka1873/apple-bcm-firmware/releases/tag/v14.0) (published 2023-10-23) |
| URL | `https://github.com/NoaHimesaka1873/apple-bcm-firmware/releases/download/v14.0/apple-bcm-firmware-14.0-1-any.pkg.tar.zst` |
| Size | 7,508,794 bytes |
| SHA-256 | `f2cd47d9e3fb9658f16997b2d9ace3033b57925b8c6ddd86ccc3d07d0c3e9559` |
| Contains | Files under `usr/lib/firmware/brcm/`, including `brcmfmac4377b3-pcie.apple,tahiti.*` for the MacBookPro15,4 |
| Checked | 2026-11-05: downloaded, checksum taken, archive listed. Not yet booted |

```bash
curl -fL -o apple-bcm-firmware-14.0-1-any.pkg.tar.zst \
  https://github.com/NoaHimesaka1873/apple-bcm-firmware/releases/download/v14.0/apple-bcm-firmware-14.0-1-any.pkg.tar.zst
echo "f2cd47d9e3fb9658f16997b2d9ace3033b57925b8c6ddd86ccc3d07d0c3e9559  apple-bcm-firmware-14.0-1-any.pkg.tar.zst" | sha256sum -c -
zstd -t apple-bcm-firmware-14.0-1-any.pkg.tar.zst   # archive is intact
sudo pacman -U apple-bcm-firmware-14.0-1-any.pkg.tar.zst
```

If the checksum doesn't match, **stop**. Don't install it.

This is a third-party build. Its PKGBUILD pulls the firmware from
`mirror.funami.tech`. Prefer the t2linux script when you can.

### Dead download links (don't use)

| Link | Status (2026-11-05) | Used by |
|---|---|---|
| `https://packages.aunali1.com/apple/wifi-fw/18G2022/...` | Host doesn't resolve | Old versions of this repo's script and manual guide |
| `https://mirror.funami.tech/arch-mact2/os/x86_64/apple-bcm-firmware-14.0-1-any.pkg.tar.zst` | HTTP 404 | The CachyOS wiki's T2 page |

### After installing firmware

Reload the drivers (or reboot):

```bash
sudo modprobe -r brcmfmac_wcc; sudo modprobe -r brcmfmac; sudo modprobe brcmfmac
sudo modprobe -r hci_bcm4377; sudo modprobe hci_bcm4377
```

Check it loaded:

```bash
sudo journalctl -k --grep=brcmfmac
```

Success is a line where the interface is renamed from `wlan0` (for example
to `wlp1s0f0`). Earlier `failed with error -2` lines are normal: the
driver tries several file names before it finds the matching one.

On Arch-based systems with wpa_supplicant 2.11 or newer, Wi-Fi may still
fail. Use `iwd` as the NetworkManager backend, or add the kernel parameter
`brcmfmac.feature_disable=0x82000`.
