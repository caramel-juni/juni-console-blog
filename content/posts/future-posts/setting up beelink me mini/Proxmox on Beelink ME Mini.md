---
title: ""
date: 2025-09-08
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

## Configuration steps:
- [Video going over general setup & optimisation steps](https://www.youtube.com/watch?v=qmSizZUbCOA) --> ==finish going through this!!==
- [It's better with Proxmox... Beelink ME Mini PC NAS](https://www.youtube.com/watch?v=VZo-2Fq8v7M)

### NETWORK:
- [x] Enabled virtual bridge across network interfaces so both can be used
      ![](Screenshot%202025-09-09%20at%202.03.32%20am.png)
      Need to do this otherwise only one interface will be auto-enabled on startup (the one connected as "slave" to the autostart-enabled `vmbr0` virtual network interface. think of this as a **virtual manager/`vNIC`** for all of your **physical interfaces** - so ***THIS*** should be set to **auto-start at boot**, ***NOT*** your the individual physical interfaces themselves if managed by the `vmbrX`!)
- [x] Make them VLAN aware
	- [ ] *In future - create one virtual interface for each physical to isolate them - one for LAN & one for management*

## Setup storage: `ZFS` 
Chose for:
- **Instant and Reversible Snapshots**
- **Native Data Compression** with `lz4`
- **Silent Error Detection and Correction**
- **Built-in Software RAID**
- Options for **Replication Between Nodes**, remote backups, & future HA
- **Optimised writing and block distribution**, resulting in better performance and less fragmentation

- https://cloudnews.tech/zfs-on-proxmox-ve-the-filesystem-that-changes-everything/
- [Proxmox Storage Secrets: LVM, LVM-Thin, ZFS & Directory Setup Made Easy](https://www.youtube.com/watch?v=YxpCVAC_H1o)
- https://www.instelligence.io/blog/2025/08/choosing-the-right-proxmox-local-storage-format-zfs-vs-lvm/
- [Even for single drives...](https://www.reddit.com/r/Proxmox/comments/wroqrb/proxmox_single_drive_should_i_use_zfs_or_go_with/)

***The trade-off: it’s RAM-hungry (rule of thumb: 1 GB per 1 TB raw storage, plus headroom). At least `8GB`.*** 

Create within GUI: `Node > ZFS > Create: ZFS.` Select unused disk, ensure `Add Storage` is ticked, `ashift = 12`, and set your desired `RAID` level (for me, single disk for now, can migrate to a larger setup as add more drives).
![](Screenshot%202025-09-09%20at%202.21.01%20am.png)
## SMB Share:
- [Video going over general setup & optimisation steps](https://www.youtube.com/watch?v=qmSizZUbCOA) --> ==finish going through!!==
### Enabling IMMOU passthrough:
- https://pve.proxmox.com/wiki/PCI_Passthrough ==finish going through & check passing GPU correctly!!==
- [x] Using [this guide](https://github.com/TechHutTV/homelab/blob/main/storage/README.md#ensure-iommu-is-enabled) & this video
- https://forum.level1techs.com/t/beelink-me-mini-proxmox-on-mmcblk-mini-howto/231244/2
### LXCs & VMs & services
- [5 Best Services to Run on Proxmox (What I Always Use)](https://www.youtube.com/watch?v=qFUieNOFYO4)
- [Install tailscale](https://www.youtube.com/watch?v=JC63OGSzTQI)
- copying over mc server & maybe installing management system for it (pterodactyl?)

### Securing Proxmox
- firewall
- autoupdates
- etc. (search YT)

### Backup (server? via smb) & Alerts
