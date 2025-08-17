---
title: ""
date: 2025-08-16
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---
- [x] Find out exact macbook model for better troubleshooting 
- `A1369` - 2011 MacBook Air [specs](https://apple.techable.com/specs/macbook-air-13-inch-core-i7-1-8-ghz-2011/)
### Live-boot from USB:
1. ==Try flashing `nixOS` to a blank USB, instead of `ventoy`. Graphical install & then minimal install. See:
	- [Potential ventoy issues with older macbooks](https://www.reddit.com/r/NixOS/comments/1b4xv5j/nix_os_dossent_work_on_ventoy/)
	- ==**THIS WORKED !**==
2. Boot into debian & **check secure boot status.** Then, [reboot into **recovery mode**](https://www.wikihow.com/Turn-Off-Secure-Boot-on-Mac) ([video](https://www.youtube.com/watch?v=rzjXgPmVtdQ&t=38s)) to **check secure boot status & other pre-reqs: [here](https://dev.to/raymondgh/day-1-installing-nixos-on-my-2019-macbook-pro-2idh)**
3. Try checking partitions in debian to see if space is ready
4. Troubleshoot the exact error commands I get when using `ventoy`
	- https://dev.to/raymondgh/day-4-reinstalling-nixos-on-my-apfs-t2-intel-macbook-pro-265n

**At this stage, pause and think: ... but is it really worth it?** 
See poor reports:
	- https://dev.to/raymondgh/day-7-uninstalling-nixos-from-my-macbook-pro-3fc9
	- https://discourse.nixos.org/t/trying-to-install-nixos-on-a-2015-macbook-pro-poor-experience/42736/10

If arrive on "yes", try...
### Installing from existing OS install:
- If no dice, **follow nixOS install guide *from* [existing distro install](https://github.com/NixOS/nixpkgs/blob/master/nixos/doc/manual/installation/installing-from-other-distro.section.md)**
- Try [old macbook-specific guide](https://superuser.com/questions/795879/how-to-configure-dual-boot-nixos-with-mac-os-x-on-an-uefi-macbook)
- https://www.arthurkoziel.com/installing-nixos-on-a-macbookpro/
- Follow [this video guide](https://www.youtube.com/watch?v=82vrj22omyQ) - boot and install nixOS FROM debian.








1. Set up your mountpoints for the NixOS system:

```
# Unencrypt LUKS container
sudo cryptsetup open /dev/sda3 debian-crypt

# Check can see inside it:
lsblk -f

# Mount your NixOS root LV
sudo mount /dev/juni-debian-vg/nixos-root /mnt

# Mount EFI partition for systemd-boot
sudo mkdir -p /mnt/boot
sudo mount /dev/sda1 /mnt/boot

# Enable swap
sudo swapon /dev/juni-debian-vg/swap_1

# Get the UUID of the encrypted partition, copy output & save for later
sudo blkid -s UUID -o value /dev/sda3

# Enter the installed nixOS system (chroot)
sudo nixos-enter --root /mnt
```

2. 
3. Edit `hardware-configuration.nix` file (see [here](https://nixos.wiki/wiki/Full_Disk_Encryption))
```
# Ensure initrd can unlock LUKS *before* LVM is activated.

boot.initrd.lvm.enable = true;

# Tell initrd which encrypted partition to unlock at boot. The name "debian-crypt" is arbitrary; using the existing name keeps things tidy.

boot.initrd.luks.devices."debian-crypt".device = "/dev/disk/by-uuid/PUT-UUID-OF-SDA3-HERE";
```


