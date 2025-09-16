---
title: Encrypted Windows 11 + Encrypted Arch with btrfs & Omarchy post-install
date: 2025-09-15
description: ""
toc: true
math: true
draft: true
categories:
tags:
---
- Install windows with [EFI partition of 1GB or more with a GPT partitioning scheme](https://gist.github.com/n0ctu/375703184748c70c5caa4a108e96f6f7#2-disk-preparation) (ideally 4GB if want to do btrfs snapshots). 
	- I did this via windows install ISO + manual partitioning + using Shift + f10 to open command prompt & manually making a 1GB EFI system partitioning initialised with the GPT partition table, to be used as the EFI system partition. Should know if Windows detects this successfully after selecting the free space to create your windows system partition on, as Windows should create **no additional EFI partition** and pick up & use the (enlarged) one you created.
- After installing windows, turn off fast boot & hibernation `/powercfg /H off`. (see [here](https://wiki.archlinux.org/title/Dual_boot_with_Windows#Disable_Fast_Startup_and_disable_hibernation))
- Encrypt windows boot drive with [veracrypt](https://veracrypt.io/en/Downloads.html) & save recovery disk.
- *Generally just follow [THIS](https://www.youtube.com/watch?v=Q4XfaJY2TZo) video tutorial*

Once have disabled secure boot in BIOS, boot into Arch ISO live install.

# Installing Arch:

## Pre-checks:

1. Check that you're in UEFI mode:
```shell
# If this command prints 64 or 32 then you are in UEFI, if nothing, you're in MBR and should likely change this.
cat /sys/firmware/efi/fw_platform_size
```

2. Ensure your boot drive (for me, `nvmen1`) is formatted with `GPT` - should output `Disklabel type: GPT` after running `fdisk -l /dev/nvmen1` (or your corresponding boot drive).

3. Double-check that the `EFI System` partition listed IS your `ESP` - aka, your **EFI System Partition**. This is an *"OS-independent partition that acts as a storage place for UEFI bootloaders, applications & drivers to be launched by the UEFI firmware* (see: [the Arch Wiki](https://wiki.archlinux.org/title/EFI_system_partition)).
   
   You can check this by listing your disks & partitions with `fdisk -l` & then [mounting](https://wiki.archlinux.org/title/Mount "Mount") the suspected `ESP` partition - for me, `mount /dev/nvmen1p1 /mnt`. Then, run `cd /mnt` & `ls` to check whether it contains a directory named `EFI` - which in turn, should contain your various bootloader entries (including Windows). If it does, **this is definitely the ESP and you can proceed.**

## Partitioning your disk for Arch + encrypted `btrfs`


## TLDR; for june to do:

1. Follow [THIS](https://www.youtube.com/watch?v=Q4XfaJY2TZo) video tutorial for using the same ESP boot partition for windows & arch, with GRUB. (**do it via ssh & record commands for my own tutorial**).
2. **(See [here](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points) for info on EFI and ESP).** Create ONE partition for btrfs, and create a @boot subvolume and mount THAT as `/boot` to contain system files, and to enable btrfs snapshots. **OR** create `ext4`  partition for GRUB (as in tutorial [here](https://gist.github.com/n0ctu/375703184748c70c5caa4a108e96f6f7)) if don't mind `/boot` being unencrypted. Then mount the existing ESP (windows created EFI partition) to `/efi` to allow bootloader, GRUB, to access that (follow video tutorial)

3. And then just switch to & follow [THIS](https://gist.github.com/n0ctu/375703184748c70c5caa4a108e96f6f7) guide for partitioning & enabling SWAP on `btrfs`:

![](Screenshot%202025-09-15%20at%2012.07.47%20am.png)



Using `cgdisk`:

![](Screenshot%202025-09-15%20at%207.12.21%20pm.png)

Now, onto encryption. Thanks to the *Godsend* that is the ever-comprehensive [Arch Wiki Docs](https://wiki.archlinux.org/title/GRUB#LUKS2), I discovered (after finishing this process & being locked out at boot) that **`GRUB` doesn't [natively](https://aur.archlinux.org/packages/grub-improved-luks2-git/) support the default encryption algorithm used by `cryptsetup`** (`Argon2id` & its Password-Based Key Derivation Functions, or `PBKDFs`) - see [GRUB bug #59409](https://savannah.gnu.org/bugs/?59409).

Thus, if we choose to use the more modern `LUKS2` (good practice over `LUKS1`) we must convert it to use `PBKDF2`, detailed below:

``` bash
# encrypt root partition using LUKS2
cryptsetup luksFormat /dev/nvme0n1p7 --type luks2 --verify-passphrase

# convert the hash and PBDKDF algorithms for this encrypted volume
cryptsetup luksConvertKey --hash sha256 --pbkdf pbkdf2 /dev/nvme0n1p7

# open root partition as "cryptroot"
cryptsetup open /dev/nvme0n1p7 cryptroot

```
Now, we should be able to see inside `/dev/nvme0n1p7` - check it out with `lsblk -f` !

![](Screenshot%202025-09-15%20at%207.17.49%20pm.png)



### 3. - Making your `btrfs` file system and subvolumes:

``` bash
# Make your (encrypted) partition a Btrfs filesystem
mkfs.btrfs -f /dev/mapper/cryptroot

# Mount temporarily
mount /dev/mapper/cryptroot /mnt

# Create subvolumes
btrfs subvolume create /mnt/@root      # system root, '/' on the final system
btrfs subvolume create /mnt/@home      # system home, ‘/home’ on the final system
btrfs subvolume create /mnt/@snapshots # system snapshots, '/.snapshots’ on the final system

# get out of /mnt (otherwise can't umount)
cd /

# Unmount to remount subvolumes with options (see below)
umount /mnt
```

### 4. - Mounting `btrfs` subvolumes with optimised options for our SSD:

``` bash

# Create mount directories
mkdir -p /mnt/{home,.snapshots}

# Mount persistent subvolumes
mount -t btrfs -o subvol=@root,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt
mount -t btrfs -o subvol=@home,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/.home
mount -t btrfs -o subvol=@snapshots,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/.snapshots

```


### 5. - Creating a SWAP partition:

For simplicity, I'll be going with creating a dedicated SWAP partition, due to SWAPfile support on btrfs being potentially a [little dodgy with hibernation](https://www.jwillikers.com/btrfs-swapfile) (but amunsure):

``` bash
# Make the SWAP (take note of UUID for later)
mkswap /dev/nvme0n1p6

# Activate SWAP
swapon /dev/nvme0n1p6

# Check it's mounted as [SWAP]
lsblk

# Add following entry to /etc/fstab using something like vim, changing the below to your corresponding SWAP partition's UUID
UUID=879c97b6-0117-4550-a53d-1fa4c0197841 none swap defaults 0 0

# Confirm it's active & on
swapon --show
```

![](Screenshot%202025-09-15%20at%207.45.20%20pm.png)

## 6. - Make your `ext4` `/boot` partition

Contains OS files, etc.

``` bash
# Make the /boot partition as an ext4 filesystem, for GRUB
mkfs.ext4 /dev/nvme0n1p5

# Create the /boot directory and mount it:
mkdir -p /mnt/boot

mount /dev/nvme0n1p5 /mnt/boot
```

### 7. - Mount the existing `ESP` to a newly-created `/mnt/efi` directory

Make a new directory on your `linux` filesystem for the existing `ESP` - in my case, I'll use `/mnt/efi` (see [here for benefits](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points) - however, is only supported when using `GRUB` or `rEFInd`).

``` bash
# Make /efi directory
mkdir /mnt/efi

# Mount it on the existing (Windows-created) ESP
mount /dev/nvme0n1p1 /mnt/efi
```

Now check you've got all your filesystems mounted properly:
![](Screenshot%202025-09-15%20at%208.06.39%20pm.png)
... and that each has a filesystem type and is similar to the following structure (from `nvmen1p5` down):
![](Screenshot%202025-09-15%20at%208.06.48%20pm.png)

## 8. - Post-partitioning steps:

**Set the mirrorlist to download packages from:** Generate optimal ones for your region [here](https://archlinux.org/mirrorlist/) (recommend to do `https` only) and then add them to `/etc/pacman.d/mirrorlist`

Now to **`pacstrap` your system** with "the basics" (will install more later):

`pacstrap -K /mnt base linux linux-firmware intel-ucode btrfs-progs curl wget vim sudo grub efibootmgr os-prober networkmanager cryptsetup base-devel git less`

See the [arch wiki](https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages) for what to swap in/out based on your system, but is primarily hardware-based packages like `intel-ucode`/`amd-ucode`, and bootloader-specific options like `grub` & `os-prober` etc. And if you use NVIDIA... see [here](https://wiki.archlinux.org/title/NVIDIA).

Now to **generate the filesystem table with `genfstab`**, and check for any errors with the `UUID`s listed:

`genfstab -U /mnt >> /mnt/etc/fstab`

![](Screenshot%202025-09-15%20at%208.20.17%20pm.png)

Now, just `arch-chroot` to directly interact with the new system's environment, and do the following - referencing the corresponding sections of the [Arch installation guide](https://wiki.archlinux.org/title/Installation_guide#Time) (as these steps are fairly standard fare):
- Generate locales
- Set root password
- Create (sudo) user & set password, edit `sudoers` file if desired
- Set hostname

As we're encrypting, we need to make a few small changes to `/etc/mkinitcpio.conf` to change the hooks, in order for our system to [unlock our `LUKS`-encrypted `/root` partition](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_mkinitcpio). **Note the ORDER of these highlighted entries - it's important.**

![](Screenshot%202025-09-15%20at%208.36.48%20pm.png)

Afterwards, recreate the `initramfs` image with `mkinitcpio -P`.

## 9. Setup GRUB:

Almost there! Install some additional tools for setting up `grub`:

`pacman -S dosfstools os-prober mtools memtest86+`

Then, install grub in `/efi`:
`grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB`

Now - take note of the various `UUID`s of your partitions - in particular, the:
- **Windows-created ESP**
- Your **ENCRYPTED** `/root` partition (**NOT** the one at `/dev/mapper/XXXXXXXX`, but the one at the encrypted DEVICE `nvme0n1pX`)
- Your `swap` partition

- You can do this with something like `blkid | less -S`:
``` bash
# >> Windows-created ESP <<
/dev/nvme0n1p1: LABEL="EFI" UUID="26CC-B80A" BLOCK_SIZE="512" TYPE="vfat" PARTLABEL="EFI system partition" PARTUUID="8932caff-45aa-4e22-bd46-e0c5e59a0493"

# >> SWAP partition <<
/dev/nvme0n1p6: UUID="879c97b6-0117-4550-a53d-1fa4c0197841" TYPE="swap" PARTLABEL="swap" PARTUUID="0221c16e-2488-4183-8a87-1480a4674642"

# Encrypted DEVICE containing your root partition
/dev/nvme0n1p7: UUID="633a5bdc-2ee2-4646-88b0-b117751807f1" TYPE="crypto_LUKS" PARTLABEL="root" PARTUUID="dcbc0b5c-29aa-4de6-8bcb-85a9e1e20fe9"


#### Other partitions you may see: ####

# /boot partition (where GRUB & system files reside)
/dev/nvme0n1p5: UUID="f509afa1-09e7-4ef2-a8ae-9db01da84f7c" BLOCK_SIZE="4096" TYPE="ext4" PARTLABEL="boot" PARTUUID="5fe30c33-9fc4-4749-996d-cb4074bd57cb" 

# The mapper for the encrypted root partition - the one with "/dev/mapper/"
/dev/mapper/cryptroot: LABEL="cryptroot" UUID="db721e94-ba53-42a0-9545-d343d36089fb" UUID_SUB="836483ea-2f3d-4a34-a2d5-1665578fe335" BLOCK_SIZE="4096" TYPE="btrfs"

```

Take note of the `UUIDs` for main encrypted device volume (`/root`) and `swap` partitions, generated above with `blkid | less -S`:

![](Screenshot%202025-09-15%20at%208.49.25%20pm.png)

Also, uncomment `GRUB_DISABLE_OS_PROBER` & it should find windows & add to partition.
![](Screenshot%202025-09-15%20at%208.50.35%20pm.png)
``` bash
# e.g for me, my encrypted /root partition is on /dev/nvmen1p7, so replace it in <luks-device-uuid> its UUID after "cryptdevice=UUID=", and my SWAP's UUID after resume=UUID=<swap-uuid>:

GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-device-uuid>:cryptroot root=/dev/mapper/cryptroot resume=UUID=<swap-uuid>"

```


![](Screenshot%202025-09-15%20at%208.58.19%20pm.png)