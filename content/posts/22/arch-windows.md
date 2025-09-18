---
title: Dual booting Arch & Windows from the same EFI Boot Partition
date: 2025-08-07
description: aka Living Hell
toc: true
math: true
draft: false
categories:
  - arch
tags:
  - arch
  - windows
  - dual-boot
  - refind
---

A while ago, my friend had played around with installing [Arch linux](https://archlinux.org/), and I warned her against choosing *it* as an OS for dual-booting due to how notoriously difficult.... Windows can be when playing with other OS's *rudely* occupying its boot drive... let alone one that's as DIY as Arch (comparatively) for the install, and a rolling release model lending to it being somewhat... *unpredictable*.

So, naturally, upon arriving home, I... *decided to do exactly that, on my main PC.*

Why? Because, like many people in this industry, I'm a masochist and like pain. Or I'm just crazy. And of course, the rose-tinted allure of "*arch btw*." Gotta try it at least once properly, right? So why not go full insane mode.

Now, to the first (& endlessly memed) step...

# 0. - Reading the Arch Wiki
Yes, I made the mistake (i jest; *blessing*) of **properly reading the Arch Wiki**. It only took me a dozen tries, and my, was it a ride. I learnt a lot, cried a bit, and **puzzled over the discrepancies between it and the myriad of existing, recent YouTube tutorials/install guides for dual booting Arch with Windows** (all advising to create an additional EFI partition to boot Linux from, when on the same disk).

Now, I was **cross-referencing like crazy**, given i was (crazy enough to be) doing this with my desktop workstation despite *very much* realising this was an extremely risky idea. However, after many back-and-forths, the long and short of it came down to: **Read The Fucking Wiki.** It's the **source of truth.**

**YouTube tutorials only get you *so* far** when dealing with edge cases, and *boy* were there a lot of edge cases. And it's *entirely* worth the extra few minutes of your time, *especially* when attempting to dual boot properly and minimise the risk of a Windows update freaking the fuck out after discovering another `EFI` partition and bricking one (if not both) OS's. *Please* make sure to follow the below recommendations to prevent a *lot* of potential future pain:

# 1. - Pre-requisite checks:

1. Do **NOT** create another `EFI` partition to boot `Arch` from when there is an existing one created by Windows. Even if only a *chance*, with Microsoft's history, the line: *"An additional EFI system partition should not be created, as it may [prevent Windows from booting](https://support.microsoft.com/en-us/help/2879602/unable-to-boot-if-more-than-one-efi-system-partition-is-present)."* [from the Wiki](https://wiki.archlinux.org/title/Dual_boot_with_Windows) **should very much be heeded.**

2. To *ensure* that your **existing Windows** `EFI` partition **has enough space to store the Arch bootloader and any other future ones that you wish to install**.
   
   As Windows typically creates a piddly `100MiB` `EFI` partition by default (only `30MiB` of which is typically used by Windows, it leaves little room for expansion or the potential for other bootloaders. Whist linux-based bootloaders don't take up anywhere *near* as much space as Windows' does... they can get large when including `initramfs`, your kernel and any CPU fixes needed per distro... 
   
   Plus, I wanted to try and do it by the book, especially when running out of space on your `EFI` partition increases the risk of boot loaders misbehaving over time, and in some cases, Windows [nuking your desired Arch bootloader](https://www.reddit.com/r/archlinux/comments/1ca2uyk/why_should_i_or_should_i_not_share_efi_in_a/) upon updates)
   
   To do this, if you're unfortunate enough to be stuck with the default `100MiB` `EFI` Windows-created partition, I'd recommend using either [MiniTool Partiton Wizard](https://www.partitionwizard.com/partitionmanager/increase-efi-system-partition-size.html) (as spammy and icky as it comes across - *you can uninstall it right after*) or [GParted](https://pureinfotech.com/resize-partition-windows-10-gparted/#resize_partition_gparted_windows10) (advanced use cases - be careful) to **resize your `EFI` boot partition to something like `4GiB` to be safe.** 
   
   Now, full disclosure - this is **not to be done lightly**, and you should **definitely make a backup of the EFI partition before you do this**... and not subsist on crossed fingers and good vibes alone, like I did.... *(thankfully, I haven't run into any issues... **yet**.)* 
   
   However, I did so after reading & noting down the `EFI System Partition` (`ESP`'s) `PARTUUID` & `UUID` values - which are typically stored in a `NVRAM` firmware entry and ***thus*** are the main values **used to correctly identify the newly-expanded `EFI` partition**, so if anything *did* go wrong, I could still point Windows to find and boot from it.

3.  Ensure to **Disable Fast Startup and Hibernation** modes on Windows via `powercfg /H off` in an elevated Powershell prompt, then power cycle (full shutdown) and check Windows registry keys for this feature to ensure they are off. **See [here](https://wiki.archlinux.org/title/Dual_boot_with_Windows#Disable_Fast_Startup_and_disable_hibernation) as to why.**

Now, once my `EFI` partition was resized, listed as "healthy" in the Windows disk manager, and showing up as `4.1G` in the live Arch install, I proceeded to the fun part - **setting up my Arch system**, guided by both [The Wiki](https://wiki.archlinux.org/title/Dual_boot_with_Windows) (read **the entire dual-booting with Windows article before proceeding**) and this (incomplete) guide [here](https://nic96.dev/blog/beginners-guide-dual-booting-arch-linux-windows/).).


---
# 2. - The "fun" part - Installing Arch!

### Partitioning drives, creating the filesystem, setting the SWAP
(no need to create an `EFI` partition, as will be using expanded windows one)
#### Some Terminology:
- **Partition:** a logical division of a drive that can be treated as its own section (containing its own filesystem, etc.)
- **Filesystem:** a method and data structure defining how an OS can store, organise and access files on a storage device. Different filesystems have different use cases and limitations (`EXT4`, `NTFS`, `FAT32`).
- **SWAP**: disk space allocated for the filesystem to use as virtual memory if/whenever available physical memory (`RAM`) is exhausted.

List your current drives with `fdisk -l`, and check the output **carefully** for your desired install disk (e.g. `/dev/nvme1n1` for me). I chose to use the `TUI` partitioning tool `cfdisk` to create my Arch filesystem, entering the `TUI` with `cfdisk /dev/nvme1n1`.

I then set my partitions: the `root` (`/`) system, and the `SWAP`. If I were starting again, I would've separated my `root` and `/home` partitions to make distro-hopping, security (isolation) & user-file-level backups a little easier, but oh well.

- `/dev/nvme1n1p6 --> 100G Linux Filesystem` --> to be used as `root` system.
- `/dev/nvme1n1p7 --> 30G Linux SWAP` --> to be used as `SWAP`.

I then **initialised the filesystem type**: choosing `ext4` for my `root` (for general balance of performance, reliability and features; but do consider snapshot-friendly alternatives like `btrfs`). 
- `mkfs.ext4 /dev/nvme1n1p6`

Then, I made and activated the `SWAP` partition:
- `mkswap /dev/nvme1n17`
- `swapon /dev/nvme1n1p7`

Now... for the `EFI` partition!

But first, reading the Arch wiki... *If you are installing Arch Linux on an UEFI-capable computer with an installed operating system, like Windows 10 for example, it is very likely that you already have an EFI system partition.*

> **Some Terminology:**
> **EFI (or ESP):** The `EFI` system partition (also called `ESP`) is an OS independent partition that acts as the storage place for the UEFI boot loaders, applications and drivers to be launched by the UEFI firmware. It is mandatory for UEFI boot. 

## So - be sure to [check whether existing EFI partition is the ESP - see here for detais!](https://wiki.archlinux.org/title/EFI_system_partition#Check_for_an_existing_partition)

Start with:

`fdisk -l`

--> e.g. for me, `/dev/nvme1n13` has TYPE: `EFI System`
mount it to local FS to check that it check it contains `EFI` directory
mount `/dev/nvme1n13` `/mnt`
`ls /mnt`
if it does, good to go! if not, see the link above.

### mount root partition to `/mnt`

mount `/dev/nvme1n1p6` `/mnt`

### mount (existing) windows EFI partition (for me, `/dev/nvme1n1p3`) to `/mnt/efi`
`mkdir /mnt/efi`
`mount /dev/nvme1n1p3 /mnt/efi`


- install required packages:
`pacstrap -K /mnt base base-devel linux linux-firmware linux-headers amd-ucode sudo git vim htop curl wget bluez bluez-utils networkmanager gcc fastfetch pipewire make cmake cargo mpv efibootmgr mtools man-db man-pages tealdeer dhcpcd resolvconf` ...

(using providers `pipewire-jack`, `openresolv`, `rustup` when prompted)

- generate [fstab](https://wiki.archlinux.org/title/Fstab) 
`genfstab -U /mnt >> /mnt/etc/fstab`
check with
`cat /mnt/etc/fstab

switch into new arch system with

`arch-chroot /mnt`
*This allows you to run commands as if you had booted into that system - even though you’re still technically running under the host OS (on the live boot drive)*

use `fastfetch` and voila!

## MAKE SURE YOU RUN:
 `mkinitcpio -P` - tries to include all necessary **kernel modules** and **firmware** for the devices your system might need to boot. The warning:

#### change root pw, add (wheel/sudo privs) users, timezone, locale, hostname, network on startup
- set root password with `passwd`
- `useradd -m -g users -G wheel,storage,power,audio,video -s /bin/bash juniarch**
- change locale:
- set timezone & synchronise clock
- set hostname - `echo "arch" >> /etc/hostname` and then edit `/etc/hosts` to include localhost as your desired `hostname.local`, e.g.:
	- `127.0.0.1      arch.localdomain     arch`
- `systemctl enable bluetooth` 
- `systemctl enable NetworkManager` --> starts network on boot
- `systemctl enable dhcpcd` (`dhcpcd` will call `resolvconf` (i.e. `openresolv`) as needed.)

### install & enable bootloader
as am booting off an existing EPS (windows-created), & whilst it *can* be used with `grub`, apparently `rEFind` is good for a simplified UI & autodetecting existing EFI boot entries (on `UEFI`), so I thought I'd try that.

`pacman -S refind`
run setup script --> `refind-install`. Should set it as default boot manager. check with `efibootmgr` - `BootOrder:` line.

This also runs `mkrlconf` as `root`, and will attempt to find your kernel in `/boot` and automatically generate `refind_linux.conf` accordingly.

## HOWEVER!!!
- ⚠ **Do not trust the auto-generated `/boot/refind_linux.conf`** ⚠
	- See why this is the case [here](https://www.reddit.com/r/archlinux/comments/1bwbb6p/refind_not_configuring_root_partition_right/) -- as the script detects `ISO` boot conditions instead of the **underlying file system.** ***Is a known flaw!***
	  See video [reconfiguring it properly here](https://www.youtube.com/watch?v=KW1jbeLdzB8 ).
Check and fix it manually by filling in your corresponding new `/root` system's Partition UUID (`PARTUUID`):
- Get correct PARTUUIDs & UUIDs of root disk with `blkid /dev/nvme1n1p3` (for example).
- Generally is recommended to use `PARTUUID` over `UUID` as (apparently):
	1. `PARTUUID` doesn't depend on the presence of a filesystem (as is assigned by `GPT`), and will thus **exist even on empty partitions**.
	2. It tends to be **more stable for dual-booting** as it will **always point to the exact partition** instead of a filesystem (which may move around... looking at you, Windows Updates).
	3. Can prevent `kernel panik !!1!` when booting as `PARTUUID` is sometimes resolved **earlier** than filesystem `UUIDs`.
    example within `/boot/refind_linux.conf`:
``` bash
"Boot Arch Linux" "rw root=PARTUUID=87463764-aaaa-aaaa-aaaa-76234876486723 add_efi_memmap initrd=/initramfs-linux.img"`
```

**You only need to do this once**, then it will work on reboot and rEFInd will autodetect your Arch kernel.

Then, feel free to edit any further settings you'd like to change (default boot order, icons, etc.) in `/efi/EFI/refind/refind.conf


#### One extra step: Check that you didn't overwrite or delete any existing EFI entries (like `/EFI/Microsoft` - that would be bad)

- Mount your underlying `OS`'s `EFI` partition and check that (for example) the Windows bootloader files are still there:
```bash
sudo mount /dev/sdXY /mnt  # sdXY or nvmenX = your EFI partition
ls /mnt/EFI/Microsoft/Boot/
# Should show files like bootmgfw.efi
sudo umount /mnt

```

Now - to reboot into your new Arch system!

- Exit `chroot` environment with `exit`
- Unmount all partitions: `umount -lR /mnt
- Now the directories you previously mounted should no longer be listed as mountpoints when running `lsblk`.
- Finally, `shutdown now` & **eject USB boot drive**

---
# What happened next...
And of course, as the `rEFind` boot menu loaded up (had to manually change boot order in `UEFI BIOS` as it overwrote that described by `efibootmgr`) and i selected the glorious Arch logo, I got dropped into an emergency shell with the error:
`device "PARTUUID" not found`
... despite that device `PARTUUID` listed being the correct one for my `/root` drive.

# Time to troubleshoot:
After booting into Arch live ISO, mounting disks as specified before (existing `EFI`, `/root`, and setting `SWAP` on), and then using `arch-chroot /mnt` to enter the live preview system, I tried...
- running `mkinitcpio -P` (as boot drive is `nvme` & needs additional auto-setup)
- uncommenting the `extra_kernel_version_strings` field in`[esp-directory]/EFI/refind/refind.conf` & adding those seen in the example on the [Arch Wiki (rEFind)](https://wiki.archlinux.org/title/REFInd#For_kernels_automatically_detected_by_rEFInd), 
	- Because, *"For `rEFInd` to support the naming scheme of Arch Linux [kernels](https://wiki.archlinux.org/title/Kernels "Kernels") and thus allow matching them with their respective initramfs images, you must uncomment and edit `extra_kernel_version_strings` option in `efi/EFI/refind/refind.conf`"* 
... but still to no avail. 

But I had not yet tried my greatest strategy.

**I made a troubleshooting plan**, and then... **took a break** (when it hit 2am).
And then **came back the next day to look over it.**

Surprise surprise, the answer lay within... 

#### THE PROBLEM: FAILING TO SPECIFY THAT I WAS USING `PARTUUID` IN `/boot/refind.conf`...
Somewhat obviously (yet not to my 2am brain), you need to DECLARE the kind of identifier you're booting from. i.e., include `PARTUUID` within the line `root=PARTUUID=87463764...`
 e.g. (fixed version)
 ``` bash
"Boot with standard options" "rw root=PARTUUID=87463764-aaaa-aaaa-aaaa-76234876486723 add_efi_memmap"
 ```

So, um. Yeah. Fun.

I then cleaned up & removed old boot images from my `/efi/EFI/` directory (an old, now wiped Manjaro install), and tinkered around with the `[esp-directory]/EFI/refind/refind.conf` file to change my boot options (see [here](https://rodsbooks.com/refind/configfile.html) for a list of all parameters & how to use them).

### And then, bam! 
- **Arch Linux** installed
- ... Dual booting from the **same drive** with an **existing Windows 11 installation**
- ... using the **same EFI partition** as Windows
- ... using a bootloader (`rEFind`) capable of [launching kernels as](https://wiki.archlinux.org/title/REFInd) `EFI boot stubs` ("graceful", some might say) 
- ... that was made *way* harder than it needed to be by the absence of one freaking word (`PARTUUID`) 
All without bricking my system.

***Oh, isn't tech just oodles of fun?***

# Here are some links to some lovely & helpful Arch Install Guides, if you prefer to learn that way!:
 (*just* Arch btw, without the Beauty and Magic of running it alongside... Windows...)
- https://github.com/silentz/arch-linux-install-guide
- [Beginner friendly ARCH LINUX Installation Guide and Walkthrough](https://www.youtube.com/watch?v=5DHz23VQJxk)


# Arch/Linux Dual Boot Video (see warning!)
- [How to Dual Boot Arch Linux and Windows 11 (2025)](https://www.youtube.com/watch?v=1J_Z_pzzbMo&t=549s) --> **WARNING: CONFLICTS WITH ARCH WIKI ADVICE AGAINST CREATING ANOTHER EFI PARTITION**


---

# Fixing Time Discrepancies (between Windows & Arch)

> Side note: you may encounter system time discrepancies between Linux/Windows when dual booting from the same drive - this is because: 
- Windows **uses the local time on the hardware clock by default (`RTC`)**
- Whereas Linux uses (the more reliable) **Coordinated Universal Time** (`UTC`) by default.
Given `UTC` is generally more reliable and makes sense (is independent of timezones & Daylight Savings `DST`, a single source of truth)... and i *wanted* to switch Windows over to using RTC with a regedit... but articles like [these](https://www.howtogeek.com/323390/how-to-fix-windows-and-linux-showing-different-times-when-dual-booting/) reminded me how **Windows rarely plays nice with these kind of things,** and **I would rather fix my Arch install than my Windows one.** So, to switch Linux to `RTC`:
- `sudo timedatectl set-local-rtc 1 --adjust-system-clock`
- and check with `timedatectl`



---

# Linux Ricing Plan:
- [Getting started with dotfiles](https://webpro.nl/articles/getting-started-with-dotfiles)
- [Dotfiles management resources & tutorials](https://github.com/webpro/awesome-dotfiles?tab=readme-ov-file)
- [Linux Ricing Guide](https://www.youtube.com/watch?v=jFz5gLqv-FM) (denkii)

# Ricing Components:
- dotfile manager
	- [chezmoi](https://www.chezmoi.io/what-does-chezmoi-do/)
	- [yadm](https://github.com/yadm-dev/yadm)
- login manager
	- `ly`
- window manager
	- `wayland`
	- `i3`
- compositor
	- `picom` (transparency, shadows,)
- notification daemon
- terminal emulator
	- `kitty` - renders images, very fast, multiple tabs, sessions
- screenshot tool
	- `flameshot` (simple but a lot of capabilities)
- file browsers (`CLI`)
	- `nnn` - fast, lightweight `CLI` file browser
- file browser (`GUI`)
	- `Thunar` (from xfce)
- blue light filter
	- `redshift`
- web browser
	- `firefox`
	- `librewolf`
- code editor
	- `nvim`
	- `lazyvim`
	- `nvchad`
	- `vscode`
- fonts
	- `Hack` (terminal)
	- `Nerd Fonts`
- wallpapers
	- `r/unixporn`
	- `arch discord`
- GTK (gnome software) theme manager
	- `lxappearance`
- system maintenance script
	- https://www.youtube.com/watch?v=o03_cfOnl84
	- see [dotfiles here](https://github.com/kurealnum/dotfiles)

---
# Backups & Snapshots - [`timeshift`](https://thelinuxcode.com/timeshift-backup-tutorial/)

**snapshot tool: `timeshift` (as using `ext4` filesystem):**
- `yay -S timeshift`
- `sudo timeshift --list-devices`
	  This tells you which partition Timeshift sees as eligible (e.g., `/dev/sda2`).
- `sudo timeshift --check`
- modified config (`/etc/timeshift/timeshift.json`) to include `/home` directory in backup, and only exclude the cache: `**/home/.cache`
- `sudo timeshift --create --comments "Full system + home pre-rice" --tags D`
- create a small file like `hello.txt` in home directory, then restore previous snapshot with: `sudo timeshift --restore`. make sure **NOT** to reinstall grub2 bootloader, as not using grub.

Generally a good practice to take backups of the following folders pre-upgrading Arch's firmware:

- `/etc`: System configs, network, fstab, pacman.conf
- `/usr`: System binaries, libraries, apps
- `/var`: Pacman cache, logs, systemd state
- `/boot`: Kernel & initramfs (important for kernel upgrades)
- `/lib, /lib64, /sbin, /bin`: Core system binaries

To check sizes of installed snapshots:

`sudo du -sh /timeshift/snapshots/*`

**Tip:** Can create a `pacman` hook to run an auto-snapshot with `timeshift` every time a full system upgrade is performed (with the options to cancel it if need be) - see [here.](https://forum.manjaro.org/t/howto-create-useful-pacman-hooks/55020)

Also, to run routinely, I added an entry to my user's crontab with `sudo crontab -e -u juniarch`, because `timeshift`'s CLI documentation is unclear as to whether just setting the `schedule_monthly` to `true` in `/etc/timeshift/timeshift.json` config file is sufficient to enable this. ==Will test to see by removing crontab & just enabling via the config file - July 2025==

`crontab`: 
1. Will first need to set sudo with NOPASSWD for timeshift: 
   `sudo visudo`
   Add line: `juniarch ALL=(ALL) NOPASSWD: /usr/bin/timeshift`
2. Then create/add to user crontab with:
   `sudo crontab -e -u juniarch`
   Add line: `0 0 1 * * sudo /usr/bin/timeshift --check --scripted --create --tags M` (for monthly snapshots)

# General use commands:
- **Create snapshot:** `sudo timeshift --create --comments "comment here" --tags D`
- **Delete snapshot:** `sudo timeshift --delete` and selecting the number of the snapshot on prompt.
	- **Delete specific snapshot:** `sudo timeshift --delete --snapshot "name"
- **List snapshots:** `sudo timeshift --list`
- **List size of all snapshots:** `sudo du -sh /timeshift/snapshots/*` (or wherever yours are located, if custom)

---
# Arch: Some TLC
- https://wiki.archlinux.org/title/System_maintenance
- [What to do AFTER you've installed ARCH LINUX - beginner friendly post-install guide](https://www.youtube.com/watch?v=-puvglgx6Qs)
- [A friendly guide to Pacman on Arch Linux and Arch-based Distros](https://www.youtube.com/watch?v=Napx5_6iBJ4)

---
# Arch: Upgrading & Best Practices (flags)

`pacman` (**official Arch Repository**):
- Always combine `-Syu` to [avoid partial upgrades that can break the system](https://wiki.archlinux.org/title/System_maintenance#Avoid_certain_pacman_commands).
- `s` = `sync/install`
- `y` = `refresh package database`
- `u` = `upgrade ALL packages` (as Arch is a **rolling release** - *"when new [library](https://en.wikipedia.org/wiki/Library_\(computing\) "wikipedia:Library (computing)") versions are pushed to the repositories, the [Developers](https://archlinux.org/people/developers/) and [Package Maintainers](https://wiki.archlinux.org/title/Package_Maintainers "Package Maintainers") **rebuild all the packages** in the repositories that need to be rebuilt against the libraries"* - thus necessitating keeping **all packages up-to-date** to avoid dependency conflicts.)
- `--needed`: Don't reinstall already-installed packages - prevents unnecessary downloads.
- `-Q`: queries local database of installed packages & dependencies
- `--ignore PACKAGE`: sometimes useful to ensure certain packages are installed **in the correct order, i.e. not before their dependencies** 
	- *may not matter: as are just "warnings* from `pacman`. likely best to just take a snapshot --> check arch news --> roll with update.

**UNINSTALL & CLEAN UP:**
- `-Rns` = remove package `-R`, **unneeded dependencies** `s`, and config files `n`

Same `-Syu` & `-Rns` flags recommended for `yay`, which installs from **both** the **official Arch Repository** *and* the `Arch User Repository` (`AUR`). Also may consider:

- `--removemake`: Removes make dependencies after build (cleans up space)

#### Clean up space from orphaned packages:
- `sudo pacman -Rns $(pacman -Qtdq)`
#### Clear old package caches
- `sudo paccache -r` (keeps 3 versions)
- `sudo paccache -ruk0` (all except current)

## TLDR:
- Always read **Arch News** before major upgrades: https://archlinux.org/news/
	- If you have trouble with this - use the [email list](https://lists.archlinux.org/mailman3/lists/arch-announce.lists.archlinux.org/) / [RSS feed](https://archlinux.org/feeds/news/) / a pacman hook like [informant](https://aur.archlinux.org/packages/informant/) to prevent you from updating if you haven't read the latest Arch News ;).
- `-Syu` is king!
- Use `timeshift` or `btrfs snapshots` before large updates
- Use `pacman -Qdt` to find unneeded dependencies

---
