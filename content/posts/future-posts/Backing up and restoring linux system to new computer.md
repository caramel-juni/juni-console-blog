---
title: "Backing up linux .config & apps to move to a new device/distro"
date: "2024-12-25"
description: "a distro hopper's delight"
toc: true
math: false
draft: true
categories:
  - linux
tags: 

---


basically to preserve user settings, if all installed under user juni-low, config files are at `/home/juni-low/.config/

so copy that folder & reinstall on new system


### copy user configuration files:

`cd /home/[user]/

`sudo tar cvzf configs-backup.tgz .config/


OR 

### copy entire /home/ folder to an external ssd
using rsync to copy entire /home/ folder with no compression (use rsync instead of cp as it copies all files with permissions retained):

mount external ssd to a folder to access contents:
`sudo fdisk -l
(lists the connected disk drives and their corresponding locations - like `/dev/sda1)

`sudo mkdir -p /mnt/externalssd
(creates a folder in which you can access files stored on this external ssd)

`sudo mount -t exfat /dev/sda1 /mnt/externalssd
(now putting files in `/mnt/externalssd` will store them on the external ssd)


sudo rsync -avh --progress /home/ /mnt/externalssd/home-backup



https://help.ubuntu.com/community/BackupYourSystem/TAR
https://askubuntu.com/questions/7809/how-to-back-up-my-entire-system