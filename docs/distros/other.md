# Other distros

This repo has only been tested on Zorin OS, with CachyOS in progress. For
anything else, follow [t2linux](https://wiki.t2linux.org/), which covers
far more distros. Don't run this repo's `scripts/` outside Zorin/Ubuntu.
They use `apt` and GRUB.

What carries over from this repo to any distro:

- [Drivers vs firmware](../drivers-and-firmware.md): why "T2 support" still
  leaves you without Wi-Fi, and how to get the firmware
- [Hardware support](../hardware-support.md): what works on the
  MacBookPro15,4
- [Troubleshooting](../troubleshooting.md): the hardware sections apply
  everywhere. Package commands differ

## Where to start for each distro family

| Family | T2 kernel / install guide |
|---|---|
| Ubuntu flavours, Linux Mint | [Zorin/Ubuntu page](zorin-ubuntu.md), or the [T2 Ubuntu ISOs](https://wiki.t2linux.org/distributions/ubuntu/installation/) |
| Debian 12/13 | [t2-ubuntu-repo](https://github.com/AdityaGarg8/t2-ubuntu-repo) (has Debian repos) |
| Arch, EndeavourOS | [t2linux Arch guide](https://wiki.t2linux.org/distributions/arch/installation/) |
| CachyOS | [cachyos.md](cachyos.md) |
| Fedora | [t2linux Fedora guide](https://wiki.t2linux.org/distributions/fedora/installation/) |
| NixOS | [t2linux NixOS guide](https://wiki.t2linux.org/distributions/nixos/installation/) |

## Checklist for any distro

1. A kernel with T2 patches (check `lsmod | grep -E '^(t2bce|apple_bce)'`).
2. The bridge driver loaded at boot and, for disk encryption, in the
   initramfs. The generator differs: initramfs-tools, mkinitcpio or dracut.
   See [t2linux post-install](https://wiki.t2linux.org/guides/postinstall/).
3. Wi-Fi/Bluetooth firmware from macOS.
4. Kernel parameters `intel_iommu=on iommu=pt pm_async=off`, added the way
   your bootloader expects (GRUB, systemd-boot, Limine...).

If you get a distro working on a T2 Mac, please open an issue with the
details listed in [hardware-support.md](../hardware-support.md#recording-a-test-result).
