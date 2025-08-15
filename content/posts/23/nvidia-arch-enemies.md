---
title: "[Arch Tidbit]: Installing the correct NVIDIA modules"
date: 2025-08-15
description: 
toc: true
math: true
draft: false
categories:
  - arch-tidbit
tags:
  - arch
  - nvidia
---
Ahhh, `nvidia`. Don't we just *love* to **hate** you.

Here's a small little entry on a new little miniseries I'm going to call "Arch tidbits", where I post small **snippet-posts** of things that I've learnt from a combination of **[Arch Wiki](https://wiki.archlinux.org/title/Main_page)-surfing**, **troubleshooting** and **tears** *(aka anything where there isn't a "complete" guide available elsewhere, or where there **are some guides** but not entirely up to date / where I feel the need to iron out the process in my own head and get it down on netpaper in order to better understand it for my specific use case or architecture)*.

So, **onwards!**

---
# Ensuring that your `nvidia` modules are correctly installed:


### Guides:
- [Our Lord and Savior, the Arch Wiki NVIDIA page](https://wiki.archlinux.org/title/NVIDIA)
- [Helpful Video walkthrough](https://www.youtube.com/watch?v=-uN6tEEZT9g)


# Steps:
1. Check your **GPU family** with `lspci -k -d ::03xx`. 
   Output should include something like the following (mine): `NVIDIA Corporation TU104 [GeForce RTX 2070 Super`. The key bit is the codename, `TU104`.
   
   *You can also double check your [graphics card codename here](https://nouveau.freedesktop.org/CodeNames.html).*

2. Find your kernel version with `uname -r`. If you have `lts` or `zen` kernel specified (i'm just on `6.16.0-arch2-1`), **take note.**

3. Depending on your GPU family (for me, `TU104`) & kernel version (either `standard`, `lts`, or `any other`) select the [corresponding main `nvidia` driver package to install.](https://wiki.archlinux.org/title/NVIDIA)
   So, for me, since `TU104` is the `Turing` family, and I'm on the standard `linux` kernel, I would pick `nvidia-open`. 
   ![](/posts/23/Screenshot%202025-08-15%20at%2011.10.01%20pm.png)
   *However - technically, my Turing family card **also** works with the **proprietary `nvidia` module** - see [here](https://developer.nvidia.com/blog/nvidia-transitions-fully-towards-open-source-gpu-kernel-modules/), noting their wording of "**recommend**":
   "For newer GPUs from the Turing, Ampere, Ada Lovelace, or Hopper architectures, NVIDIA **recommends** switching to the open-source GPU kernel modules."*

4. Now, install your applicable `[nvidia-module]` alongside `nvidia-utils nvidia-settings` with:
   `sudo pacman -S nvidia nvidia-utils nvidia-settings`
5. Uninstall any older conflicting drivers (like `nvidia-dkms` etc.) at the prompts, and check with `sudo pacman -Q | grep "nvidia"` that only **ONE** main `nvidia` module listed in your family table above is installed.
6. Once done, **rebuild the initramfs** (general good practice) to make sure the new installed drivers are loaded & available at boot, and to update any new kernel hooks required by the driver change. Do so with: `sudo mkinitcpio -P` 
7. Then, just `sudo reboot`, cross your fingers & pray you boot in. 
8. To test whether it works, run `nvidia-smi` and your output should show a table containing your driver version and GPU details. Then, run `glxgears` for a live graphics test - you should see some gnarly gears pop up on the screen, meaning you're good to go! :3


