---
title: ""
date: 2025-09-19
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---


Absolutely! Here’s a **comprehensive summary of what we did to remove Omarchy and get a clean GNOME setup on your Arch system**, formatted clearly for a writeup:

---

## **1. Remove Omarchy Services and Units**

**Checks performed:**

- Listed all systemd unit symlinks pointing to Omarchy services:
    

```bash
find /etc/systemd -type l -exec test -f {} \; -print | awk -F'/' '{ printf ("%-40s | %s\n", $(NF-0), $(NF-1)) }' | sort -f
```

- Found leftover Omarchy unit:
    

```
omarchy-seamless-login.service | graphical.target.wants
```

**Action:**

```bash
sudo rm /etc/systemd/system/graphical.target.wants/omarchy-seamless-login.service
sudo systemctl daemon-reload
systemctl list-unit-files | grep -i omarchy  # confirm removed
```

---

## **2. Remove Omarchy Plymouth Theme**

**Check:**

```bash
grep -r omarchy /etc/
# Found:
# /etc/plymouth/plymouthd.conf:Theme=omarchy
```

**Action:**

- Set a new Plymouth theme (e.g., `spinner`):
    

```bash
sudo plymouth-set-default-theme -R spinner
```

- Installed required fonts for Plymouth on Arch:
    

```bash
sudo pacman -S cantarell-fonts ttf-dejavu
```

**Notes:**

- `-R` automatically rebuilds the initramfs (`mkinitcpio`) and applies the theme for boot.
    

---

## **3. Fix NetworkManager / Wi-Fi Conflicts**

**Problem:** Wi-Fi not appearing after Omarchy’s IWD/NetworkManager setup.

**Checks performed:**

- Verified NetworkManager status:
```bash
systemctl status NetworkManager
nmcli device status
rfkill list all
lsmod | grep iwlwifi
```

Potentially uninstall all of the wireless-related packages + dependencies + config files (using a wired connection, if via `ssh`, as **wireless network will die**) with: `sudo pacman -Rns iwd wpa_supplicant networkmanager`.
Then **only** reinstall `networkmanager` and & associated drivers with `sudo pacman -Syu networkmanager linux-firmware`.
`
- Ensured no IWD conflicts:

```bash
# This ensures no conflicting background network service (like iwd) is grabbing the Wi-Fi card.
sudo systemctl stop iwd
systemctl disable --now iwd
sudo pacman -Rns iwd

