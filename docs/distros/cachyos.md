# CachyOS on T2 MacBooks

> **Status: ISO build in progress; hardware testing pending.**
> Nothing on this page has been tested on the maintainer's MacBookPro15,4
> yet. It is based on the CachyOS and t2linux documentation. Results will
> be published in [hardware-support.md](../hardware-support.md) with the
> exact ISO build revision.

**Don't run this repo's `scripts/` on CachyOS.** They use `apt`, Ubuntu
kernel packages and `update-grub`, none of which apply here.

---

## What CachyOS gives you, and what it doesn't

| | Provided by CachyOS? |
|---|---|
| T2 kernel patches (keyboard, trackpad, audio, Touch Bar drivers) | ✅ In all CachyOS kernels |
| T2 boot parameters | ✅ Applied by `chwd` (CachyOS hardware detection) during install |
| Wi-Fi/Bluetooth firmware | ❌ You have to supply it. See [drivers-and-firmware.md](../drivers-and-firmware.md) |

Without firmware, the official ISO has no internal Wi-Fi. Either use
Ethernet/USB tethering during install, or build a
[custom ISO with the firmware](../custom-iso/cachyos.md).

---

## Before installing (in macOS)

Follow the [CachyOS T2 MacBook page](https://wiki.cachyos.org/installation/installation_t2macbook)
and the [t2linux pre-install guide](https://wiki.t2linux.org/guides/preinstall/):

1. Keep macOS if you can. You need it for T2 firmware updates and recovery.
2. Make space with Disk Utility → **Add Partition** (not Add Volume).
3. Startup Security Utility (boot holding Cmd+R): **No Security** and
   **Allow booting from external media**.
4. Optional, for Wi-Fi in the installer: copy the firmware to the EFI
   partition. Download the script first instead of piping it into bash:

   ```bash
   curl -fL -o ~/firmware.sh https://wiki.t2linux.org/tools/firmware.sh
   bash ~/firmware.sh copy_to_efi
   ```

## Installing

1. Hold **Option** at power-on and pick the USB stick (**EFI Boot**).
2. Optional, Wi-Fi in the live session from the EFI copy:

   ```bash
   sudo mkdir -p /tmp/apple-wifi-efi
   sudo mount /dev/nvme0n1p1 /tmp/apple-wifi-efi    # check it's your EFI partition first: lsblk -f
   bash /tmp/apple-wifi-efi/firmware.sh get_from_efi
   sudo umount /tmp/apple-wifi-efi
   printf '[device]\nwifi.backend=iwd\n' | sudo tee /etc/NetworkManager/conf.d/wifi_backend.conf
   sudo systemctl restart NetworkManager
   ```

   Or boot the [custom ISO](../custom-iso/cachyos.md), which already has
   the firmware.
3. Run the installer and select **only** the free space you created.

## After installing

### Wi-Fi firmware on the installed system

Don't assume the live session's firmware was copied to the installed
system. Check first:

```bash
ls /usr/lib/firmware/brcm/ | grep -i apple
```

If it's empty, install the firmware using either:

- the t2linux script (`get_from_macos`, or `get_from_online` if macOS is
  gone). See [drivers-and-firmware.md](../drivers-and-firmware.md#main-method-the-t2linux-firmware-script)
- the versioned `apple-bcm-firmware` package, **after checking its
  SHA-256**. See [drivers-and-firmware.md](../drivers-and-firmware.md#versioned-alternative-apple-bcm-firmware-package-arch-based-distros)

The package link on the CachyOS wiki (`mirror.funami.tech/.../os/x86_64/...`)
returned 404 when this page was written.

If Wi-Fi still fails, switch NetworkManager to `iwd` (above) or add
`brcmfmac.feature_disable=0x82000` to the kernel parameters. Recent
`wpa_supplicant` versions break this chip on Arch-based systems.

### Keep a fallback kernel

The T2 bridge driver moved from `apple-bce` to `t2bce` (`t2bce_dma`,
`t2bce_core`, `t2bce_vhci`, `t2bce_audio`) in CachyOS 7.2 kernels. Users
have reported problems around that change. These are forum reports, not
confirmed by CachyOS:

- mkinitcpio config listing `apple-bce` broke initramfs builds for kernels
  that only have `t2bce`. Reported fixed from LTS 6.18.50-3, September 2026
  ([thread](https://discuss.cachyos.org/t/change-of-module-from-apple-bce-to-t2bce/34748))
- kernel 7.2.5-1 broke keyboard/trackpad/audio for some users. 7.2.6
  fixed it for some but not all
  ([thread](https://discuss.cachyos.org/t/bug-kernel-7-2-5-1-breaks-t2bce-drivers-modules-on-t2-macbook-pro/35934))

So keep `linux-cachyos-lts` installed alongside the default kernel, and
take a snapshot before kernel updates if you use Btrfs snapshots. Check
which driver is loaded:

```bash
lsmod | grep -E '^(t2bce|apple_bce)'
grep -r 'bce' /etc/mkinitcpio.conf /etc/mkinitcpio.conf.d/ 2>/dev/null
```

### Touch Bar, audio, fan

Follow the t2linux guides. On Arch-based systems:

- Touch Bar: `sudo pacman -S tiny-dfr`
- Audio: [t2linux audio guide](https://wiki.t2linux.org/guides/audio-config/)
- Everything else: [t2linux post-install](https://wiki.t2linux.org/guides/postinstall/)

---

## Test checklist (to be filled in)

| Item | Result | Notes |
|---|---|---|
| ISO build revision | pending | `git rev-parse --short HEAD` of CachyOS-Live-ISO |
| Wi-Fi in live session | pending | |
| Bluetooth | pending | |
| Keyboard | pending | |
| Trackpad | pending | |
| Kernel(s) tested | pending | `uname -r` |
