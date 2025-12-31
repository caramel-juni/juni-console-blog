---
title: Making a shared NTFS drive play nice with Steam/Proton on Arch
date: 2025-12-31
description: Fixing games hanging on launch due to shared drive/file permission errors for Steam/Proton
toc: true
math: true
draft: false
categories:
  - arch
tags:
  - steam
  - proton
  - permissions
  - linux
---
Recently, I ran into issues getting certain Steam games running when installed to an NTFS internal SSD that I'd formatted to share across my dual boot Arch Linux and Windows 11 machine. They would hang on boot after pressing `Play`, and occasionally produce the following Steam log (stored in my home directory, `~`).

> TIP: **To generate live Steam logs to assist with troublehooting, launch Steam from the CLI with `steam PROTONLOG=1` - which will also create files at `~/steam-*.log` with debug information.**

Here was the error I was running into that indicated this was perhaps a permissions issue with how I'd mounted the shared SSD, preventing Proton & Wine from accessing the shared drive's game files:

``` bash
wineserver: pfx is not owned by you
wine: failed to open "c:\windows\system32\steam.exe": c0000135
```

Checking the permissions on the drive itself with `cd /mnt/424EDDFB783812E5` and `ls -lahs`, I could see the folder was owned by `root`, not the user that Steam was running under (identified with `id`). 

Further, it was `auto`mounted via GVFS / udisks as `root` within my `/etc/fstab` file, as indicated by the following entry:

``` bash
/dev/disk/by-uuid/424EDDFB783812E5 /mnt/424EDDFB783812E5 auto nosuid,nodev,nofail,x-gvfs-show 0 0
```

Because `NTFS` does not support Unix ownership, **ownership must be set at mount time via this file.**

Thus, I needed to re-mount the shared `NTFS` drive & edit this entry to ensure Steam & Proton could access the game files properly!

---

# The fix:

## 1. **Fix Mounting Strategy**

Edit the `fstab` file with `sudo vim /etc/fstab` to something like:
``` bash
UUID=424EDDFB783812E5  /mnt/424EDDFB783812E5  ntfs3  uid=1000,gid=1000,rw,exec,noatime,nofail,x-gvfs-show  0  0
```
- Replace `uid` and `gid` with the `id` of your user that runs Steam/Proton
- Replace `UUID` with that of your corresponding disk (find this via `blkid`)
- Add `x-gvfs-show` to show the drive in your file explorer `GUI`
- Ensure `exec` is added so any executables can be run!

Once this is edited, ensure you're not inside the disk and `umount` it (adding `-l` if you run into `target busy` errors):

``` bash
sudo umount -l /mnt/424EDDFB783812E5
```

Reloaded `systemd` mount units to process changes to the `/etc/fstab` file: 

``` bash
systemctl daemon-reload
sudo mount -a
```

Now, verify that the disk ownership has been adjusted to your current user with `ls -lahs`!

## 2. **Regenerate Proton prefixes & cache**

To ensure that Proton works smoothly, you'll need to potentially regenerate proton prefixes & clear the cache, if you attempted to run the games previously on the old mounted drive.

Exit steam, and then remove the old proton prefixes & cache with the following:

``` bash
steam -shutdown

# Replace with your drive mount path & associated steam /compatdata folder
rm -rf /mnt/424EDDFB783812E5/SteamLibrary/steamapps/compatdata

# Clear proton shader cache
rm -rf ~/.local/share/Steam/steamapps/shadercache
```

Now, just open steam again (after an optional `reboot` to clean things up) and attempt to run the game with `steam PROTONLOG=1`, to ensure the logs are flowing to check everything is going smoothly! 

Hopefully this should resolve any file permission issues, and if not, continue to troubleshoot via the `CLI` proton logs! <3
