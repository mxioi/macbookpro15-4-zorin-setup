# Quick Reference

Fast command reference for common tasks.

---

## Installation

```bash
# One-command install
git clone https://github.com/YOUR_USERNAME/macbookpro15-4-zorin-setup.git
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

# Check apple-bce loaded
lsmod | grep apple_bce

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
sudo modprobe -r brcmfmac && sudo modprobe brcmfmac

# Reload apple-bce
sudo modprobe -r apple-bce && sudo modprobe apple-bce

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

# Remove stock kernel (if T2 kernel installed)
sudo apt remove --purge linux-image-generic linux-headers-generic
sudo apt autoremove

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

# Rebuild apple-bce (after kernel update)
cd /tmp/apple-bce-drv
git pull
make clean && make
sudo make install
sudo depmod -a
sudo modprobe -r apple-bce && sudo modprobe apple-bce

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
# At GRUB: Select "Advanced options" → T2 kernel

# If keyboard doesn't work:
sudo modprobe apple-bce

# If WiFi doesn't work:
sudo modprobe brcmfmac

# If nothing works, boot from USB and:
sudo chroot /mnt
cd /tmp/apple-bce-drv
make clean && make && make install
exit
reboot
```

---

## Useful Links

- **This repo:** https://github.com/YOUR_USERNAME/macbookpro15-4-zorin-setup
- **t2linux wiki:** https://wiki.t2linux.org
- **T2 Ubuntu Kernel:** https://github.com/t2linux/T2-Ubuntu-Kernel
- **apple-bce driver:** https://github.com/t2linux/apple-bce-drv
- **t2-better-audio:** https://github.com/kekrby/t2-better-audio
