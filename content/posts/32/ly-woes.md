---
title: why, ly?? - Diagnosing a hung boot + login process after a seemingly innocuous Pacman -Syu
date: 2025-12-23
description: ""
toc: true
math: true
draft: false
categories:
tags:
---

ahhh, `ly`. how you betrayed me.
# The `TLDR;` + quickfix
After a (mostly silent) change in how `ly` interacts with `systemd` and its associated services, the [following commit](https://github.com/fairyglade/ly/commit/04d44472734d414e9d5cb557b0575e004e9aeb68) was added to the readme to clarify a new tweak when enabling interactions between `ly` and any other services (for me, that was `getty`) attempting to use the default `tty` service spawned at login. This was (**importantly**) accompanied by a change to the loading order within the `ly` `systemd` service file.

However, this meant that for users who had *already installed and set up `ly` a while ago*, this could cause `systemd tty` ownership conflicts between `getty` and `ly`, depending on which `tty` was enabled to run during login by default.

This meant that to fix this hanging at login, I needed to escape into a new `tty` and run the following commands:
``` bash
# check which ttys getty and ly are running on by default
sudo systemctl list-units | grep ly@
sudo systemctl list-units | grep getty@

# replace ttyX with whatever number tty ly is using  
sudo systemctl disable ly@ttyX.service
sudo systemctl disable getty@tty2.service
sudo systemctl enable ly@tty2.service

sudo reboot
```

Read on for the full context, as *this may differ depending on which `tty` is automatically used at login on your system, if customised or otherwise configured differently to mine.*

---

# The context:

A simple `sudo pacman -Syu`... that included the update to `ly` with the quiet changes to its `systemd` service file, `ly@.service`:

``` bash
[Unit]
Description=TUI display manager
After=systemd-user-sessions.service plymouth-quit-wait.service
++ After=getty@%i.service
++ Conflicts=getty@%i.service

[Service]
Type=idle
```

This resulted, upon a reboot, my boot process hanging and refusing to progress from the `plymouth` boot process animation/`LUKS` disk decryption prompt to my `ly` login manager. 

Initially, I thought it was a borked update, and so `chroot`-ed into the system to manually update & rebuild everything, as well as editing `/etc/default/grub` to enable verbose logging & disable the `plymouth` splash screen for troubleshooting purposes by changing `"logging=3 quiet splash"` to simply `"logging=7"`. 

> **Hot tip for future me** - if you need to just troubleshoot/change system files, try to drop into a new `tty` by pressing `Ctrl + Alt + FX` after boot, where `X` is the new `tty` instance number (e.g. `Ctrl + Alt + F2` spawns `tty2`, and so on). See [here](https://wiki.archlinux.org/title/Getty#Add_additional_virtual_consoles) for more details.


After regenerating the main `grub` boot config file with `grub-mkconfig -o /boot/grub/grub.cfg`, I rebooted to check the logs during boot.

The boot logs didn't seem to show anything was *wrong*, per se, but I began to suspect (after consultation with a friend) that maybe the boot process *was mostly fine* and that there was an issue with the next step - starting `ly` to log in.

---
# `ly` under the 'scope

As `ly` ran as an automatic `systemd` service on boot, this led us to checking their [github page](https://github.com/fairyglade/ly/) for installation instructions and discovering the [aforementioned commit](https://github.com/fairyglade/ly/commit/04d44472734d414e9d5cb557b0575e004e9aeb68), which revealed the potential `tty` ownership conflict (outlined in the `TLDR;` above).

Sure enough, after performing the below steps in the emergency `tty` spawned at hung login (and after a few reboots), the boot process was back to normal. 

> **Note:** I seemed to run into bugs during testing this where `ly` would successfully *start*, but upon entering my password, each individual character would appear in the prompt but then be replaced by the next one as I typed, and certain combinations of `Ctrl + `characters would be replaced, as if typing into a command line. It also prevented me from authenticating and when pressing `Ctrl + C`, half the screen would go black, like one half of the process died. 

> This was likely due to `getty` and `ly` *both* being enabled on the default `tty` that my arch install loaded by default, and actively fighting for control over one another for text input. This seemed to be resolved after performing the below steps in order, however, specifying `tty2`.

---
# The fix (step by step):

1. Drop into an emergency new `tty` when the boot process hangs - e.g. with `Ctrl + Alt + F2`. Log in with your user account when prompted.
2. Check which `systemd` services are running for `getty` and `ly` with `sudo systemctl list-units | grep ly`, etc. 
3. Disable `ly` on **whatever `ttyX` it is currently running on**, if any. 
   E.g. for me, `sudo systemctl disable ly@tty1.service`.
4. **Disable** `getty` on `tty2`: `sudo systemctl disable getty@tty2.service`
   *(`tty2` seems to be the `tty` that `ly` seems to like by default, at least for me on arch. Also mentioned [here](https://linuxvox.com/blog/arch-linux-switch-tty/#what-is-a-tty) that it's the first `tty` used for **text**-based interactions, as `ly` is not a **graphical** login manager, but a **text** based on. Just conjecture here, though):*
5. **Enable** `ly` on `tty2`: `sudo systemctl enable ly@tty2.service`
6. **Double check** what `systemd` services are enabled for `getty` and `ly` **now** with the command in step 2. Ensure that `ly@tty2.service` is **enabled** and `getty@tty2.service` is **disabled**.
7. Reboot (a couple times) and pray!

I dearly hope this may have helped some other lost souls, and endless thanks to my friend for accompanying me through the discovery & troubleshooting process, and teaching me a few `tty` tidbits along the way! 

*~ ☘️ juni ☘️*
