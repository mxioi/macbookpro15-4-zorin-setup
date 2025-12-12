# Hardware Reference - MacBookPro15,4

Complete hardware specifications and Linux compatibility status.

---

## MacBookPro15,4 Specifications

**Model:** MacBookPro15,4 (2019 13" with Touch Bar)

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
- **Thunderbolt 3:** 4× USB-C ports
  - Power Delivery
  - DisplayPort 1.4
  - USB 3.1 Gen 2 (10 Gbps)
  - Thunderbolt 3 (40 Gbps)
- **WiFi:** Broadcom BCM4377b3 (802.11ac)
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
- **Charging:** USB-C Power Delivery (any of 4 ports)

### Apple T2 Chip
Custom Apple Silicon security coprocessor that controls:
- Storage controller (NVMe)
- System Management Controller (SMC)
- Image Signal Processor (camera)
- Audio controller (speakers, microphone)
- Secure Enclave (Touch ID, encryption)
- Boot security

---

## Linux Compatibility Matrix

### ✅ Fully Working

| Component | Driver | Notes |
|-----------|--------|-------|
| CPU | intel_pstate | Full frequency scaling |
| iGPU | i915 | Hardware acceleration, 4K output |
| Display | i915 | Full resolution, brightness control |
| NVMe SSD | nvme | Full speed (via T2 bridge) |
| Keyboard | apple-bce | All keys, backlight |
| Trackpad | apple-bce + T2 kernel | Multitouch gestures |
| Touch Bar | apple-bce + T2 kernel | Function keys display |
| Speakers | apple-bce | Full audio output |
| Microphone | apple-bce + UCM | 3-mic array |
| Camera | apple-bce | 720p video |
| WiFi | brcmfmac | Full speed, 5GHz support |
| Bluetooth | hci_bcm4377 | Full functionality |
| Thunderbolt 3 | thunderbolt | All 4 ports, daisy chaining |
| USB-C | xhci_hcd | Power, data, display |
| Battery | ACPI | Charge status, percentage |
| Lid Switch | ACPI | Suspend on close (unstable) |
| Power Button | ACPI | Shutdown/sleep |

### ⚠️ Partially Working

| Component | Status | Notes |
|-----------|--------|-------|
| Suspend/Resume | Unstable | May cause freezes on some systems |
| Fan Control | Works | May be louder than macOS |
| Battery Life | Reduced | ~70-80% of macOS battery life |

### ❌ Not Working

| Component | Status | Notes |
|-----------|--------|-------|
| Touch ID | Not supported | Locked to macOS by Secure Enclave |
| eGPU | Untested | Should work via Thunderbolt 3 |
| Target Display | N/A | Not available on this model |

---

## Performance Comparison

### Geekbench 5 (Approximate)

| Metric | macOS | Linux |
|--------|-------|-------|
| Single-Core | ~950 | ~920 (97%) |
| Multi-Core | ~3600 | ~3500 (97%) |
| OpenCL (iGPU) | ~7500 | ~7000 (93%) |

**Linux performance is comparable to macOS.**

---

## Power Consumption

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

## Thermal Management

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
- Requires `apple-bce` driver for access
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
- **EveryMac:** [MacBookPro15,4 Details](https://everymac.com/systems/apple/macbook_pro/specs/macbook-pro-core-i5-1.4-iris-plus-645-13-mid-2019-four-thunderbolt-3-ports-specs.html)
