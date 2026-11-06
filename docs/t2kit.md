# t2kit: one USB for any supported distro

`t2kit` is a single script you keep on your install USB next to your distro
ISOs. It does the T2-specific work that each distro's live ISO and installer
don't do for you:

1. **`capture`**: save your Wi-Fi/Bluetooth firmware into the kit, once
2. **`live`**: load that firmware in any live session, so the installer has Wi-Fi
3. **`install`**: after the installer finishes and **before you reboot**,
   set up the new system: firmware, T2 package sources, T2 kernel, the
   keyboard/trackpad driver at boot, kernel parameters and the initramfs
4. **`verify`**: after rebooting, check the hardware

Each distro still uses its own installer. t2kit handles everything around
it, so you don't have to set up each distro by hand.

> **Status:** `install` has been run against a real Ubuntu 22.04 system
> (bootstrapped in a folder, not on a Mac): it added the T2 repos,
> installed `linux-t2-lts` 6.18.60, configured `t2bce` and rebuilt an
> initramfs containing the `t2bce` modules. **Not yet tested on Mac
> hardware, with GRUB, or on a real CachyOS install.** The CachyOS path is
> covered only by automated tests against a fake system.

| Installed system | Package manager | Status |
|---|---|---|
| Zorin OS, Ubuntu, Mint and other Ubuntu derivatives (22.04, 24.04, 26.04, 26.10 bases) | apt | Real-system test passed (no Mac, no GRUB); hardware test pending |
| CachyOS | pacman | Automated tests only; hardware test pending |
| Arch, EndeavourOS | pacman | Only if a T2 kernel is already installed (e.g. from a t2linux ISO). Untested |
| Fedora, Debian, others | — | Not supported; t2kit refuses. See [distros/other.md](distros/other.md) |

---

## The USB layout

```text
USB stick (Ventoy)
├── ubuntu-t2.iso / zorin.iso / cachyos.iso ...   distro ISOs, booted by Ventoy
└── T2KIT/              copy of this repo's t2kit/ folder
    ├── t2kit           the script
    ├── lib/os.sh
    └── firmware/       created by "t2kit capture" — your Apple firmware
        ├── firmware.tar
        └── firmware.tar.sha256
```

