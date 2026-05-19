# MacBookPro15,4 Zorin OS Complete Setup

Complete automated setup for **MacBookPro15,4 (2019 13" with Touch Bar)** running **Zorin OS 17 / Ubuntu 24.04**.

This repository gets **all hardware working** on your T2 MacBook, including keyboard, trackpad, Touch Bar, camera, microphone, WiFi, and Bluetooth.

---

## ✅ What Works After Setup

| Hardware | Status | Notes |
|----------|--------|-------|
| ✅ Keyboard | Working | Function keys, backlight |
| ✅ Trackpad | Working | Full multitouch gestures |
| ✅ Touch Bar | Working | Function keys display |
| ✅ Speakers | Working | T2 audio output |
| ✅ Microphone | Working | Built-in mic |
| ✅ Camera | Working | FaceTime HD 720p |
| ✅ WiFi | Working | BCM4377b3 |
| ✅ Bluetooth | Working | BRCM4377 |
| ✅ Display/GPU | Working | Intel Iris Plus 645, hardware acceleration |
| ✅ Thunderbolt 3 | Working | All 4 USB-C ports |
| ✅ USB-C Charging | Working | Any port |
| ❌ Touch ID | Not supported | Locked to macOS by T2 chip |

---

## 🚀 Quick Start (Fresh Install)

### Prerequisites

1. **Install Zorin OS 17** (based on Ubuntu 24.04)
2. **Boot with external USB keyboard and mouse** (internal keyboard/trackpad won't work initially)
3. **Connect to internet** via Ethernet adapter or USB WiFi dongle

### One-Command Installation

```bash
git clone https://github.com/YOUR_USERNAME/macbookpro15-4-zorin-setup.git
cd macbookpro15-4-zorin-setup
sudo bash scripts/master_install.sh
```

**Then reboot.** Everything will work!

---

## 📋 What Gets Installed

### 1. T2 Kernel
- Patched kernel with T2 hardware support
- Trackpad/touchpad drivers
- Touch Bar support
- Camera support
- Source: [t2linux/T2-Ubuntu-Kernel](https://github.com/t2linux/T2-Ubuntu-Kernel)

### 2. Apple BCE Driver
- T2 chip communication driver
- Keyboard and trackpad via virtual USB host controller
- Audio support
- Source: [t2linux/apple-bce-drv](https://github.com/t2linux/apple-bce-drv)

### 3. WiFi Firmware (BCM4377b3)
- Broadcom WiFi firmware extraction
- Bluetooth firmware
- Source: [t2linux WiFi guide](https://wiki.t2linux.org/guides/wifi-bluetooth/)

### 4. T2 Audio Configuration
- UCM (Use Case Manager) profiles
- PipeWire configuration
- Microphone DSP settings
- Source: [kekrby/t2-better-audio](https://github.com/kekrby/t2-better-audio)

### 5. Kernel Parameters
- `intel_iommu=on`
- `iommu=pt`
- `pm_async=off`
- `pcie_ports=compat`

---

## 📖 Manual Installation (Step-by-Step)

If you prefer to understand each step, see [docs/MANUAL_INSTALL.md](docs/MANUAL_INSTALL.md).

---

## 🛠️ Individual Scripts

Located in `scripts/` directory:

| Script | Purpose |
|--------|---------|
| `master_install.sh` | ⭐ Run everything automatically |
| `01_install_wifi_bluetooth.sh` | WiFi and Bluetooth firmware |
| `02_install_t2_kernel.sh` | T2-patched kernel |
| `03_install_apple_bce.sh` | T2 keyboard/trackpad driver |
| `04_setup_t2_audio.sh` | Microphone configuration (wrapper) |
| `fix_mic.sh` | Direct microphone fix/apply |
| `05_finalize_setup.sh` | Kernel parameters, cleanup |
| `diagnostics.sh` | Check hardware status |

---

## 🔧 Post-Installation

### Verify Everything Works

```bash
./scripts/diagnostics.sh
```

### Configure Trackpad Gestures

Settings → Mouse & Touchpad → Touchpad:
- ✅ Tap to click
- ✅ Natural scrolling
- ✅ Two-finger scrolling
- ✅ Two-finger right-click

### Test Microphone

```bash
arecord -f cd -d 5 test.wav
aplay test.wav
```

Or: Settings → Sound → Input → Test microphone

### Test Camera

```bash
sudo apt install cheese
cheese
```

---

## 🐛 Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions.

Quick checks:

```bash
# Check kernel version
uname -r
# Should include: -t2-

# Check apple-bce is loaded
lsmod | grep apple_bce

# Check WiFi firmware
dmesg | grep -i brcmfmac

# Full diagnostics
./scripts/diagnostics.sh
```

---

## 📚 Documentation

- [Manual Installation Guide](docs/MANUAL_INSTALL.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [Hardware Reference](docs/HARDWARE_REFERENCE.md)
- [Kernel Parameters](docs/KERNEL_PARAMETERS.md)

---

## 🙏 Credits

This setup is based on the amazing work of:

- **[t2linux](https://github.com/t2linux)** - T2 Linux support project
- **[Aditya Garg](https://github.com/AdityaGarg8)** - T2 Ubuntu kernel maintainer
- **[MCMrARM](https://github.com/MCMrARM)** - Original apple-bce driver
- **[kekrby](https://github.com/kekrby)** - t2-better-audio configuration
- **[t2linux wiki](https://wiki.t2linux.org)** - Comprehensive documentation

---

## 💻 Tested On

- **Model**: MacBookPro15,4 (2019 13" with Touch Bar)
- **CPU**: Intel Core i5-8257U (Coffee Lake)
- **GPU**: Intel Iris Plus Graphics 645
- **RAM**: 8GB/16GB
- **Storage**: 256GB/512GB NVMe SSD
- **OS**: Zorin OS 17 (Ubuntu 24.04 Noble)
- **Kernel**: Any current `*-t2-*` build for Noble

Should also work on:
- MacBookPro15,1 (2018 15" with Touch Bar)
- MacBookPro15,2 (2018 13" with Touch Bar)
- MacBookPro15,3 (2019 15" with Touch Bar)
- MacBookPro16,1 (2019 16")
- Other T2 MacBooks with minor adjustments

---

## 📄 License

MIT License - Feel free to use, modify, and distribute.

---

## 🤝 Contributing

Improvements welcome! Please open an issue or pull request.

---

## ⚠️ Disclaimer

This setup modifies your system kernel and drivers. While tested and working, use at your own risk. Always backup your data before making system changes.

---

**Enjoy your fully functional MacBook running Zorin OS!** 🎉
