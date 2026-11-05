# Hardware Support and Testing Status

What has actually been tested, on which distro and kernel, and what is
still broken. Instructions that haven't been tested on real hardware say
so.

---

## Testing Status by Distro

| Distro | Status | Tested on | Kernel | Guide |
|---|---|---|---|---|
| Zorin OS / Ubuntu | ✅ Tested by maintainer | MacBookPro15,4, Zorin OS (version not recorded, see note) | `linux-t2-lts` (exact version not recorded) | [distros/zorin-ubuntu.md](distros/zorin-ubuntu.md) |
| CachyOS | 🚧 ISO build in progress; hardware testing pending | — | — | [distros/cachyos.md](distros/cachyos.md), [custom-iso/cachyos.md](custom-iso/cachyos.md) |
| Other distros | ℹ️ Not tested here. Follow t2linux | — | — | [distros/other.md](distros/other.md) |

**Note on the Zorin result:** earlier versions of this repo said "Zorin OS
17 (Ubuntu 24.04)". Zorin OS 17 is based on Ubuntu 22.04 (`jammy`). Zorin
OS 18 is based on 24.04 (`noble`). The exact release and kernel used for
the test weren't recorded. They'll be filled in on the next re-test using
the commands below.

### Recording a test result

Run these on the machine and paste the output into the table (or an issue):

```bash
cat /sys/class/dmi/id/product_name          # model, e.g. MacBookPro15,4
grep -E '^(PRETTY_NAME|UBUNTU_CODENAME)=' /etc/os-release
uname -r                                    # kernel
lsmod | grep -E '^(t2bce|apple_bce)'        # bridge driver in use
bash scripts/diagnostics.sh
```

For a custom ISO, also record the ISO build revision (see
[custom-iso/cachyos.md](custom-iso/cachyos.md)).

---

## Component Status: MacBookPro15,4 on Zorin OS (maintainer test)

| Component | Status | Driver | Remaining issues |
|---|---|---|---|
| Keyboard, backlight | ✅ Working | `t2bce` / `apple-bce` | — |
| Trackpad | ✅ Working | T2 kernel | — |
| Touch Bar | ✅ Working | T2 kernel | Function-key display may need `tiny-dfr` on current kernels (not re-tested) |
| Speakers | ✅ Working | T2 bridge audio | — |
| Microphone | ✅ Working | T2 bridge audio + UCM config | Needs `fix_mic.sh` |
| Camera | ✅ Working | T2 bridge | — |
| Wi-Fi | ✅ Working | `brcmfmac` + Apple firmware | Firmware must be supplied by you (see [drivers-and-firmware.md](drivers-and-firmware.md)) |
| Bluetooth | ✅ Working | `hci_bcm4377` + Apple firmware | As Wi-Fi |
| Display/GPU | ✅ Working | `i915` | — |
| Thunderbolt 3 / USB-C | ✅ Working | `thunderbolt` | — |
| Suspend/resume | ⚠️ Unstable | — | May freeze; see troubleshooting |
| Touch ID | ❌ Not working | — | Upstream `t2-touchid` exists; not tested here |

