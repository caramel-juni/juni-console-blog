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

### Choosing a filesystem:
- https://discourse.nixos.org/t/filesystem-recommendations/28486/11
	- Likely going with `btrfs` - see [here for a tour of a whole host of its features](https://www.youtube.com/watch?v=fLVRMhB_cls&t=27s)

### Partitioning guide:
- https://www.youtube.com/watch?v=iRtVfqBXNVE (very simple `btrfs` install)
- [Mountpoint guide (ArchWiki)](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points) - using `/efi` to allow encrypting of `/boot` partition & proper snapshots/rollbacks with `btrfs` 


Chose to [mount](https://wiki.archlinux.org/title/Mount "Mount") the ESP to `/efi`, see 


Partition with cfdisk: 
- `512MB` EFI System (ESP)
- `8GB` Linux SWAP partition (swap partition vs swapfile [comparison here](https://tecadmin.net/swapfile-vs-swap-partition/))
- `229.9` Linux Filesystem (can use btrfs subvolumes to separate /home and /boot, instead of rigid partitioning seen on ext4. Goes hand in hand with mounting the ESP to `/efi`, as it allows both **rollback** & **encryption** of BOTH `/home` and `/boot` volumes.

### **==Then run the following in minimal install iso to make the filesystem:==**

### FOLLOW [THIS GODSEND GUIDE](https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html) & MAKE SMALL ADJUSTMENTS FROM CHATGPT
 - follow this guide to [get encrypted SWAP file with hibernation working](https://discourse.nixos.org/t/is-it-possible-to-hibernate-with-swap-file/2852/4)

### Partitioning layout
- `/dev/nvme0n1p1` → `EFI` System Partition (512 MiB, FAT32)
- ~~`/dev/nvme0n1p2` → Linux backup SWAP partition (16 GiB) for paging (main hibernation SWAP lives within encrypted filesystem)~~
- `/dev/nvme0n1p3` → `btrfs` root filesystem (rest of disk, encrypted with LUKS2).
	- `swap` (17GB) lives inside here, to store `RAM` on sleep to support hibernation.




### post install:
... install denki retro rice:
- https://github.com/diinki/linux-retroism/tree/main


#### Other resources:
- https://nixos.wiki/wiki/Btrfs#Installation_with_encryption
- &/or https://weiseguy.net/posts/how-to/setup/nixos-with-luks-and-btrfs/
	- can always [follow this thread for some install advice as well](https://discourse.nixos.org/t/btrfs-seeking-installation-advice/40826/16)
- https://gist.github.com/giuseppe998e/629774863b149521e2efa855f7042418
- The "[erase your darlings](https://grahamc.com/blog/erase-your-darlings/)" mindset explained




``` bash
mkswap /dev/nvme0n1p2 -L swap
swapon /dev/nvme0n1p2

# Initialize LUKS on root partition
cryptsetup --verify-passphrase -v luksFormat /dev/nvme0n1p3

# Open it as "cryptroot"
cryptsetup open /dev/nvme0n1p3 cryptroot

# Make Btrfs filesystem
mkfs.btrfs -f /dev/mapper/cryptroot

# Mount temporarily
mount /dev/mapper/cryptroot /mnt

# make swapfile (needed for laptop hibernation ??)
btrfs filesystem mkswapfile --size 16G --name swapfile /mnt/swap




# enter btrfs shell

nix-shell -p btrfs-progs

# once inside shell

mkfs.fat -F 32 /dev/nvme0n1p1

# replace p3 with the partition # of your main linux filesystem (not SWAP or ESP)
mkfs.btrfs /dev/nvme0n1p3

mkdir -p /mnt

```

