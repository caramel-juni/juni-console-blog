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
## ==preamble about why i chose to do this, and the journey i'd been on==


I began by following **[this tutorial](https://www.youtube.com/watch?v=Q4XfaJY2TZo)** to prepare my custom `microwin` installation *(Windows stripped of all the usual bloat Microsoft pumps it with, created by the incredible Chris Titus)* for dual booting. The steps are outlined (roughly) below, as the video is still largely up-to-date as of writing:
# General Overview of preparing Windows for dual-booting
- Install Windows with [`EFI` partition of 1GB or more with a `GPT` partitioning scheme](https://gist.github.com/n0ctu/375703184748c70c5caa4a108e96f6f7#2-disk-preparation) (ideally 4GB if want to do `btrfs` snapshots). 
	- I did this via windows install ISO + manual partitioning + using `Shift` + `f10` to open command prompt & manually making a 1GB `EFI` system partition, initialised with the `GPT` partition table, to be used as the `EFI` system partition. Should know if Windows detects this successfully after selecting the free space to create your windows system partition on, as Windows should **NOT** create **an additional `EFI` partition** and instead, pick up & use the (enlarged) one you created.
- After installing windows, **turn off fast boot & hibernation** with `/powercfg /H off` (see [here](https://wiki.archlinux.org/title/Dual_boot_with_Windows#Disable_Fast_Startup_and_disable_hibernation)).
- Encrypt your windows boot drive with [veracrypt](https://veracrypt.io/en/Downloads.html), & ensure to save the recovery disk at the prompts.
- Check that you've disabled secure boot in your BIOS (may have to research how to do this for your specific device's manufacturer), & then boot into Arch ISO live install.

***Now - onto the "fun" part!***

---
# Installing Arch Linux on an encrypted `btrfs` filesystem, with subvolumes, alongside Windows, using the same `ESP`
---

# 1. - Pre-checks:

1. Check that you're in `UEFI` mode:
```shell
# If this command prints 64 or 32 then you are in UEFI, if nothing, you're in MBR and should likely change this.
cat /sys/firmware/efi/fw_platform_size
```

2. Ensure your boot drive (for me, `nvmen1`) is formatted with `GPT` - should output `Disklabel type: GPT` after running `fdisk -l /dev/nvmen1` (or your corresponding boot drive).

3. Double-check that the `EFI System` partition listed IS your `ESP` - aka, your **EFI System Partition**. This is an *"OS-independent partition that acts as a storage place for UEFI bootloaders, applications & drivers to be launched by the UEFI firmware* (see: [the Arch Wiki](https://wiki.archlinux.org/title/EFI_system_partition)).
   
   You can check this by listing your disks & partitions with `fdisk -l` & then [mounting](https://wiki.archlinux.org/title/Mount "Mount") the suspected `ESP` partition - for me, `mount /dev/nvmen1p1 /mnt`. Then, run `cd /mnt` & `ls` to check whether it contains a directory named `EFI` - which in turn, should contain your various bootloader entries (including Windows). If it does, **this is definitely the ESP and you can proceed.**

---
# 2. - Partitioning your disk for Arch + encrypted `btrfs`

# Partitioning overview:
![](Screenshot%202025-09-16%20at%2010.30.38%20pm.png)

Using `cgdisk` (I tried this out to name the partitions for convenience, but I much prefer the operation of `cfdisk`...)

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

Now, we should be able to see inside `/dev/nvme0n1p7` - check it out with `lsblk -f`!

![](Screenshot%202025-09-15%20at%207.17.49%20pm.png)


---
# 3. - Making the `btrfs` file system and subvolumes:

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

---
# 4. - Mounting `btrfs` subvolumes with optimised options if using an `SSD`:

``` bash

# Create mount directories
mkdir -p /mnt/{home,.snapshots}

# Mount persistent subvolumes
mount -t btrfs -o subvol=@root,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt
mount -t btrfs -o subvol=@home,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/home
mount -t btrfs -o subvol=@snapshots,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/.snapshots

```

## Options explained:

| Option          | Purpose                                                             |
| --------------- | ------------------------------------------------------------------- |
| `subvol=root`   | Mount the specific subvolume as root                                |
| `compress=zstd` | Compress files to save space, reduce writes, possibly improve speed |
| `noatime`       | Don’t update file access times → reduces unnecessary writes         |
| `ssd`           | Optimize Btrfs allocation for SSD characteristics                   |
| `discard=async` | Enable background TRIM to keep SSD healthy and fast                 |

---
# 5. - Creating a `SWAP` partition:

For simplicity, I'll be going with creating a dedicated [`SWAP` partition](/title/Swap#Swap_partition) as opposed to a [`SWAP` file](https://wiki.archlinux.org/title/Swap#Swap_partition), to `SWAP` file support on `btrfs` is potentially a [little dodgy with hibernation](https://www.jwillikers.com/btrfs-swapfile) (but am unsure on this):

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

# 6. - Make your `ext4` `/boot` partition

I'll be making this as its **own partition** for simplicity (as opposed to it being **an encrypted subvolume**, as that will require additional steps to boot from as it will need to be [decrypted at startup](https://wiki.archlinux.org/title/GRUB#Encrypted_/boot)). 

The `/boot` partition differs from the `ESP` as it primarily contains important **linux-specific system files** (kernel images, initial RAM disk, bootloader resources like for `grub`, etc.) - hence why separating it from the `ESP` is a good idea wherever possible, *especially* if the `ESP` is small.

``` bash
# Make the /boot partition as an ext4 filesystem, for GRUB
mkfs.ext4 /dev/nvme0n1p5

# Create the /boot directory and mount it:
mkdir -p /mnt/boot

mount /dev/nvme0n1p5 /mnt/boot
```

# 7. - Mount the existing `ESP` to a newly-created `/mnt/efi` directory

Make a new directory on your `linux` filesystem to mount the existing `ESP` - in my case, I'll use `/mnt/efi` (see [here for benefits](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points) - however, this naming scheme/location only supported when using `GRUB` or `rEFInd`).

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

# 8. - Post-partitioning steps:

**Set the mirrorlist to download packages from:** Generate optimal ones for your region [here](https://archlinux.org/mirrorlist/) (recommend to do `https` only) and then add them to `/etc/pacman.d/mirrorlist`

Now to **`pacstrap` your system** with "the basics" (will install more later):

`pacstrap -K /mnt base linux linux-firmware intel-ucode btrfs-progs curl wget vim sudo grub efibootmgr os-prober networkmanager cryptsetup base-devel git less`

See the [arch wiki](https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages) for what to swap in/out based on your system, but is primarily hardware-based packages like `intel-ucode`/`amd-ucode`, and bootloader-specific options like `grub` & `os-prober` etc. And if you use NVIDIA... see [here](https://wiki.archlinux.org/title/NVIDIA).

Now to **generate the filesystem table with `genfstab`**, outlining which block devices hold what data, so your system knows how to access it all.
`genfstab -U /mnt >> /mnt/etc/fstab`

Make sure to open up `/mnt/etc/fstab` to check for any errors with the `UUID`s listed, but it should be auto-generated:
![](Screenshot%202025-09-15%20at%208.20.17%20pm.png)

Now, time to `arch-chroot` & directly interact with your new system's environment! Once you're in, perform the following - referencing the corresponding sections of the [Arch installation guide](https://wiki.archlinux.org/title/Installation_guide#Time) (as these steps are fairly standard fare):
- Generate locales
- Set root password
- Create (sudo) user & set password, edit `sudoers` file if desired
- Set hostname
- ...etc.

As we're encrypting the filesystem, we need to make a few small changes to `/etc/mkinitcpio.conf` to change the hooks for the booting process, in order for our system to be able to [unlock our `LUKS`-encrypted `/root` partition](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_mkinitcpio). **Note the ORDER of these highlighted entries - it's important.** Add `block encrypt filesystems btrfs resume`:

![](Screenshot%202025-09-15%20at%208.36.48%20pm.png)

Afterwards, recreate the `initramfs` image with `mkinitcpio -P`.

# 9. - Setup GRUB

Almost there! Time to install some additional tools for setting up `grub`'s capabilities (note the use of `pacman` now we're **inside** the system itself):

`pacman -S dosfstools os-prober mtools memtest86+`

Then, install grub in `/efi` (if that's where your `/boot` is mounted, as I did earlier):

`grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB`


Now - **take CAREFUL note of the various** `UUID`s of your block device partitions - in particular, the:
- **Windows-created ESP** (for me, the `UUID` of `nvme0n1p1`)
- Your `SWAP` partition (for me, the `UUID` of `nvme0n1p6`)
- Your **ENCRYPTED** `/root` partition (for me, the `UUID` of `nvme0n1p7`). *Note - **NOT** the `UUID` of the **[device mapper](https://linuxvox.com/blog/dev-mapper-linux/)**`/dev/mapper/XXXXXXXX`, but of the **actual block device** `nvme0n1pX`.*

You can do this with something like `blkid | less -S`:

``` bash
# >> Windows-created ESP <<
/dev/nvme0n1p1: LABEL="EFI" UUID="26CC-B80A" BLOCK_SIZE="512" TYPE="vfat" PARTLABEL="EFI system partition" PARTUUID="8932caff-45aa-4e22-bd46-e0c5e59a0493"

# >> SWAP partition <<
/dev/nvme0n1p6: UUID="879c97b6-0117-4550-a53d-1fa4c0197841" TYPE="swap" PARTLABEL="swap" PARTUUID="0221c16e-2488-4183-8a87-1480a4674642"

# Encrypted DEVICE containing your root partition
/dev/nvme0n1p7: UUID="633a5bdc-2ee2-4646-88b0-b117751807f1" TYPE="crypto_LUKS" PARTLABEL="root" PARTUUID="dcbc0b5c-29aa-4de6-8bcb-85a9e1e20fe9"

```

Then, just edit the line `GRUB_CMDLINE_LINUX` in `/etc/default/grub` to include the following `UUIDs` of your **encrypted root partition**, and `SWAP` (unsure if the latter is necessary):

``` bash
# e.g for me, my encrypted /root partition is on /dev/nvmen1p7, so replace it in <luks-device-uuid> its UUID after "cryptdevice=UUID=", and my SWAP's UUID after resume=UUID=<swap-uuid>:

GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-device-uuid>:cryptroot root=/dev/mapper/cryptroot resume=UUID=<swap-uuid>"

```

![](Screenshot%202025-09-15%20at%208.49.25%20pm.png)

Also within the same file, **uncomment** `GRUB_DISABLE_OS_PROBER` so that it can auto-detect Windows & add its bootloader to the menu. You can also add an entry for this manually if you prefer, as shown [here](https://gist.github.com/n0ctu/375703184748c70c5caa4a108e96f6f7#498-install-and-configure-grub).

![](Screenshot%202025-09-15%20at%208.50.35%20pm.png)

Then, simply generate the new `grub` boot menu with `grub-mkconfig -o /boot/grub/grub.cfg`. Monitor the output for what entries it is able to detect, and troubleshoot accordingly if it misses either the windows or linux entries.

![](Screenshot%202025-09-15%20at%208.58.19%20pm.png)

If it does miss any, you can add entries manually as [described here](https://wiki.archlinux.org/title/GRUB#Windows_installed_in_UEFI/GPT_mode), by creating files like `/etc/grub.d/40_custom`. E.g., if `os-prober` doesn't detect your `Windows Boot Manager`, or you want to add any other boot entries. 

**Example:**

``` bash
#!/bin/sh
exec tail -n +3 $0

menuentry "VeraCrypt Bootloader (Windows)" --class windows --class os {
    insmod part_gpt
    insmod fat
    # replacing 26CC-B80A with your actual ESP's UUID
    search --no-floppy --fs-uuid --set=root 26CC-B80A
    chainloader /EFI/VeraCrypt/DcsBoot.efi
}
```

Once done, you can `exit` the `chroot` environment, unmount everything with `umount -R /mnt` & `swapoff -a`, and then... pray, and `reboot`.

If all goes well, you should be presented with the `grub` menu upon rebooting, and be able to select & boot into Windows & Arch linux, both prompting you to enter the passwords for the encrypted partitions before doing so!

# 10. [OPTIONAL] - Installing the [omarchy]() desktop environment

**In stark contrast to the rest of this guide**... installing `omarchy` is as simple as logging into your new Arch system, ensuring you have a network connection & running the following command:

`curl -fsSL https://omarchy.org/install | bash`

And then follow the prompts.

***Yep. That's it.***

And then, voila!

![](Screenshot%202025-09-16%20at%2010.39.21%20pm.png)

---
# Troubleshooting *(because every good Arch install comes with it pre-loaded)*

If you run into any errors, Google is your best friend - but if you need to get back into your `Arch` install to modify the boot settings, run the below set of commands to remount your filesystem & `btrfs` (sub)volumes in order to safely do so. 

``` bash
# open & enter encrypted root partition
cryptsetup open /dev/nvme0n1p7 cryptroot

# re-mount sub-volumes
mount -o subvol=@root /dev/mapper/cryptroot /mnt
mount -o subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots

# re-mount boot & ESP partitions
mount /dev/nvme0n1p5 /mnt/boot
mount /dev/nvme0n1p1 /mnt/efi

# now you can enter the filesystem & edit your arch system files normally
arch-chroot /mnt

```

*I had to do this once as I initially put the `UUID` of `/dev/mapper/cryptroot` instead of `/dev/nvmen1p7` for my `root` partition to be unlocked & loaded at boot, hence my extreme emphasis on grabbing the right one above!*

---

