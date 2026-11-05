# Quick Reference

Fast command reference for common tasks on **Zorin OS / Ubuntu**. Hardware
checks work on any distro; `apt`/GRUB commands don't. Other distros: see
[docs/distros/](docs/distros/).

---

## Installation

```bash
# One-command install
git clone https://github.com/mxioi/macbookpro15-4-zorin-setup.git
cd macbookpro15-4-zorin-setup
sudo bash scripts/master_install.sh
sudo reboot
```

---

## Diagnostics

```bash
# Full hardware check
bash scripts/diagnostics.sh

# Check kernel
uname -r  # Should include: -t2-

# Check T2 bridge driver loaded (t2bce, or apple_bce on older kernels)
lsmod | grep -E '^(t2bce|apple_bce)'

# Check WiFi
iwconfig

# Check kernel parameters
cat /proc/cmdline
```

---

## Hardware Tests

```bash
# Test microphone (5 second recording)
arecord -f cd -d 5 test.wav && aplay test.wav

# Test camera
sudo apt install cheese && cheese

# List audio devices
arecord -l

# List video devices
ls -l /dev/video*

# Check GPU
glxinfo | grep "OpenGL renderer"
```

---

## Troubleshooting

```bash
# Reload WiFi
sudo modprobe -r brcmfmac_wcc; sudo modprobe -r brcmfmac && sudo modprobe brcmfmac

# Check Wi-Fi firmware loaded
sudo journalctl -k --grep=brcmfmac | tail -5

# Restart audio
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check logs
dmesg | grep -i "apple\|bce\|error" | tail -50
journalctl -b | grep -i "error\|fail" | tail -50
```

---

## Kernel Management

```bash
# List installed kernels
dpkg -l | grep linux-image

# Remove stock kernel - ONLY after the T2 kernel has booted and works
sudo bash scripts/06_remove_stock_kernel.sh

# Update GRUB
sudo update-grub

# Update initramfs
sudo update-initramfs -u -k all
```

---

## Configuration

```bash
# Edit GRUB kernel parameters
sudo nano /etc/default/grub
sudo update-grub

# Configure touchpad via gsettings
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'

# Open touchpad settings GUI
gnome-control-center mouse
```

---

## Maintenance

```bash
# Update system
sudo apt update
sudo apt upgrade

# Nothing to rebuild after a kernel update: the T2 driver is in the kernel.
# If the driver name changed (apple-bce -> t2bce), reconfigure:
sudo bash scripts/03_configure_t2_modules.sh && sudo update-initramfs -u -k all

# Check for T2 kernel updates
sudo apt update
sudo apt list --upgradable | grep t2
```

---

## File Locations

```
# Kernel modules
/lib/modules/$(uname -r)/

# WiFi firmware
/lib/firmware/brcm/

# Module configurations
/etc/modules-load.d/
/etc/modprobe.d/

# Audio configuration
/usr/share/alsa/ucm2/

# GRUB configuration
/etc/default/grub
/boot/grub/grub.cfg
```

---

## Useful Commands

```bash
# Show all input devices
cat /proc/bus/input/devices

# List PCI devices
lspci -k

# List USB devices
lsusb -v

# Monitor kernel messages
sudo dmesg -w

# Monitor audio
wpctl status

# Test Thunderbolt
sudo boltctl list
```

---

## Emergency Recovery

```bash
# Boot with external keyboard/mouse
# At GRUB (hold Shift): "Advanced options" → T2 kernel, or the stock kernel as fallback

# If keyboard doesn't work:
sudo modprobe t2bce_vhci || sudo modprobe apple-bce

# If WiFi doesn't work:
sudo modprobe brcmfmac
```

---

## Useful Links

- **This repo:** https://github.com/mxioi/macbookpro15-4-zorin-setup
- **t2linux wiki:** https://wiki.t2linux.org
- **T2 Ubuntu/Debian Kernel:** https://github.com/t2linux/T2-Debian-and-Ubuntu-Kernel
- **Wi-Fi/Bluetooth firmware guide:** https://wiki.t2linux.org/guides/wifi-bluetooth/
- **t2-better-audio:** https://github.com/kekrby/t2-better-audio