sudo rm -f /etc/NetworkManager/conf.d/*iwd*.conf
sudo rm -f /etc/iwd/main.conf
sudo rm -rf /var/lib/iwd

# Reload the Intel Wi-Fi driver
sudo modprobe -r iwlwifi
sudo modprobe iwlwifi


sudo systemctl daemon-reload
```

Edit `/etc/NetworkManager/NetworkManager.conf` to include:

``` yaml
[main]
plugins=keyfile

[device]
wifi.scan-rand-mac-address=no
```

Then `sudo systemctl restart NetworkManager`, & `sudo systemctl enable --now NetworkManager`.

- Rescan and list Wi-Fi networks:

```bash
# check wireless interfaces are up & listed
ip link 

sudo nmcli device
sudo nmcli device wifi rescan
sudo nmcli device wifi list
```


---

## **5. Configure GNOME + Login Manager**

- Confirmed `ly` login manager works alongside GNOME:

```bash
sudo systemctl enable ly
```


---

## **6. Install & Configure Plymouth, Fastfetch, Kitty, Zsh**

**[`Plymouth`](https://github.com/deepin-community/plymouth/blob/master/README.md) & associated [`plymouth-themes`](https://github.com/adi1090x/plymouth-themes)**
- New theme applied (e.g. `spinner` or custom circle):
```bash
sudo plymouth-set-default-theme -R spinner
```
**Install required fonts for `plymouth` unlock:**
```bash
sudo pacman -S cantarell-fonts ttf-dejavu
```

**Fastfetch:**

- Regenerate config (& optionally create a custom ASCII + system info setup later)

```bash
fastfetch --list-config-paths
fastfetch --gen-config-force 
```

**Kitty Terminal:*
- Themed, with autocomplete & Zsh:
    

```bash
mkdir -p ~/.config/kitty
# customise kitty.conf with colors, font, Zsh, Fastfetch auto-run. 
kitty themes
```

**Zsh:**
- Installed and set as default:

```bash
sudo pacman -S zsh
chsh -s $(which zsh)
```

---
## **7. Final Checks**

- Removed leftover Omarchy mirror and references:

```bash
grep -r omarchy /etc/pacman.d/mirrorlist.bak
# Removed Omarchy mirror if present
```

- Rebooted to test:

```bash
sudo reboot
```

- Confirmed:
    - Plymouth shows new theme
    - Fastfetch displays chibi Arch cat in purple
    - GNOME loads via `ly` login manager
    - Wi-Fi works via NetworkManager
    - No Omarchy logos remain
        

---


## **8. Remove All Omarchy Packages**

**Bulk remove installed Omarchy-related packages and dependencies:**

```bash
sudo pacman -Rns \
  hyprland hypridle hyprlock hyprpicker hyprshot hyprsunset \
  uwsm waybar mako slurp satty swaybg swayosd wf-recorder \
  wl-clip-persist wl-clipboard wl-screenrec walker-bin \
  wiremix blueberry polkit-gnome \
  xdg-desktop-portal-hyprland kvantum-qt5 qt5-wayland \
  omarchy-chromium \
  starship zoxide fastfetch gum \
  fcitx5 fcitx5-gtk fcitx5-qt \
  --noconfirm
```

**Optional: remove general utilities installed by Omarchy that you don’t need:**

```bash
sudo pacman -Rns \
  btop dust eza fd fzf jq pamixer playerctl tldr \
  imagemagick imv pinta mpv typora \
  --noconfirm
```

---

## **9. Remove User Configuration Files**

Delete leftover configuration directories and files for Hyprland, Waybar, Mako, Kitty, Zsh, Starship, and other Omarchy-specific setups:

```bash
rm -rf ~/.config/hypr ~/.config/waybar ~/.config/mako ~/.config/rofi \
       ~/.config/wofi ~/.config/kitty ~/.config/Thunar ~/.config/starship \
       ~/.config/zsh* ~/.zsh* ~/.local/share/icons ~/.themes ~/.icons
```

---

## **10. Reinstall Standard GNOME Packages and Services**

```bash
sudo pacman -S gnome gnome-terminal nautilus gvfs ly \
  networkmanager bluez bluez-utils tlp powertop fwupd fprintd --needed
```

**Enable and start core services:**

```bash
sudo systemctl enable --now NetworkManager bluetooth tlp fprintd ly
sudo systemctl enable --now \
  cups \
  pipewire pipewire-pulse wireplumber \
  snapperd
```

---

## **11. Remove Omarchy Mirrors and Pacman Entries**

- Search for Omarchy in Pacman’s configuration, mirrors, and cache:
    

```bash
sudo grep -r omarchy /etc/pacman*
sudo rm -f /etc/pacman.d/mirrorlist.bak  # if it contains Omarchy mirrors
sudo pacman -Syy  # refresh package database
```

- Remove any local Omarchy binaries, aliases, or shell functions:
    

```bash
grep -r omarchy ~/.bashrc ~/.zshrc ~/.profile ~/.config/*  # review before removing
```

- Delete any leftover Omarchy system-wide binaries if installed manually:
    

```bash
sudo find /usr/local/bin /usr/bin /usr/local/sbin -type f -iname "*omarchy*" -delete
```

---

## **12. Regenerate Default Configs for Standard Tools**

- **Bash / Zsh:**
    

```bash
mv ~/.bashrc ~/.bashrc.old
mv ~/.zshrc ~/.zshrc.old
cp /etc/skel/.bashrc ~/
cp /etc/skel/.zshrc ~/
```

- **Vim / other editors:** delete or backup `~/.vim` or other Omarchy configs.
    

```bash
mv ~/.vim ~/.vim.old
mv ~/.config/nvim ~/.config/nvim.old
```

- **Icons and Themes:** ensure only standard themes remain:
    

```bash
rm -rf ~/.themes ~/.icons
```

---

## **13. Rebuild Initramfs and Plymouth**

- After removing Omarchy Plymouth theme and installing a new one:
    

```bash
sudo plymouth-set-default-theme -R spinner  # example
sudo mkinitcpio -P
```

---

## **14. Reboot and Verify Clean GNOME Environment**
- Reboot and check:

```bash
sudo reboot
```

- Verify:
    - Plymouth splash uses new theme
    - GNOME loads via `ly`
    - Wi-Fi works via NetworkManager
    - No Omarchy logos appear in `fastfetch` or `fastfetch --ascii`
    - No leftover services, configs, or mirrors

---

**Outcome:**

- All Omarchy packages removed
- User configs and themes cleaned
- Standard GNOME + utilities installed and functional
- Plymouth, Fastfetch, Kitty, Zsh properly configured




- fingerprint package: [`python-validity`](https://aur.archlinux.org/packages/python-validity)
	- (doesn't natively work with `ly` but does for sudo commands!)
- `sudo pacman -S steam` (choosing intel versions of drivers)
- enabling proton via compatibility layer
- installing `proton-ge-custom` from `AUR` with `yay -S proton-ge-custom` - a compatibility tool based on Proton that allows playing many more Windows games on Linux systems like Arch ([ref](https://thelinuxcode.com/install_steam_arch_linux/))
- use [prismlauncher](https://prismlauncher.org/download/) + [fabric mod launcher with sodium](https://prismlauncher.org/wiki/getting-started/install-of-alternatives/) to run minecraft optimised (can use instead of minecraft client)
- installing bottles for (windows) apps & game emulation (ubuntu store, flatpak)
- installing `rclone` to sync to onedrive without account bullshit
	- https://rclone.org/onedrive/
	- sync via cli:
		- `rclone config`
		- use defaults (as will configure in web browser), then when selecting remote, type `onedrive`
		- login in web browser when prompted, then name the remote once connected
		- to mount it persistently (as a daemon, to be run at boot) on your filesystem, see [here](https://ericvlog.github.io/posts/rclone-automount-linux/).
			- however, create it as a user service - e.g. create the file under `~/.config/systemd/user/rclone-mount.service`, and use `systemctl --user daemon-reload` & `systemctl --user enable --now rclone-mount` instead (see [here](https://www.guyrutenberg.com/2021/06/25/autostart-rclone-mount-using-systemd/))
		- otherwise, just run manually each time with something like `rclone mount Juni\ -\ OneDrive: ~/OneDrive\ -\ Juni --vfs-cache-mode full --vfs-cache-max-size 40G --daemon`
```

``` bash

```

### music player
- https://www.youtube.com/watch?v=iGW0EpsUb7E

Battery optimisations for lenovo thinkpad:
- https://wiki.archlinux.org/title/Laptop/Lenovo
- https://www.thinkwiki.org/wiki/ThinkWiki

Gaming optimisations:
- [Gaming On Linux - Everything You Need To Know ..](https://www.youtube.com/watch?v=BYIDoD8VdAw&t=120s)


---
## Security:
- [The Biggest Linux Security Mistakes](https://www.youtube.com/watch?v=QxNsyrftJ8I)
- [The Arch Wiki guide](https://wiki.archlinux.org/title/Security)

`ufw`:

``` bash
# Enable firewall
sudo ufw enable
# Reset to defaults (cleans any previous config)
sudo ufw reset

# Set default deny all in, allow all out
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allows ssh on default port 22, with a tarpit (if an IP address makes too many connections in a short period, UFW will temporarily block it)
sudo ufw limit ssh

# Enable logging
sudo ufw logging on
```


changing `ssh` defaults:

``` bash
# transfer ssh key from any machine you want to remotely connect/manage your linux laptop
ssh-copy-id linux-laptop-user@XXX.XXX.XXX.XXX
```

Editing `/etc/sshd/sshd_config` on linux laptop:

``` bash
# Authentication
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
AuthenticationMethods publickey
PermitEmptyPasswords no
IgnoreRhosts yes
HostbasedAuthentication no

# Keys & Ciphers
PubkeyAuthentication yes
X11Forwarding no
AllowTcpForwarding no
PermitTunnel no
GatewayPorts no
AllowAgentForwarding no

# Only strong ciphers, MACs, KEX (adjust if client compatibility issues)
Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512

# Session-based controls
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30
MaxAuthTries 3
MaxSessions 2


```

---
## Check `CPU` microcode:
**Microcode** is essentially low-level firmware inside the CPU. 

[Detecting available microcode updates:](https://wiki.archlinux.org/title/Microcode#Detecting_available_microcode_update)
`sudo pacman -Syu intel-ucode iucode-tool`
`modprobe cpuid`
`iucode_tool -lS /usr/lib/firmware/intel-ucode/`
If an update is available, it should show up below *selected microcodes*.

**SHOULD** just be applied & rebuilt into `initramfs` with `sudo pacman -Syu intel-ucode`.

---
## Auto snapshots with `btrfs`

Using this script (test the manual `sudo btrfs subvolume snapshot -r` commands until they work with your own system subvolume setup):
```bash
#!/bin/bash
set -e

SNAPSHOT_DIR="/.snapshots/manual"
RETENTION_DAYS=7


echo "Current size of snapshot directory:"
sudo du -sh "$SNAPSHOT_DIR"

# Create snapshots of root and home
sudo btrfs subvolume snapshot -r / $SNAPSHOT_DIR/root_$(date +%F_%H-%M)
sudo btrfs subvolume snapshot -r /home $SNAPSHOT_DIR/home_$(date +%F_%H-%M)

# -------------------------------
# Prune old snapshots (older than X days)
# -------------------------------

echo "Pruning snapshots older than $RETENTION_DAYS days in $SNAPSHOT_DIR..."

echo "Disk usage before pruning:"
sudo du -sh "$SNAPSHOT_DIR"

# Find directories older than RETENTION_DAYS and delete them
sudo find "$SNAPSHOT_DIR" -maxdepth 1 -mindepth 1 -type d -mtime +$RETENTION_DAYS \
  -print -exec sudo btrfs subvolume delete {} \;

echo "Disk usage after pruning:"
sudo du -sh "$SNAPSHOT_DIR"

echo "Pruning complete."

```

Then create it to run automatically every `X` days with `systemd timers`:

Create the service file with `sudo vim /etc/systemd/system/btrfs-autosnapshot.service`
``` bash
[Unit]
Description=Btrfs Auto Snapshot

[Service]
Type=oneshot
ExecStart=/usr/local/bin/btrfs-autosnapshot.sh

```

then also the linked timer file with `sudo vim /etc/systemd/system/btrfs-autosnapshot.timer`:

``` bash
[Unit]
Description=Run Btrfs auto snapshot every 2 days

[Timer]
OnBootSec=10min
OnUnitActiveSec=2d
Persistent=true

[Install]
WantedBy=timers.target

```

then enable them with:
```
sudo systemctl daemon-reload
sudo systemctl enable --now btrfs-autosnapshot.timer
```

Can check status with `systemctl list-timers --all | grep btrfs-autosnapshot`, and check the logs of the last run with `journalctl -u btrfs-autosnapshot.service`.