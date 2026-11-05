# Troubleshooting Guide

Common issues and solutions for T2 MacBooks. Commands using `apt`,
`update-grub` or this repo's `scripts/` are for **Zorin OS / Ubuntu only**.
On CachyOS or other distros, use the hardware checks but your own package
and bootloader commands.

**Contents:** [Keyboard](#keyboard-not-working) ·
[Trackpad](#trackpad-not-working) · [Wi-Fi](#wifi-not-working) ·
[Downloads and installs](#downloads-and-installs-failing) ·
[Microphone](#microphone-not-working) ·
[Boot](#system-wont-boot-t2-kernel) · [CachyOS](#cachyos-keyboard-or-trackpad-stopped-after-a-kernel-update) ·
[Custom ISO builds](#custom-iso-build-problems)

---

## Keyboard Not Working

### Check the T2 bridge driver is loaded
```bash
lsmod | grep -E '^(t2bce|apple_bce)'
```

Current T2 kernels use `t2bce`; older ones `apple-bce`.

**If not loaded:**
```bash
sudo modprobe t2bce_vhci || sudo modprobe apple-bce
```

**If "module not found":** you're probably not on the T2 kernel
(`uname -r` must contain `-t2-`). Don't build `apple-bce` from source; T2
kernels have the driver built in. Boot the T2 kernel, then make it load at
boot:
```bash
sudo bash scripts/03_configure_t2_modules.sh
sudo update-initramfs -u -k all
```

**`systemd-modules-load` fails at boot naming `apple-bce`:** an older
version of this repo wrote `/etc/modules-load.d/apple-bce.conf`. Current
kernels don't have that module. Rerun `03_configure_t2_modules.sh`, which
replaces it.

---

## Trackpad Not Working

### 1. Verify T2 Kernel
```bash
uname -r
```

Must include: `-t2-`

**If it ends in `-generic`:**
- Stock Ubuntu kernel does NOT support the trackpad
- Pick the T2 kernel in GRUB (hold Shift at boot → Advanced options), or reinstall

**Reinstall T2 kernel:**
```bash
sudo bash scripts/02_install_t2_kernel.sh
sudo reboot
```

### 2. Check the T2 bridge driver
```bash
lsmod | grep -E '^(t2bce|apple_bce)'
```

If not loaded, see [Keyboard Not Working](#keyboard-not-working).

---

## WiFi Not Working

Wi-Fi needs **both** the T2 kernel (driver) and Apple's firmware. See
[drivers-and-firmware.md](drivers-and-firmware.md).

### Check firmware files
```bash
ls -l /lib/firmware/brcm/ | grep -i apple
```

MacBookPro15,4 files contain `4377b3` and `tahiti`. Files without `apple`
in the name (e.g. the old `brcmfmac4377b3-pcie.bin` from earlier versions
of this repo) are not what current kernels look for.

**If missing:**
```bash
sudo bash scripts/01_install_wifi_bluetooth.sh
```

### Reload WiFi module
```bash
sudo modprobe -r brcmfmac_wcc
sudo modprobe -r brcmfmac
sudo modprobe brcmfmac
```

### Check the kernel log
```bash
sudo journalctl -k --grep=brcmfmac | tail -20
```

Working: a line renaming `wlan0`. Lines saying `failed with error -2` for
other file names are normal fallbacks.

### Arch-based distros (CachyOS, Arch, EndeavourOS)
With wpa_supplicant 2.11+, switch NetworkManager to `iwd`:
```bash
printf '[device]\nwifi.backend=iwd\n' | sudo tee /etc/NetworkManager/conf.d/wifi_backend.conf
sudo systemctl restart NetworkManager
```
or add `brcmfmac.feature_disable=0x82000` to the kernel parameters.

---

## Downloads and Installs Failing

### `sudo: command not found`
Minimal images (Arch WSL, some containers) ship without sudo. As root:
`pacman -S sudo` (Arch) or `apt install sudo` (Debian/Ubuntu), then add
your user to `wheel`/`sudo`. On Zorin/Ubuntu desktop installs, your user
already has sudo; check with `groups`.

### A download "worked" but the file is broken
`curl -s -o file URL` saves an HTML error page when the URL is dead. Always
use `curl -fL` so HTTP errors fail, then check the file:
```bash
file firmware.tar                      # should not say "HTML document"
sha256sum -c <checksum-file>           # when a checksum is published
zstd -t package.pkg.tar.zst            # archive integrity
```

### `Could not resolve host: packages.aunali1.com`
That firmware host is gone. Earlier versions of this repo used it. Pull
this repo again and see [drivers-and-firmware.md](drivers-and-firmware.md).

### apt: `NO_PUBKEY` or `The repository ... is not signed` (T2 repo)
The T2 repo key is missing or saved in the wrong place. Re-add it where
`t2.list` expects it:
```bash
curl -fsSL --compressed https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg | \
    gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg >/dev/null
sudo apt update
```

### apt: `404 Not Found` from `t2-ubuntu-repo/releases/download/<codename>`
The codename in `/etc/apt/sources.list.d/t2.list` doesn't match your Ubuntu
base (e.g. `noble` on Zorin OS 17, which is `jammy`). Check:
```bash
grep UBUNTU_CODENAME /etc/os-release
cat /etc/apt/sources.list.d/t2.list
```
Fix the codename in `t2.list`, then `sudo apt update`.

### pacman: `unknown trust` / `invalid or corrupted package (PGP signature)`
See [custom ISO build problems](#custom-iso-build-problems).

---

## Microphone Not Working

### Test ALSA detection
```bash
arecord -l
```

Should show: `Apple T2 Audio Digital Mic`

**If not showing:**
```bash
sudo bash scripts/fix_mic.sh
sudo reboot
```

### Test recording
```bash
arecord -f cd -d 5 test.wav
aplay test.wav
```

### Check PipeWire
```bash
wpctl status
```

---

## Camera Not Working

### Check device
```bash
ls -l /dev/video*
```

**If /dev/video0 doesn't exist:**
- T2 kernel includes camera support
- Check the bridge driver is loaded: `lsmod | grep -E '^(t2bce|apple_bce)'`
- Reboot if just installed

### Test camera
```bash
sudo apt install cheese
cheese
```

---

## System Won't Boot T2 Kernel

### Check installed kernels
```bash
dpkg -l | grep linux-image
```

### Pick the T2 kernel manually
GRUB boots the highest-numbered kernel. If that's the stock one, hold
**Shift** (or press **Esc**) as GRUB starts → **Advanced options** → the
`-t2-` entry.

**Don't remove the stock kernel to "force" the T2 one** until the T2 kernel
has booted and works. It's your fallback. Once it works:
```bash
sudo bash scripts/06_remove_stock_kernel.sh
```

### T2 kernel boots to a black screen or panics
Pick the stock kernel from **Advanced options**, then check the T2 kernel
installed fully and its initramfs exists:
```bash
ls /boot | grep t2
sudo update-initramfs -u -k all
sudo update-grub
```

---

## Touch Bar Not Showing

Touch Bar support is built into the T2 kernel. If not showing:

1. Verify T2 kernel: `uname -r`
2. Check the bridge driver: `lsmod | grep -E '^(t2bce|apple_bce)'`
3. On current kernels the function-key display comes from `tiny-dfr`:
   `sudo apt install tiny-dfr` (Ubuntu, T2 repo) or `sudo pacman -S tiny-dfr` (Arch-based)
4. Reboot if just installed

---

## Display/GPU Issues

### Check driver
```bash
lspci -k | grep -A 3 VGA
```

Should show: `Kernel driver in use: i915`

### Check OpenGL
```bash
sudo apt install mesa-utils
glxinfo | grep "OpenGL"
```

Should show:
- OpenGL renderer: Intel Iris Plus Graphics 645
- OpenGL version: 4.6

---

## Kernel Parameters Not Applied

### Check current parameters
```bash
cat /proc/cmdline
```

Should include:
- `intel_iommu=on`
- `iommu=pt`
- `pm_async=off`
- `pcie_ports=compat`

**If missing:**
```bash
sudo bash scripts/05_finalize_setup.sh
sudo reboot
```

### Manually add parameters
```bash
sudo nano /etc/default/grub
```

Find line: `GRUB_CMDLINE_LINUX_DEFAULT=`

Add to the end (inside quotes):
```
intel_iommu=on iommu=pt pm_async=off pcie_ports=compat
```

Then:
```bash
sudo update-grub
sudo reboot
```

---

## System Unstable / Random Freezes

This can be caused by suspend/resume issues on T2 Macs.

### Disable suspend
```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

### Re-enable suspend
```bash
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

**Note:** Suspend/resume is not fully stable on T2 Macs running Linux.

---

## CachyOS: Keyboard or Trackpad Stopped After a Kernel Update

CachyOS 7.2 kernels replaced `apple-bce` with `t2bce`. Forum reports (not
confirmed by CachyOS) describe initramfs builds failing when mkinitcpio
config still lists `apple-bce`, and a 7.2.5-1 regression. See
[distros/cachyos.md](distros/cachyos.md#keep-a-fallback-kernel).

1. Boot `linux-cachyos-lts` (or a snapshot) from the boot menu.
2. Check which driver the kernel has and what mkinitcpio asks for:
   ```bash
   lsmod | grep -E '^(t2bce|apple_bce)'
   grep -r 'bce' /etc/mkinitcpio.conf /etc/mkinitcpio.conf.d/
   ```
3. Update and rebuild: `sudo pacman -Syu && sudo mkinitcpio -P`.

---

## Custom ISO Build Problems

| Problem | Fix |
|---|---|
| `sudo: command not found` in Arch WSL | Install sudo and create a wheel user ([guide](custom-iso/cachyos.md#on-wsl2-windows)) |
| Permission/symlink errors or a very slow build in WSL | You're building under `/mnt/c`. Move the build into `~/` |
| `unknown trust` / PGP signature errors | Trust the CachyOS key on the build host ([guide](custom-iso/cachyos.md#2-cachyos-signing-key-only-on-a-non-cachyos-host)) |
| `curl: (22) ... 404` fetching firmware | Dead link. Use the [current sources](drivers-and-firmware.md) |
| `tar`/`zstd` says the archive is invalid | You saved an HTML error page. Use `curl -fL` and check the SHA-256 |

---

## Getting Help

If none of these solutions work:

1. **Run diagnostics:**
   ```bash
   bash scripts/diagnostics.sh
   ```

2. **Check logs:**
   ```bash
   dmesg | grep -i "apple\|bce\|error" | tail -50
   ```

3. **Collect the details** listed in
   [hardware-support.md](hardware-support.md#recording-a-test-result).

4. **Community support:**
   - [t2linux Wiki](https://wiki.t2linux.org)
   - [t2linux Discord](https://discord.gg/68MRhQu)
   - [t2linux GitHub Issues](https://github.com/t2linux/wiki/issues)

5. **Create an issue:**
   - Include output of `diagnostics.sh`
   - Include `uname -r`
   - Include `dmesg` output
   - Describe the problem clearly

---

## Known Limitations

### Touch ID
**Not tested here.** Upstream has an experimental `t2-touchid` package

### Suspend/Resume
**Partially working** - may cause instability on some systems

### Battery Life
May be slightly worse than macOS due to less aggressive power management

### Fan Control
Works but may be louder than macOS

---

## Reset to Stock Ubuntu

See [Uninstall in the Zorin/Ubuntu guide](distros/zorin-ubuntu.md#uninstall).
