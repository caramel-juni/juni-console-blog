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
