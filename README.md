# T2 MacBook Linux Setup

Setup guide for **Intel MacBooks with the Apple T2 chip**, with separate
instructions per distro. It started as (and is still tested as) a
**Zorin OS setup for the MacBookPro15,4** (2019 13" with Touch Bar, two
Thunderbolt ports).

| Distro | Status |
|---|---|
| Zorin OS / Ubuntu | ✅ Tested on MacBookPro15,4 ([details](docs/hardware-support.md)) |
| CachyOS | 🚧 ISO build in progress; hardware testing pending |
| Others | ℹ️ Not tested here. Pointers to [t2linux](https://wiki.t2linux.org/) |

---

## Where to start

### I'm choosing a distro
Check what's been tested and how each distro handles T2 hardware:

- [Hardware support and testing status](docs/hardware-support.md)
- [Drivers vs firmware](docs/drivers-and-firmware.md): why a distro can
  "support T2" and still have no Wi-Fi

### I've installed Linux but hardware doesn't work
Follow the page for your distro:

- [Zorin OS / Ubuntu](docs/distros/zorin-ubuntu.md) (or the automated
  installer below)
- [CachyOS](docs/distros/cachyos.md)
- [Other distros](docs/distros/other.md)
- [Troubleshooting](docs/troubleshooting.md)

### I need Wi-Fi in the installer
The Wi-Fi firmware is Apple's and no distro can ship it. Either:

- copy it to the EFI partition from macOS before installing, then load it
  in the live session: see [Drivers and firmware](docs/drivers-and-firmware.md#main-method-the-t2linux-firmware-script)
  and the [CachyOS live-session steps](docs/distros/cachyos.md#installing)
- or build a [custom CachyOS ISO with the firmware](docs/custom-iso/cachyos.md)
- or use Ethernet / USB tethering during install

---

## Automated install: Zorin OS / Ubuntu only

The scripts use `apt`, Ubuntu T2 kernel packages and GRUB. **Don't run
them on CachyOS, Arch, Fedora or other distros.** The installer checks and
refuses.

Supported Ubuntu bases: `jammy` (22.04, Zorin OS 17), `noble` (24.04,
Zorin OS 18), `resolute` (26.04), `stonking` (26.10). The installer reads
yours from `/etc/os-release`.

Before you start:

1. Install Zorin OS / Ubuntu
2. Plug in a USB keyboard and mouse (internal ones need the T2 kernel)
3. Connect to the internet: Ethernet adapter, USB tethering or USB Wi-Fi dongle

```bash
git clone https://github.com/mxioi/macbookpro15-4-zorin-setup.git
cd macbookpro15-4-zorin-setup
sudo bash scripts/master_install.sh
sudo reboot
```

After rebooting, check `uname -r` contains `-t2-` and run
`bash scripts/diagnostics.sh`. If the stock kernel booted instead, pick the
T2 one from GRUB's **Advanced options** (hold Shift at boot).

**Only once the T2 kernel works**, remove the fallback stock kernel:

```bash
sudo bash scripts/06_remove_stock_kernel.sh
```

### What the scripts do

| Script | Purpose |
|---|---|
| `master_install.sh` | Runs 01–05 in order |
| `01_install_wifi_bluetooth.sh` | Gets Apple Wi-Fi/Bluetooth firmware via the t2linux script |
| `02_install_t2_kernel.sh` | Detects your Ubuntu base, adds the T2 apt repos, installs `linux-t2-lts`. Keeps the stock kernel |
| `03_configure_t2_modules.sh` | Loads the T2 bridge driver (`t2bce`, or `apple-bce` on older kernels) at boot and in the initramfs |
| `04_setup_t2_audio.sh` / `fix_mic.sh` | Microphone config ([t2-better-audio](https://github.com/kekrby/t2-better-audio)) |
| `05_finalize_setup.sh` | Kernel parameters, GRUB, initramfs. Warns if GRUB will boot the stock kernel |
| `06_remove_stock_kernel.sh` | Run by hand after verifying. Removes stock kernel metapackages |
| `diagnostics.sh` | Hardware status report |
| `lib_os.sh` | Shared helpers (tested by `tests/test_lib_os.sh`) |

Kernel parameters set: `intel_iommu=on iommu=pt pm_async=off pcie_ports=compat`.

---

## Documentation

- [Hardware support and testing status](docs/hardware-support.md)
- [Drivers vs firmware](docs/drivers-and-firmware.md)
- [Zorin OS / Ubuntu manual install](docs/distros/zorin-ubuntu.md)
- [CachyOS](docs/distros/cachyos.md)
- [Custom CachyOS ISO with Wi-Fi firmware](docs/custom-iso/cachyos.md)
- [Other distros](docs/distros/other.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Quick reference](QUICK_REFERENCE.md)

---

## Credits

Built on the work of:

- **[t2linux](https://github.com/t2linux)**: T2 Linux support project and [wiki](https://wiki.t2linux.org)
- **[Aditya Garg](https://github.com/AdityaGarg8)**: T2 Ubuntu/Debian kernel and apt repo
- **[MCMrARM](https://github.com/MCMrARM)**: original apple-bce driver
- **[kekrby](https://github.com/kekrby)**: t2-better-audio configuration
- **[CachyOS](https://cachyos.org)**: T2 kernel patches and live ISO tooling
- **[NoaHimesaka1873](https://github.com/NoaHimesaka1873/apple-bcm-firmware)**: apple-bcm-firmware package

---

## License

MIT. See [LICENSE](LICENSE). Apple firmware is **not** included in this
repo and must not be redistributed.

## Contributing

Test results from other models and distros are especially welcome. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## Disclaimer

These steps change your kernel and boot configuration. Back up first, and
keep macOS if you can. You need it for T2 firmware updates.