- [Ventoy](https://www.ventoy.net/) lets you copy several ISOs onto one
  stick and pick one at boot. Any ISO works. Prefer ISOs with a T2 kernel
  (CachyOS, or the [t2linux ISOs](https://wiki.t2linux.org/)), otherwise
  the internal keyboard won't work in the live session.
- Put `T2KIT` where the live session can read it. The Ventoy data partition
  usually works. If your live session can't mount it while booted from
  Ventoy, use a small second partition (Ventoy's "preserve space" option)
  or a second USB stick. Not yet tested.
- Run the script with `bash`. exFAT sticks don't keep the execute bit.
- **The firmware is Apple's. Keep the stick to yourself.** Don't share the
  `firmware/` folder or put it in git (this repo's `.gitignore` excludes it).

---

## 1. Capture the firmware (once, when making the USB)

`t2kit capture` runs on Linux, including WSL. Pick a source:

```bash
# A. A Linux system where Wi-Fi already works on this Mac
sudo bash T2KIT/t2kit capture --from-system

# B. The tarball made in macOS by the t2linux script (tar option)
#    In macOS:  curl -fL -o ~/firmware.sh https://wiki.t2linux.org/tools/firmware.sh && bash ~/firmware.sh
bash T2KIT/t2kit capture --from-tar ~/Downloads/firmware.tar

# C. The versioned apple-bcm-firmware package (its SHA-256 is checked automatically)
bash T2KIT/t2kit capture --from-pkg apple-bcm-firmware-14.0-1-any.pkg.tar.zst
```

It keeps only the `*apple*` firmware files, refuses archives with unsafe
paths, and writes `firmware.tar` with a SHA-256 that `live` and `install`
check before using it. See [drivers-and-firmware.md](drivers-and-firmware.md)
for where each source comes from.

## 2. Boot the live session and get Wi-Fi

Boot holding **Option**, pick the USB, pick your ISO in Ventoy. Then:

```bash
sudo bash /path/to/T2KIT/t2kit live
nmcli device wifi list
```

On Arch-based live systems (CachyOS) it also switches NetworkManager to
`iwd`, which this Wi-Fi chip needs with recent `wpa_supplicant`. Use
`--iwd` to force that on other systems.

## 3. Install the distro as usual

Use the distro's own installer. **When it finishes, don't reboot yet.**

## 4. Set up the installed system, before rebooting

Mount the installed system's root partition if the installer didn't leave
it mounted:

```bash
lsblk -f                                      # find the Linux root partition
sudo mount /dev/nvme0n1p3 /mnt                # ext4 / xfs
sudo mount -o subvol=@ /dev/nvme0n1p3 /mnt    # btrfs (CachyOS default): the @ subvolume
```

Then:

```bash
sudo bash /path/to/T2KIT/t2kit install /mnt
# options: --touchbar     also install tiny-dfr for the Touch Bar
#          --no-packages  offline: skip repos and package installs
```

What it does, in order:

| Step | Ubuntu-based (apt) | Arch-based (pacman) |
|---|---|---|
| Mount `/boot`, `/boot/efi`, `/efi` from the target's fstab if needed | ✓ | ✓ |
| Copy firmware to `/usr/lib/firmware/brcm` (from the kit, or from the live session if you loaded it another way) | ✓ | ✓ |
| Add T2 package sources | T2 apt repos for the detected Ubuntu base | — (CachyOS kernels include T2) |
| Install a T2 kernel if none is present | `linux-t2-lts` | Refuses and points to the t2linux Arch guide |
| Load the T2 driver at boot | `/etc/modules-load.d/t2.conf` (`t2bce_vhci`, or `apple-bce` on older kernels) | same |
| Early boot (keyboard at a LUKS prompt) | `/etc/initramfs-tools/modules` | `/etc/mkinitcpio.conf.d/99-t2kit.conf` (picks `t2bce` or `apple-bce` per kernel, and removes a stale `apple-bce` entry) |
| Kernel parameters `intel_iommu=on iommu=pt pm_async=off` | GRUB | GRUB, systemd-boot entries, `/etc/kernel/cmdline`, `sdboot-manage`; Limine: warns if missing |
| Rebuild initramfs and bootloader config | `update-initramfs`, `update-grub` | `mkinitcpio -P`, `grub-mkconfig` / `sdboot-manage gen` |

Commands that need the installed system run inside it (`arch-chroot` when
available, otherwise a chroot with `/dev`, `/proc`, `/sys` and `/run`
bound and unmounted afterwards). Package installs need internet, which
step 2 gives you.

It's safe to run again: nothing gets added twice.

The Zorin/Ubuntu `scripts/` also add `pcie_ports=compat`, from the original
tested setup. t2kit follows the upstream t2linux list and doesn't.

## 5. Reboot and verify

```bash
sudo bash /path/to/T2KIT/t2kit verify
```

It checks the bridge driver, firmware, Wi-Fi interface, Bluetooth
controller, kernel parameters and audio device. Then check the keyboard,
trackpad, Touch Bar, speakers, microphone and camera by hand, and record
the result in [hardware-support.md](hardware-support.md#recording-a-test-result).

Updates then come from the system's normal package manager, since the T2
sources were added in step 4.

You can also run `t2kit install /` on an already-running system to fix up
anything that's missing.

---

## Developing

```bash
bash tests/test_t2kit.sh      # t2kit against fake Ubuntu/CachyOS systems
bash tests/test_lib_os.sh     # shared helpers
```

The tests stub out the in-system commands (`T2KIT_CHROOT`), downloads
(`T2KIT_FETCH`) and mounts (`T2KIT_MOUNT`), and check the files t2kit
writes. CI runs both.
