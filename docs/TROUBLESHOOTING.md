# Troubleshooting Guide

Common issues and solutions for MacBookPro T2 on Zorin OS.

---

## Keyboard Not Working

### Check if apple-bce is loaded
```bash
lsmod | grep apple_bce
```

**If not loaded:**
```bash
sudo modprobe apple-bce
```

**If module not found:**
```bash
cd /tmp/apple-bce-drv
sudo make clean
sudo make
sudo make install
sudo depmod -a
sudo modprobe apple-bce
```

---

## Trackpad Not Working

### 1. Verify T2 Kernel
```bash
uname -r
```

Must include: `-t2-`

**If showing 6.14.x-generic:**
- Stock Ubuntu kernel does NOT support trackpad
- Boot into T2 kernel or reinstall

**Reinstall T2 kernel:**
```bash
sudo bash scripts/02_install_t2_kernel.sh
sudo reboot
```

### 2. Check apple-bce
```bash
lsmod | grep apple_bce
```

If not loaded:
```bash
sudo modprobe apple-bce
```

---

## WiFi Not Working

### Check firmware files
```bash
ls -l /lib/firmware/brcm/brcmfmac4377b3*
```

**If missing:**
```bash
sudo bash scripts/01_install_wifi_bluetooth.sh
```

### Reload WiFi module
```bash
sudo modprobe -r brcmfmac
sudo modprobe brcmfmac
```

### Check dmesg for errors
```bash
dmesg | grep -i brcmfmac | tail -20
```

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
- Check if apple-bce is loaded
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

### Remove stock kernels
```bash
sudo apt remove --purge linux-image-generic linux-headers-generic
sudo apt autoremove
sudo update-grub
sudo reboot
```

### Set T2 kernel as default
Use `sudo grub-set-default` with your currently installed T2 kernel menu entry.

```bash
sudo update-grub
sudo reboot
```

---

## Touch Bar Not Showing

Touch Bar support is built into the T2 kernel. If not showing:

1. Verify T2 kernel: `uname -r`
2. Check apple-bce: `lsmod | grep apple_bce`
3. Reboot if just installed

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

3. **Community support:**
   - [t2linux Wiki](https://wiki.t2linux.org)
   - [t2linux Discord](https://discord.gg/68MRhQu)
   - [t2linux GitHub Issues](https://github.com/t2linux/wiki/issues)

4. **Create an issue:**
   - Include output of `diagnostics.sh`
   - Include `uname -r`
   - Include `dmesg` output
   - Describe the problem clearly

---

## Known Limitations

### Touch ID
**NOT supported** - locked to macOS by T2 Secure Enclave

### Suspend/Resume
**Partially working** - may cause instability on some systems

### Battery Life
May be slightly worse than macOS due to less aggressive power management

### Fan Control
Works but may be louder than macOS

---

## Reset to Stock Ubuntu

If you need to revert:

```bash
# Add Ubuntu repository back
sudo apt-add-repository main

# Install stock kernel
sudo apt install linux-image-generic linux-headers-generic

# Remove T2 kernel
sudo apt remove linux-t2-lts

# Update GRUB
sudo update-grub
sudo reboot
```

**Note:** Internal keyboard and trackpad will NOT work on stock kernel.
