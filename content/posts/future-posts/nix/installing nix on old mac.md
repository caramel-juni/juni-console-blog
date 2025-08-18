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


Now for my next stupid adventure: installing `NixOS` (for the first time) on a 2011 MacBook Air, that *already* has `debian` installed with `GRUB` on an **encrypted (with Linux Unified Key Setup, or `LUKS`) volume**.

**Here we go.**

---

# 1. - Creating a bootable USB installer
I started with the typical attempt of downloading the NixOS graphical installer `.iso` (to try easy mode) as well as the minimal install `.iso` & popping both on my Ventoy USB. 

*However*, I ran into the following slew of errors even *trying* to get *any* of these to work via Ventoy...

- `Not a secure boot platform 14` + infinite hang or kernel panik
- Crashing into shell after `Stage 1` of `NixOS` installer `CLI` bootup process, & then... kernel panik after selecting any option.

After some research, and seeing that this was also encountered by a few other folks who had the same esoteric idea that I did a while back... I resorted to flashing the installer to a fresh USB with good 'ol balenaEtcher, and... it worked perfectly. 

I selected the `Linux LTS kernel` when booting into the installer (a precautionary measure, due to the 2011 hardware... please note that *I haven't tested the most recent kernel on this*).





1. When booting from your live USB, open a terminal session & set up your mountpoints for the NixOS system again
```
# Unencrypt LUKS container
sudo cryptsetup open /dev/sda3 debian-crypt

# Check that you can see inside it - should reveal the discrete volumes & not just "/dev/sda3"
lsblk -f

# Mount whichever LV is your NixOS root partition 
sudo mount /dev/juni-debian-vg/nixos-root /mnt

# Mount the EFI partition you're booting from
sudo mkdir -p /mnt/boot
sudo mount /dev/sda1 /mnt/boot

# Enable swap
sudo swapon /dev/juni-debian-vg/swap_1

# Get the UUID of the encrypted partition, copy output & save for later. Can also use lsblk -f.
sudo blkid -s UUID -o value /dev/sda3
# OR
lsblk -f

# Enter the installed nixOS system (chroot)
sudo nixos-enter --root /mnt
```

2. Edit `hardware-configuration.nix` file (see [here](https://nixos.wiki/wiki/Full_Disk_Encryption)), to ensure it can unlock your encrypted LUKS partition, then activate LVM to read its contents & boot into the correct one.
   
   Replace the `<UUID>` part of each `device = "/dev/disk/by-uuid/<UUID>"` entry with the UUID (e.g. `73d8ad4c-c3b6-4ea7-98d5-f04a3ca36c11`) of your corresponding partition for each mountpoint, discovered in step `1.` with `lsblk -f`.
   
   Further, ensure to add the following packages listed below to `boot.initrd.availableKernelModules` so the kernel can access & decrypt the volume.

```
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Ensure initrd can unlock LUKS before LVM is activated - THIS MAY NOT BE NEEDED (was auto-commented out after re-generation)
  # boot.initrd.luks.enable = true;

  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "dm-snapshot" "cryptd" "aesni_intel" "dm_mod" "dm_crypt" ];

  # Tells initrd which encrypted partition to unlock at boot
  boot.initrd.luks.devices = {
    luksroot = {
      device = "/dev/disk/by-uuid/73d8ad4c-c3b6-4ea7-98d5-f04a3ca36c11";
      preLVM = true;
    };
  };

# Specifies further variables for initrd
  boot.initrd.supportedFilesystems = [ "ext4" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

# Sets up & points to filesystems to mount on boot
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/6526e9ec-dff7-41f3-93d7-daa77c3ce211";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/D5DC-9F01";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/66450e28-0163-4c74-a190-2fa22eb69045"; }
    ];

... [SNIP]
```

![](Screenshot%202025-08-17%20at%206.47.03%20pm.png)


![](70451.png)