Other T2 models (MacBookPro15,1/15,2/15,3/16,x, MacBookAir, iMac) are
**untested here**. They use different Wi-Fi chips and firmware. Check
[t2linux](https://wiki.t2linux.org/) before following this repo on them.

---

## MacBookPro15,4 Specifications

**Model:** MacBookPro15,4 (2019 13" with Touch Bar, two Thunderbolt 3 ports, A2159)

### Processor
- **CPU:** Intel Core i5-8257U / i7-8557U (Coffee Lake)
- **Cores:** 4 cores, 8 threads
- **Base Clock:** 1.4 GHz (i5) / 1.7 GHz (i7)
- **Turbo Clock:** Up to 3.9 GHz (i5) / 4.5 GHz (i7)
- **TDP:** 15W

### Graphics
- **iGPU:** Intel Iris Plus Graphics 645
- **Execution Units:** 48 EUs
- **Memory:** Shared system RAM
- **Display Output:** Thunderbolt 3 (DisplayPort 1.4)

### Display
- **Size:** 13.3" diagonal
- **Resolution:** 2560 x 1600 (WQXGA)
- **PPI:** 227 pixels per inch
- **Technology:** IPS LED-backlit
- **Color:** P3 wide color gamut
- **Brightness:** 500 nits

### Memory
- **Type:** LPDDR3
- **Speed:** 2133 MHz
- **Capacity:** 8GB or 16GB
- **Soldered:** Yes (not upgradeable)

### Storage
- **Type:** NVMe PCIe 3.0 SSD
- **Capacity:** 256GB, 512GB, 1TB, 2TB
- **Controller:** Apple T2 chip

### Connectivity
- **Thunderbolt 3:** 2× USB-C ports (both on the left; the four-port 13" is MacBookPro15,2)
  - Power Delivery
  - DisplayPort 1.4
  - USB 3.1 Gen 2 (10 Gbps)
  - Thunderbolt 3 (40 Gbps)
- **WiFi:** Broadcom BCM4377b3 (802.11ac), firmware module `tahiti`
- **Bluetooth:** Broadcom BRCM4377 (Bluetooth 5.0)
- **Audio Jack:** 3.5mm combo (TRRS)

### Input
- **Keyboard:** Magic Keyboard (2019, scissor switch)
- **Trackpad:** Force Touch trackpad
- **Touch Bar:** OLED multitouch strip
- **Touch ID:** Fingerprint sensor (NOT supported in Linux)

### Audio
- **Speakers:** Stereo speakers
- **Microphones:** 3-microphone array
- **Controller:** Apple T2 chip

### Camera
- **Type:** FaceTime HD Camera
- **Resolution:** 720p
- **Controller:** Apple T2 chip

### Battery
- **Capacity:** 58.2 Wh
- **Type:** Lithium-polymer
- **Charging:** USB-C Power Delivery (either port)

### Apple T2 Chip
Custom Apple Silicon security coprocessor that controls:
- Storage controller (NVMe)
- System Management Controller (SMC)
- Image Signal Processor (camera)
- Audio controller (speakers, microphone)
- Secure Enclave (Touch ID, encryption)
- Boot security

---

---

## Performance and Power (approximate)

These figures were not measured with a recorded method. Treat them as rough guides only.

### Performance

### Geekbench 5 (Approximate)

| Metric | macOS | Linux |
|--------|-------|-------|
| Single-Core | ~950 | ~920 (97%) |
| Multi-Core | ~3600 | ~3500 (97%) |
| OpenCL (iGPU) | ~7500 | ~7000 (93%) |

**Linux performance is comparable to macOS.**

---

### Power Consumption

### Idle
- **macOS:** ~3-4W
- **Linux:** ~4-5W

### Light Use (Web browsing)
- **macOS:** ~8-10W
- **Linux:** ~10-12W

### Heavy Use (Compilation)
- **macOS:** ~25-30W
- **Linux:** ~25-30W

**Battery life on Linux is typically 70-80% of macOS.**

---

### Thermal Management

### Throttling
- **CPU:** Throttles at 100°C (same as macOS)
- **Fan:** Kicks in around 60-65°C
- **Max RPM:** ~7200 RPM

### Linux vs macOS
- Linux may run slightly warmer at idle
- Fan curve is less aggressive than macOS
- Under load, thermals are similar

---

## Known Hardware Quirks

### T2 Chip Communication
- All internal devices go through T2 chip
- Requires the T2 bridge driver (`t2bce`, formerly `apple-bce`) for access
- Some devices appear as USB over virtual host controller

### Suspend Issues
- T2 chip doesn't properly reinitialize after suspend
- May cause system hangs
- Recommendation: Disable suspend or use hibernate

### Firmware Updates
- T2 firmware updates require macOS
- Keep a macOS partition for firmware updates

---

## Recommended BIOS Settings

**Note:** MacBooks don't have traditional BIOS. These are managed through macOS recovery:

1. **Startup Security Utility:**
   - Security: No Security / Reduced Security
   - Allow booting from external media: Enabled

2. **Startup Disk:**
   - Select your Linux installation

---

## Additional Resources

- **Detailed Specs:** [Apple MacBookPro15,4](https://support.apple.com/kb/SP795)
- **t2linux Wiki:** [https://wiki.t2linux.org](https://wiki.t2linux.org)
- **EveryMac:** [MacBookPro15,4 Details](https://everymac.com/systems/apple/macbook_pro/specs/macbook-pro-core-i5-1.4-quad-core-13-2019-touch-bar-2-thunderbolt-3-ports-specs.html)
- **t2linux hardware support:** [wiki.t2linux.org/state](https://wiki.t2linux.org/state/)
