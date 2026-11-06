# Custom CachyOS ISO with T2 Wi-Fi firmware

> **Status: ISO build in progress; hardware testing pending.** These steps
> document the build process. Booting the USB and checking Wi-Fi,
> Bluetooth, keyboard and trackpad hasn't been done yet. Results will go
> in [hardware-support.md](../hardware-support.md) with the ISO revision.

**You may not need a custom ISO.** [t2kit](../t2kit.md) gives any live ISO
Wi-Fi from a firmware copy kept on the same USB stick, and sets up the
installed system afterwards. Build a custom ISO only if you want the
firmware baked into one image.

The official CachyOS ISO has T2 drivers but no Apple Wi-Fi firmware (it
can't be redistributed). This builds your own ISO with the firmware added,
so Wi-Fi works in the live installer without Ethernet.

**Keep the ISO to yourself.** It contains Apple firmware, which you may not
redistribute. Don't upload or share it.

---

## 1. Build machine

You need an **Arch-based** system: CachyOS, Arch, or Arch on WSL2. The
build uses `pacman`, `archiso` and CachyOS's own repos.

### On WSL2 (Windows)

- **Work inside the Linux filesystem** (`~/`, i.e. `\\wsl$\<distro>\home\<you>`),
  **not** under `/mnt/c/...`. The Windows drive doesn't keep Linux
  permissions, symlinks or case-sensitive names properly, and is much
  slower. mkarchiso needs all of that.
- Fresh Arch WSL images often have **no `sudo`** and only a root user. The
  build script calls `sudo`, so set it up once, as root:

  ```bash
  pacman -Syu --needed sudo
  useradd -m -G wheel builder && passwd builder
  echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel && chmod 440 /etc/sudoers.d/wheel
  su - builder
  ```

- When finished, copy the ISO to Windows with
  `cp out/*.iso /mnt/c/Users/<you>/Downloads/`.

## 2. CachyOS signing key (only on a non-CachyOS host)

The ISO profile's `pacman.conf` pulls from the CachyOS repos with
`SigLevel = Required`. On plain Arch or Arch WSL, your host keyring must
trust the CachyOS key, or the build stops with "unknown trust" /
"invalid or corrupted package (PGP signature)":

```bash
sudo pacman-key --init                # fresh WSL images may not have a keyring yet
sudo pacman-key --populate archlinux
sudo pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key F3B607488DB35A47
```

The key ID comes from CachyOS's own `cachyos-repo.sh`. On CachyOS itself
skip this step; the key is already trusted.

If you see signature errors on a host that *had* the key, refresh the
keyrings: `sudo pacman -Sy archlinux-keyring` (plus `cachyos-keyring` on
CachyOS).

## 3. Build tools and source

```bash
sudo pacman -S --needed archiso mkinitcpio-archiso git squashfs-tools grub
git clone https://github.com/cachyos/cachyos-live-iso.git ~/cachyos-archiso
cd ~/cachyos-archiso
git rev-parse --short HEAD     # write this down: it's the ISO build revision
```

Note: `buildiso.sh` patches `/usr/bin/mkarchiso` on your build machine
(it uses `sudo sed` to disable an Arch keyring timer in the image). That
is upstream behaviour. Reinstall `archiso` afterwards if you want the
original back.

## 4. Get the firmware

Use **one** of these. See [drivers-and-firmware.md](../drivers-and-firmware.md)
for background.

**A. From your own macOS (preferred).** In macOS, run the t2linux script
and pick the **tarball** method. It creates `~/Downloads/firmware.tar`.
Copy that to the build machine.

```bash
curl -fL -o ~/firmware.sh https://wiki.t2linux.org/tools/firmware.sh
bash ~/firmware.sh      # in macOS, choose the tar option
```

**B. Versioned package from GitHub.** Download, then **check the checksum
before using it**:

```bash
mkdir -p ~/t2-fw && cd ~/t2-fw
curl -fL -o apple-bcm-firmware-14.0-1-any.pkg.tar.zst \
  https://github.com/NoaHimesaka1873/apple-bcm-firmware/releases/download/v14.0/apple-bcm-firmware-14.0-1-any.pkg.tar.zst
echo "f2cd47d9e3fb9658f16997b2d9ace3033b57925b8c6ddd86ccc3d07d0c3e9559  apple-bcm-firmware-14.0-1-any.pkg.tar.zst" | sha256sum -c -
zstd -t apple-bcm-firmware-14.0-1-any.pkg.tar.zst
```

`-f` makes `curl` fail on a 404 instead of saving an HTML error page with a
`.zst` name. If `sha256sum -c` doesn't print `OK`, stop.

## 5. Inject the firmware into the ISO profile

Files under `archiso/airootfs/` are copied into the live system as-is.

```bash
cd ~/cachyos-archiso
mkdir -p archiso/airootfs/usr/lib/firmware/brcm
```

From A (tarball):

```bash
tar -xf /path/to/firmware.tar -C archiso/airootfs/usr/lib/firmware/brcm
```

From B (package): extract only the firmware directory, not the package
metadata:

```bash
tar --zstd -xf ~/t2-fw/apple-bcm-firmware-14.0-1-any.pkg.tar.zst \
    -C archiso/airootfs usr/lib/firmware
```

Check the MacBookPro15,4 files (`tahiti`) are there:

```bash
ls archiso/airootfs/usr/lib/firmware/brcm/ | grep -i tahiti
```

Optional: the CachyOS wiki recommends the `iwd` Wi-Fi backend for T2 Macs.
To have it set already in the live session:

```bash
mkdir -p archiso/airootfs/etc/NetworkManager/conf.d
printf '[device]\nwifi.backend=iwd\n' > archiso/airootfs/etc/NetworkManager/conf.d/wifi_backend.conf
```

## 6. Build

```bash
sudo ./buildiso.sh -p desktop -v -w
ls -l out/
sha256sum out/*.iso
```

Record the ISO file name, its SHA-256 and the revision from step 3.

## 7. Write the USB and test

Write the ISO with Ventoy, Rufus (DD mode), `dd` or GNOME Disks. Boot holding
**Option**, then check:

```bash
sudo journalctl -k --grep=brcmfmac | tail -5    # firmware loaded, wlan0 renamed
nmcli device wifi list                          # Wi-Fi
bluetoothctl list                               # Bluetooth controller
lsmod | grep -E '^(t2bce|apple_bce)'            # T2 bridge driver
uname -r
```

Also try the internal keyboard and trackpad. Put the results in the test
checklist on [the CachyOS page](../distros/cachyos.md#test-checklist-to-be-filled-in).

## 8. After installing from the ISO

The firmware you added is in the **live** system. Check whether it reached
the installed system (`ls /usr/lib/firmware/brcm | grep -i apple`). If it
didn't, install it as described in [the CachyOS page](../distros/cachyos.md#wi-fi-firmware-on-the-installed-system).

---

## Troubleshooting the build

| Problem | Cause / fix |
|---|---|
| `sudo: command not found` | Arch WSL image without sudo. See step 1 |
| Permission or symlink errors, very slow build | Building under `/mnt/c`. Move to `~/` (step 1) |
| `unknown trust`, `invalid or corrupted package (PGP signature)` | CachyOS key not trusted on the host (step 2), or outdated keyrings |
| `curl: (22) ... 404` | The link is dead. Don't retry the same URL; see [dead links](../drivers-and-firmware.md#dead-download-links-dont-use) |
| `zstd: ... unknown header` / `tar: not in gzip format` | You downloaded an HTML error page, not the package. Use `curl -fL` and check the SHA-256 |
| `pacman` download errors during build | Mirror out of sync. Run `sudo pacman -Syy` and retry |
| No `tahiti` files after step 5 | Wrong extraction path. Files must end up in `archiso/airootfs/usr/lib/firmware/brcm/` |
