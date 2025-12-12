# Manual Installation Guide

Step-by-step guide for installing each component manually.

---

## Prerequisites

- **Fresh Zorin OS 17 installation** (based on Ubuntu 24.04)
- **External USB keyboard and mouse** (internal won't work initially)
- **Internet connection** (Ethernet or USB WiFi dongle)
- **At least 20GB free disk space**

---

## Installation Steps

### Step 1: Install WiFi and Bluetooth Firmware

**Purpose:** Get WiFi working so you can disconnect Ethernet

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install required tools
sudo apt install -y curl git build-essential

# Create firmware directory
sudo mkdir -p /lib/firmware/brcm

# Download WiFi firmware
sudo curl -sL -o /lib/firmware/brcm/brcmfmac4377b3-pcie.bin \
    "https://packages.aunali1.com/apple/wifi-fw/18G2022/brcmfmac4377b3-pcie.bin"

sudo curl -sL -o /lib/firmware/brcm/brcmfmac4377b3-pcie.apple,tahiti-SPPR-m-4c.txt \
    "https://packages.aunali1.com/apple/wifi-fw/18G2022/brcmfmac4377b3-pcie.apple,tahiti-SPPR-m-4c.txt"

sudo curl -sL -o /lib/firmware/brcm/brcmfmac4377b3-pcie.clm_blob \
    "https://packages.aunali1.com/apple/wifi-fw/18G2022/brcmfmac4377b3-pcie.clm_blob"

# Download Bluetooth firmware
sudo curl -sL -o /lib/firmware/brcm/BCM4377B3.hcd \
    "https://packages.aunali1.com/apple/wifi-fw/18G2022/BCM4377B3.hcd"

# Reload WiFi module
sudo modprobe -r brcmfmac
sudo modprobe brcmfmac

# Test WiFi
nmcli device wifi list
```

✅ **WiFi should now work!** Connect to your network.

---

### Step 2: Install T2 Kernel

**Purpose:** Get kernel with trackpad, Touch Bar, and camera support

```bash
# Add T2 kernel repository
CODENAME="noble"
curl -s --compressed "https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg" | \
    gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg >/dev/null

sudo curl -s --compressed -o /etc/apt/sources.list.d/t2.list \
    "https://adityagarg8.github.io/t2-ubuntu-repo/t2.list"

echo "deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/${CODENAME} ./" | \
    sudo tee -a /etc/apt/sources.list.d/t2.list

# Update and install
sudo apt update
sudo apt install -y linux-t2-lts

# Verify installation
dpkg -l | grep linux-image-.*t2
```

**DO NOT REBOOT YET** - Need to install apple-bce first!

---

### Step 3: Install Apple BCE Driver

**Purpose:** Enable keyboard and trackpad communication via T2 chip

```bash
# Install build dependencies
sudo apt install -y git build-essential linux-headers-$(uname -r)

# Clone repository
cd /tmp
git clone https://github.com/t2linux/apple-bce-drv.git
cd apple-bce-drv

# Build
make clean
make

# Install
sudo make install
sudo depmod -a

# Configure auto-load
sudo tee /etc/modules-load.d/apple-bce.conf << 'EOF'
# Apple BCE Driver - T2 Chip Support
apple-bce
EOF

# Blacklist conflicting driver
sudo tee /etc/modprobe.d/blacklist-applespi.conf << 'EOF'
# Blacklist applespi - conflicts with apple-bce
blacklist applespi
EOF

# Load module now
sudo modprobe apple-bce
```

✅ **Internal keyboard should now work!**

---

### Step 4: Add Kernel Parameters

**Purpose:** Required for T2 hardware to function properly

```bash
# Backup GRUB config
sudo cp /etc/default/grub /etc/default/grub.backup

# Edit GRUB config
sudo nano /etc/default/grub
```

Find the line starting with `GRUB_CMDLINE_LINUX_DEFAULT=`

Add these parameters inside the quotes:
```
intel_iommu=on iommu=pt pcie_ports=compat
```

Example:
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on iommu=pt pcie_ports=compat"
```

Save and exit (Ctrl+X, Y, Enter)

```bash
# Update GRUB
sudo update-grub
```

---

### Step 5: Force T2 Kernel Boot

**Purpose:** Ensure system boots T2 kernel, not stock kernel

```bash
# Remove stock Ubuntu kernels
sudo apt remove -y --purge linux-image-generic linux-headers-generic
sudo apt autoremove -y --purge

# Update GRUB
sudo update-grub

# Verify only T2 kernel remains
dpkg -l | grep linux-image
```

Should only show the T2 kernel (6.12.x-t2-noble)

---

### Step 6: Install T2 Audio Configuration

**Purpose:** Enable microphone

```bash
# Clone and install
cd /tmp
git clone https://github.com/kekrby/t2-better-audio.git
cd t2-better-audio
sudo ./install.sh

# Restart audio services
systemctl --user restart pipewire pipewire-pulse wireplumber
```

---

### Step 7: Update Initramfs and Reboot

**Purpose:** Apply all changes

```bash
# Update initramfs
sudo update-initramfs -u -k all

# Reboot
sudo reboot
```

---

## After Reboot

### Verify Installation

```bash
# Check kernel
uname -r
# Should show: 6.12.x-x-t2-noble

# Check apple-bce
lsmod | grep apple_bce

# Check WiFi
iwconfig

# Check kernel parameters
cat /proc/cmdline | grep -o "intel_iommu=on iommu=pt pcie_ports=compat"
```

### Test Hardware

**Keyboard:**
- Type something
- Test function keys (Fn+F1, Fn+F2, etc.)
- Test keyboard backlight (Fn+F5, Fn+F6)

**Trackpad:**
- Move cursor
- Tap to click
- Two-finger scroll
- Two-finger right-click

**Touch Bar:**
- Should display function keys
- Should be illuminated

**Camera:**
```bash
sudo apt install cheese
cheese
```

**Microphone:**
```bash
arecord -f cd -d 5 test.wav
aplay test.wav
```

**WiFi:**
```bash
nmcli device wifi list
nmcli device wifi connect "SSID" password "PASSWORD"
```

---

## Configure Touchpad Gestures

```bash
# Via GNOME Settings
gnome-control-center mouse

# Or via command line
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'
```

---

## Optional: Install Additional Software

```bash
# Video player with hardware acceleration
sudo apt install mpv

# Better file manager
sudo apt install nautilus-admin

# Screenshot tool
sudo apt install flameshot

# System monitor
sudo apt install htop

# Video editing
sudo apt install kdenlive
```

---

## Troubleshooting

If anything doesn't work, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Quick diagnostics:
```bash
bash ~/macbookpro15-4-zorin-setup/scripts/diagnostics.sh
```

---

## Maintenance

### Update T2 Kernel

The T2 kernel updates automatically with `apt upgrade`:

```bash
sudo apt update
sudo apt upgrade
```

### Rebuild apple-bce After Kernel Update

If the kernel updates, you may need to rebuild apple-bce:

```bash
cd /tmp/apple-bce-drv
git pull
make clean
make
sudo make install
sudo depmod -a
sudo modprobe -r apple-bce
sudo modprobe apple-bce
```

---

## Uninstall

To revert to stock Ubuntu:

```bash
# Install stock kernel
sudo apt install linux-image-generic linux-headers-generic

# Remove T2 kernel
sudo apt remove linux-t2-lts

# Remove apple-bce
cd /tmp/apple-bce-drv
sudo make uninstall

# Remove configurations
sudo rm /etc/modules-load.d/apple-bce.conf
sudo rm /etc/modprobe.d/blacklist-applespi.conf

# Restore GRUB
sudo cp /etc/default/grub.backup /etc/default/grub
sudo update-grub

# Reboot
sudo reboot
```

**Note:** Internal keyboard and trackpad will NOT work on stock kernel.
