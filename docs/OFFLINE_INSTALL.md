# Offline Installation (No Network on the MacBook)

On a fresh Zorin OS install the MacBook's built-in WiFi (BCM4377b3) has no
firmware and the stock kernel has no T2 support. So `apt install` cannot work
unless you have an Ethernet adapter or USB WiFi dongle.

The offline installer fixes this. You download everything on **another
computer**, copy it to a USB stick, and install on the MacBook with no network.

---

## 1. Build the bundle (on a machine WITH internet)

Any Debian/Ubuntu-based system works: another Linux PC, a VM, WSL on Windows,
or a Zorin/Ubuntu live USB on another computer. The script does **not** change
that machine's apt sources or installed packages.

```bash
sudo apt-get install -y curl git gpg dpkg-dev ubuntu-keyring
git clone https://github.com/mxioi/macbookpro15-4-zorin-setup.git
cd macbookpro15-4-zorin-setup
bash scripts/offline/build_offline_bundle.sh ~/
```

This creates `~/t2-offline-bundle-noble-amd64.tar.gz` (about 240 MB). It contains:

| Item | Purpose |
| ---- | ------- |
| `firmware/` | BCM4377b3 WiFi + Bluetooth firmware |
| `debs/` | T2 kernel, build tools + all dependencies (local apt repo) |
| `src/apple-bce-drv` | BCE driver source (built only if the kernel lacks it) |
| `src/t2-better-audio` | Microphone / speaker profiles |
| `keys/` | T2 repo signing key, so `apt upgrade` works once online |
| `repo/` | A copy of this repository's scripts and docs |
| `install.sh` | The offline installer |
| `SHA256SUMS` | Integrity check, verified automatically before install |

Dependencies are resolved as if nothing is installed, so the bundle works on a
fresh system. On the MacBook, apt only installs what is actually missing.

### Options

```bash
# Different target release / kernel flavour
CODENAME=noble T2_KERNEL_PKG=linux-t2-lts bash scripts/offline/build_offline_bundle.sh

# Add extra packages you want available offline (e.g. cheese, mesa-utils)
EXTRA_PACKAGES="cheese mesa-utils" bash scripts/offline/build_offline_bundle.sh
```

---

## 2. Copy to the MacBook

Copy the `.tar.gz` to a USB stick (any filesystem: FAT32, exFAT or ext4 all
work; the file is under 4 GB).

---

## 3. Install (on the MacBook, no network needed)

With an external USB keyboard and mouse connected:

```bash
cd ~
tar -xzf /media/$USER/<USB-NAME>/t2-offline-bundle-noble-amd64.tar.gz
cd t2-offline-bundle-noble-amd64
sudo bash install.sh
sudo reboot
```

After reboot, `uname -r` should contain `-t2-`. The internal keyboard,
trackpad and WiFi should work. Connect to WiFi, then update normally:

```bash
sudo apt update && sudo apt upgrade
```

---

## Notes

- Build the bundle shortly before you use it. If your Zorin install is much
  newer than the bundle, apt simply keeps the newer installed versions.
- The installer logs to `/var/log/macbook-t2-offline-install-*.log`.
- Recent T2 kernels already include the BCE driver (`t2bce_*` modules). In
  that case the installer skips building `apple-bce`, so two drivers do not
  compete for the same device.
- The bundle is for `amd64` Ubuntu 24.04 (noble) based systems such as
  Zorin OS 17.
