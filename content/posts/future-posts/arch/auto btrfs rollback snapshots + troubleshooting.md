---
title: ""
date: 2025-08-07
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

- --> main guide https://www.dwarmstrong.org/btrfs-snapshots-rollbacks/
	- also helpful cleanup script: https://www.dwarmstrong.org/update-arch/
	- [full arch install with encrypted btrfs subvolumes + quality of life tweaks](https://www.dwarmstrong.org/archlinux-install/)

- https://askubuntu.com/questions/1459350/how-to-restore-btrfs-snapshot-backup-of-root-partition-with-subvolume-for-home
- https://www.reddit.com/r/archlinux/comments/1p7ibk1/okay_how_do_i_roll_back_failed_updates/
- https://www.baeldung.com/linux/arch-boot-failure
- [Resetting Arch Linux](https://www.youtube.com/watch?v=2vbrFZiq2Hc)
- [Removing everything but essential packages](https://wiki.archlinux.org/title/Pacman/Tips_and_tricks#Removing_everything_but_essential_packages)
- [I want to reinstall Arch on my btrfs without loosing data from the home directory. The system is so damaged, that I can't use pacman anymore. What would be the simplest way? I have the home directory on a separate partition. Thanks for every advice!](https://www.facebook.com/groups/archlinuxen/posts/10160068546478393/)
- 





## further steps to troubleshoot:
- [x] [Arch Wiki rEFind](https://wiki.archlinux.org/title/REFInd#For_kernels_automatically_detected_by_rEFInd) - *"For `rEFInd` to support the naming scheme of Arch Linux [kernels](https://wiki.archlinux.org/title/Kernels "Kernels") and thus allow matching them with their respective initramfs images, you must uncomment and edit `extra_kernel_version_strings` option in `efi/EFI/refind/refind.conf`"* 
  ``` bash
extra_kernel_version_strings "linux-hardened,linux-rt-lts,linux-zen,linux-lts,linux-rt,linux"
	```
	- ***Warning:** Without `extra_kernel_version_strings` set, rEFInd will incorrectly pass the first initramfs it finds as the `initrd=` kernel parameter, instead of using the correct initramfs for the kernel. This will result in a failure to boot since the matching loadable kernel modules will not be available.*
	- *Without the above `extra_kernel_version_strings` line, the `%v` variable in `refind_linux.conf` will not work for Arch Linux [kernels](https://wiki.archlinux.org/title/Kernels "Kernels").*



- try `UUID` instead of `PARTUUID`, as seen below:
	- https://www.youtube.com/watch?v=KW1jbeLdzB8&t=29s
	- https://www.rodsbooks.com/refind/linux.html#efistub
- [x] run `efibootmgr -v` to check EFI partition layout
- check - [You must place your kernels in a directory other than the one that holds the main rEFInd .efi file. This is because rEFInd does not scan its own directory for boot loaders.](https://www.rodsbooks.com/refind/linux.html#efistub)
- check if using encryption or LVM
--> ==try and install grub instead
- https://www.youtube.com/watch?v=tCGL_FY3xeM&t=1750s