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

### 1. - Partitioning layout (using `cfdisk`)
- `/dev/nvme0n1p1` → `512 MiB` `EFI` System Partition
- ~~`/dev/nvme0n1p2` → Linux backup SWAP partition (16 GiB) for paging (main hibernation SWAP lives within encrypted filesystem)~~
- `/dev/nvme0n1p2` → `btrfs` root filesystem (nearly the whole rest of disk, encrypted with LUKS).
	- `swap` (17GB) lives inside here, to store `RAM` on sleep to support hibernation.
- `1GB free space` (for the lols)

### 2. - Making the boot filesystem & setting up LUKS2 encryption

First, lets set the boot filesystem (`FAT32`):
``` bash
# make EFI boot partition FAT32 filesystem
mkfs.fat -F32 /dev/nvmen1p1
```

Now, onto encryption. Thanks to the *Godsend* that is the ever-comprehensive [Arch Wiki Docs](https://wiki.archlinux.org/title/GRUB#LUKS2), I discovered (after finishing this process & being locked out at boot) that **`GRUB` doesn't [natively](https://aur.archlinux.org/packages/grub-improved-luks2-git/) support the default encryption algorithm used by `cryptsetup`** (`Argon2id` & its Password-Based Key Derivation Functions, or `PBKDFs`) - see [GRUB bug #59409](https://savannah.gnu.org/bugs/?59409).

Thus, if we choose to use the more modern `LUKS2` (good practice over `LUKS1`) we must convert it to use `PBKDF2`, detailed below:

``` bash
# encrypt root partition using LUKS2
cryptsetup luksFormat /dev/nvmen1p2 --type luks2 --verify-passphrase

# convert the hash and PBDKDF algorithms for this encrypted volume
cryptsetup luksConvertKey --hash sha256 --pbkdf pbkdf2 /dev/nvme0n1p2

# open root partition as "cryptroot"
cryptsetup open /dev/nvme0n1p2 cryptroot

```
Now, we should be able to see inside `/dev/nvme0n1p2` - check it out with `lsblk -f` !


### 3. - Making your `btrfs` file system and subvolumes:

``` bash
# Make Btrfs filesystem
mkfs.btrfs -f /dev/mapper/cryptroot

# Mount temporarily
mount /dev/mapper/cryptroot /mnt

# Create subvolumes
btrfs subvolume create /mnt/root       # system root (erased every boot)
btrfs subvolume create /mnt/home       # persistent user data
btrfs subvolume create /mnt/nix        # nix store
btrfs subvolume create /mnt/persist    # system state to persist
btrfs subvolume create /mnt/log        # /var/log
btrfs subvolume create /mnt/swap       # swapfile for hibernation

# Create readonly snapshot of root for rollback
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank

# get out of /mnt (otherwise can't umount)
cd /

# Unmount to remount properly
umount /mnt
```

### 4. - Mounting `btrfs` subvolumes with optimised options for our SSD:

``` bash
# Mount root
mount -o subvol=root,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt

# Create mount directories
mkdir -p /mnt/{home,nix,persist,var/log,efi}

# Mount persistent subvolumes
mount -o subvol=home,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/home
mount -o subvol=nix,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/nix
mount -o subvol=persist,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/persist
mount -o subvol=log,compress=zstd,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/var/log

# Mount EFI boot partition
mount /dev/nvme0n1p1 /mnt/efi

```


#### Options explained:

| Option          | Purpose                                                             |
| --------------- | ------------------------------------------------------------------- |
| `subvol=root`   | Mount the specific subvolume as root                                |
| `compress=zstd` | Compress files to save space, reduce writes, possibly improve speed |
| `noatime`       | Don’t update file access times → reduces unnecessary writes         |
| `ssd`           | Optimize Btrfs allocation for SSD characteristics                   |
| `discard=async` | Enable background TRIM to keep SSD healthy and fast                 |

### 5. Making the SWAP file & its own subvolume

``` bash
# Set directory to NOCOW (already mounted with nodatacow)
chattr +C /mnt/swap

# Make swap DIRECTORY (to house SWAPfile)
mkdir /mnt/swap

# Mount this directory to the swap subvolume with NOCOW and compression disabled
mount -o subvol=swap,compress=no,ssd,discard=async,nodatacow /dev/mapper/cryptroot /mnt/swap

# Make the swapFILE itself, >= RAM size for saving hibernation state
btrfs filesystem mkswapfile --size 17G --uuid clear /mnt/swap/swapfile

# Ensure it has these permissions (usually created by default)
chmod 600 /mnt/swap/swapfile

# Make it swap & activate it
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile

```

## #6: Generate NixOS configuration
Creates the initial `hardware-configuration.nix` and `configuration.nix` files.
``` bash
nixos-generate-config --root /mnt
```

Then... set up your config. This will be quite specific to your configuration, but some key points to include `configuration.nix` are:

- Setting your bootloader - `GRUB` for me
	- Enabling Cryptodisk
- Setting filesystem as `btrfs`
- Pointing your bootloader to the system mount point, for me `/efi`
- Enabling SWAPfile & pointing to its location
- ENsuring /var/log persists & mounts at boot - `fileSystems."/var/log" = { neededForBoot = true; }`
- Setting your display manager (`sddm`, `wayland`) & desktop manager (`plasma6`)
- Defining user account
- Adding minimal programs for functionality (vim, wget, curl, kitty, fastfetch, htop)
- ... a few other things (==to check and paste below==)

Then, cross your fingers and run `nixos-install` & field the error after error you get with config semantics 🤣. Just focus on the red `error: words here...` part, and **don't forget your semicolons at the end of each line`;`!!!**

Then, upon a successful run, you'll be prompted for a `root` password, and then set your user's password (if you want to use that to login) with: `nixos-enter --root /mnt -c 'passwd USERNAME`.

***THEN,*** just... `reboot`. And **pray**.

---

My minimal (working, at least - have removed most uncommented lines from default config) `configuration.nix`:

``` nix
{ config, lib, pkgs, ... }:

{
	
	imports = [ 
		# Includes the results of the hardware scan.
		./hardware-configuration.nix
		
	];
	
# Setting EFI bootloader variable access, packages.
	boot.loader.efi.canTouchEfiVariables = true;
	boot.kernelPackages = pkgs.linuxPackages_latest;
	boot.loader.efi.efiSysMountPoint = "/efi";

# Setting GRUB as bootloader
	boot.loader.grub = {
		enable = true;
		efiSupport = true;
		devices = [ "nodev" ];
		useOSProber = true;
		enableCryptodisk = true;
	};

# Sets filesystem supported at boot
	boot.supportedFilesystems = [ "btrfs" ];

# SWAP Devices/file
	boot.initrd.systemd.enable = true;
	swapDevices = [{
		device = "/swap/swapfile";
		size = 17 * 1024;
	}];

# Ensures /var/log persists & is mounted at boot
	fileSystems."/var/log" = { neededForBoot = true; };
	
# Networking
	networking.hostName = "juni-nixos"; # Define your hostname.
# Pick only one of the below networking options.
	# networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.
	networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
	
# Set your time zone
	time.timeZone = "XXXXXXX/XXXXXXXX";

	
# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";
	console = {
		font = "Lat2-Terminus16";
		useXkbConfig = true; # use xkb.options in tty.
	};
	
# Enable desktop environment
	services = {
	# GNOME:
		xserver.enable = true;
		xserver.desktopManager.gnome.enable = true;
		xserver.displayManager.gdm.enable = true;
	};
	
# Enable sound.
	services.pipewire = {
		enable = true;
		pulse.enable = true;
	};
	
# Enable touchpad support (enabled default in most desktopManager).
	services.libinput.enable = true;
	
# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.juni = {
		isNormalUser = true;
		extraGroups = [ "wheel" ]; # Enables ‘sudo’ for the user.
		shell = pkgs.bash;
		home = "/home/juni";
		packages = with pkgs; [
				tree
		];
	};
	
# List packages installed in system profile.
# You can use https://search.nixos.org/ to find more packages (and options).
	environment.systemPackages = with pkgs; [
		vim 
		wget
		curl
		fastfetch
		htop
		kitty
		git
		powertop
		gparted
		firefox
		vlc
		adwaita-icon-theme
	];
	
	programs.firefox.enable = true;
	
# Enable the OpenSSH daemon.
	services.openssh.enable = true;
	
	system.stateVersion = "25.05";
}
```

Most of the device mappings were auto-generated in `hardware-configuration.nix`, which you shouldn't (have to) touch if you followed the steps above (at least, as of me making this... who knows when that might change 🤣).

After editing, just run `sudo nixos-rebuild boot` & then `reboot` to apply & (hopefully) boot into fresh system! 

---

## ==future tasks to do, post install!==
- ... install denki retro rice:
	- https://github.com/diinki/linux-retroism/tree/main
- optimise system features - battery & performance optimisation, touchpad, fingerprint reader, etc.
- btrfs snapshots & subvolumes explore
- **erase your darlings** - if needed?





#### Other resources:
- https://nixos.wiki/wiki/Btrfs#Installation_with_encryption
- &/or https://weiseguy.net/posts/how-to/setup/nixos-with-luks-and-btrfs/
	- can always [follow this thread for some install advice as well](https://discourse.nixos.org/t/btrfs-seeking-installation-advice/40826/16)
- https://gist.github.com/giuseppe998e/629774863b149521e2efa855f7042418
- The "[erase your darlings](https://grahamc.com/blog/erase-your-darlings/)" mindset explained



