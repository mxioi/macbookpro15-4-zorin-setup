# Zorin OS / Ubuntu: Manual Installation

Step-by-step version of `scripts/master_install.sh`. These instructions
are **only for Zorin OS, Ubuntu and Ubuntu derivatives** (apt + GRUB). On
CachyOS or other distros, use [the other distro pages](../../README.md#where-to-start).

**Shortcut:** installing from a live USB? [t2kit](../t2kit.md) does Steps
1–4 and 6 from the live session before your first boot.

**Testing status:** tested by the maintainer on a MacBookPro15,4 with Zorin
OS. See [hardware-support.md](../hardware-support.md) for exact versions
and remaining issues.

---

## Prerequisites

- **Fresh Zorin OS or Ubuntu install** on one of the supported Ubuntu bases
  below
- **External USB keyboard and mouse.** The internal ones only work once the T2 kernel is running
- **Internet connection:** Ethernet adapter, USB tethering or a USB Wi-Fi
  dongle. Internal Wi-Fi needs firmware first
- **At least 20GB free disk space**
- **A user with sudo.** On Zorin/Ubuntu the user created during install has it

---

## Step 0: Find your Ubuntu base

The T2 kernel repo is split by Ubuntu release. Using the wrong one installs
packages built for another release. Don't assume `noble`.

```bash
grep -E '^(PRETTY_NAME|UBUNTU_CODENAME|VERSION_CODENAME)=' /etc/os-release
```

Use `UBUNTU_CODENAME` (derivatives such as Zorin and Mint set it). On plain
Ubuntu, `VERSION_CODENAME` is the same thing.

| Your system | Ubuntu base | `CODENAME` |
|---|---|---|
| Zorin OS 17 | 22.04 | `jammy` |
| Zorin OS 18 | 24.04 | `noble` |
| Ubuntu 22.04 / 24.04 / 26.04 / 26.10 | — | `jammy` / `noble` / `resolute` / `stonking` |

If your codename isn't in that list, there is no T2 kernel repo for it.
Check [the upstream list](https://github.com/t2linux/T2-Debian-and-Ubuntu-Kernel#using-the-apt-repo).

```bash
CODENAME=$(. /etc/os-release; echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
echo "$CODENAME"
```

---

## Step 1: Wi-Fi and Bluetooth firmware

**Purpose:** Wi-Fi/Bluetooth need Apple firmware that no distro can ship.
See [drivers-and-firmware.md](../drivers-and-firmware.md) for why.

```bash
sudo apt update
sudo apt install -y curl python3
curl -fL -o /tmp/firmware.sh https://wiki.t2linux.org/tools/firmware.sh
head -1 /tmp/firmware.sh        # should be a bash shebang, not HTML
bash /tmp/firmware.sh           # pick a method from the menu
```

Which menu option:

- macOS still on the disk: **Retrieve the firmware directly from macOS**
- you ran `copy_to_efi` in macOS beforehand: **Retrieve the firmware from the EFI partition**
- macOS removed: **Download a macOS Recovery Image** (choose Monterey, Ventura or Sonoma)

Wi-Fi may only appear after you boot the T2 kernel (Step 6).

---

## Step 2: Add the T2 apt repos and install the T2 kernel

**Purpose:** kernel with trackpad, keyboard, Touch Bar, audio and camera
support. The T2 bridge driver is built in.

```bash
# Common repo + signing key (matches upstream instructions)
curl -fsSL --compressed "https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg" | \
    gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg >/dev/null
sudo curl -fsSL --compressed -o /etc/apt/sources.list.d/t2.list \
    "https://adityagarg8.github.io/t2-ubuntu-repo/t2.list"

# Release-specific repo, using CODENAME from Step 0
echo "deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/${CODENAME} ./" | \
    sudo tee -a /etc/apt/sources.list.d/t2.list

sudo apt update
sudo apt install -y linux-t2-lts

# Confirm it installed
ls /lib/modules | grep t2
```

**Keep your existing stock kernel.** It's your way back if the T2 kernel
doesn't boot. Step 8 removes it once the T2 kernel is proven.

If you upgrade Zorin/Ubuntu to a new release later, update the codename in
`/etc/apt/sources.list.d/t2.list`.

---

## Step 3: Load the T2 bridge driver at boot

**Purpose:** make the internal keyboard and trackpad load automatically.

Don't build `apple-bce` from source. The T2 kernel already contains the
driver, and building against `uname -r` would target the stock kernel
you're still running. Check what the **new** T2 kernel ships instead:

```bash
T2K=$(ls /lib/modules | grep t2 | sort -V | tail -1)
find /lib/modules/$T2K -name 't2bce_vhci.ko*' -o -name 'apple*bce.ko*'
```

If it lists `t2bce_vhci` (current kernels):

```bash
echo t2bce_vhci | sudo tee /etc/modules-load.d/t2.conf
# Early loading, so the keyboard works at a disk-encryption prompt
printf 't2bce_dma\nt2bce_core\nt2bce_vhci\n' | sudo tee -a /etc/initramfs-tools/modules
```

If it lists `apple-bce` (older kernels):

```bash
echo apple-bce | sudo tee /etc/modules-load.d/t2.conf
echo apple-bce | sudo tee -a /etc/initramfs-tools/modules
```

If you followed an older version of this guide, remove its config, which
names a module current kernels don't have:

```bash
sudo rm -f /etc/modules-load.d/apple-bce.conf
```

---

## Step 4: Kernel parameters

```bash
sudo cp /etc/default/grub /etc/default/grub.backup
sudo nano /etc/default/grub
```

Add these inside the quotes of `GRUB_CMDLINE_LINUX_DEFAULT=`:

```text
intel_iommu=on iommu=pt pm_async=off pcie_ports=compat
```

Upstream t2linux currently lists `intel_iommu=on iommu=pt pm_async=off`.
`pcie_ports=compat` was part of the tested setup here and is kept. It
hasn't been re-tested without it.

```bash
sudo update-grub
```

---

## Step 5: T2 audio configuration (microphone)

```bash
cd ~/macbookpro15-4-zorin-setup     # wherever you cloned this repo
sudo bash scripts/fix_mic.sh
```

`fix_mic.sh` installs [kekrby/t2-better-audio](https://github.com/kekrby/t2-better-audio),
which the [t2linux audio guide](https://wiki.t2linux.org/guides/audio-config/)
still recommends.

---

## Step 6: Update initramfs and boot the T2 kernel

```bash
sudo update-initramfs -u -k all
sudo reboot
```

GRUB boots the **highest-numbered** kernel by default. If the stock kernel
is newer than the T2 one, it'll boot instead. To choose:

1. Hold **Shift** (or tap **Esc**) as GRUB starts to show the menu.
2. **Advanced options** → the entry with `-t2-` in its name.

The finalize script warns you when this applies.

---

## Step 7: Verify

```bash
uname -r                                       # must contain -t2-
lsmod | grep -E '^(t2bce|apple_bce)'           # bridge driver loaded
sudo journalctl -k --grep=brcmfmac | tail -5   # Wi-Fi firmware loaded
cat /proc/cmdline | grep -Eo "intel_iommu=on|iommu=pt|pm_async=off|pcie_ports=compat"
bash scripts/diagnostics.sh
```

Then check by hand:

- **Keyboard:** typing, function keys, backlight
- **Trackpad:** move, tap-to-click, two-finger scroll and right-click
- **Touch Bar:** shows keys. On current kernels this may need
  `sudo apt install tiny-dfr` (from the T2 repo)
- **Camera:** `sudo apt install cheese && cheese`
- **Microphone:** `arecord -f cd -d 5 test.wav && aplay test.wav`
- **Wi-Fi:** `nmcli device wifi list`
- **Bluetooth:** `bluetoothctl scan on`

Record what you tested in [hardware-support.md](../hardware-support.md#recording-a-test-result).

---

## Step 8: Remove the stock kernel (only after Step 7 passes)

The stock kernel was kept as a fallback. Once the T2 kernel boots and the
hardware works, removing the stock kernel metapackages stops a newer stock
kernel from being installed and booted ahead of it:

```bash
sudo bash scripts/06_remove_stock_kernel.sh
```

The script refuses to run unless you're on a T2 kernel with the bridge
driver loaded. It lists what it will remove (including HWE metapackages
such as `linux-generic-hwe-22.04`) and asks first.

---

## Touchpad settings

```bash
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'
```

---

## Maintenance

T2 kernels update with the rest of the system:

```bash
sudo apt update && sudo apt upgrade
```

Nothing needs rebuilding after a kernel update; the driver is part of the
kernel. If a new kernel switches from `apple-bce` to `t2bce`, rerun:

```bash
sudo bash scripts/03_configure_t2_modules.sh
sudo update-initramfs -u -k all
```

---

## Uninstall

```bash
sudo apt install linux-generic           # stock kernel back (Zorin 17: linux-generic-hwe-22.04)
sudo rm -f /etc/modules-load.d/t2.conf /etc/modules-load.d/apple-bce.conf
sudo rm -f /etc/modprobe.d/blacklist-applespi.conf
sudo sed -i '/^# T2 MacBook keyboard/,/^# end T2$/d' /etc/initramfs-tools/modules
sudo cp /etc/default/grub.backup /etc/default/grub   # or grub.backup.t2 if you used the scripts
sudo update-grub
sudo reboot                              # boot the stock kernel, then:
sudo apt remove linux-t2-lts
```

The internal keyboard and trackpad will **not** work on the stock kernel.
