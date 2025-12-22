---
title: Arch Quickies - Auto btrfs snapshot script
date: 2025-12-22
description: A simple script to create periodic btrfs snapshots of home and root subvolumes
toc: true
math: true
draft: false
categories: arch
tags:
  - arch
  - btrfs
  - snapshots
  - grub
  - subvolume
  - script
---

## Auto snapshots with `btrfs`

Using the following script, you can create and manage periodic `btrfs` snapshots of the `/home` and `/root` subvolumes. Ensure to test the manual `sudo btrfs subvolume snapshot -r` commands until they work with your own system subvolume setup, before committing them to the script and running it!

```bash
#!/bin/bash
set -e

SNAPSHOT_DIR="/.snapshots/manual"
RETENTION_DAYS=7


echo "Current size of snapshot directory:"
sudo du -sh "$SNAPSHOT_DIR"

# Create snapshots of root and home
sudo btrfs subvolume snapshot -r / $SNAPSHOT_DIR/root_$(date +%F_%H-%M)
sudo btrfs subvolume snapshot -r /home $SNAPSHOT_DIR/home_$(date +%F_%H-%M)

# -------------------------------
# Prune old snapshots (older than X days)
# -------------------------------

echo "Pruning snapshots older than $RETENTION_DAYS days in $SNAPSHOT_DIR..."

echo "Disk usage before pruning:"
sudo du -sh "$SNAPSHOT_DIR"

# Find directories older than RETENTION_DAYS and delete them
sudo find "$SNAPSHOT_DIR" -maxdepth 1 -mindepth 1 -type d -mtime +$RETENTION_DAYS \
  -print -exec sudo btrfs subvolume delete {} \;

echo "Disk usage after pruning:"
sudo du -sh "$SNAPSHOT_DIR"

echo "Pruning complete."

```

Then, adjust it to run automatically every `X` days with `systemd timers`, tailored to a time period of your liking!

Create the `systemd` service file with `sudo vim /etc/systemd/system/btrfs-autosnapshot.service`:

``` bash
[Unit]
Description=Btrfs Auto Snapshot

[Service]
Type=oneshot
ExecStart=/usr/local/bin/btrfs-autosnapshot.sh

```

... as well as the linked timer file with `sudo vim /etc/systemd/system/btrfs-autosnapshot.timer`:

``` bash
[Unit]
Description=Run Btrfs auto snapshot every 2 days

[Timer]
OnBootSec=10min
OnUnitActiveSec=2d
Persistent=true

[Install]
WantedBy=timers.target

```

Then, simply enable them with:

``` bash
sudo systemctl daemon-reload
sudo systemctl enable --now btrfs-autosnapshot.timer
```

You can check the new timer task's status with `systemctl list-timers --all | grep btrfs-autosnapshot`, and check the logs of the last time it was run with `journalctl -u btrfs-autosnapshot.service`.

The possibilities from here are limited only by your imagination (and time, lol) - you could run this as an update hook, if desired, to create automatic rollback snapshots when updating your precious `Arch` install! Adding the most recent one as an additional GRUB entries could be a cool future project, too... and [looks like there's a repo for this, too](https://github.com/Antynea/grub-btrfs)!

That's it from me this time - *happy snapping! <3*
