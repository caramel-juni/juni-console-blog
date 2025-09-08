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
- [Video going over general setup & optimisation steps](https://www.youtube.com/watch?v=qmSizZUbCOA) --> ==finish going through!!==
- [It's better with Proxmox... Beelink ME Mini PC NAS](https://www.youtube.com/watch?v=VZo-2Fq8v7M)

### NETWORK:
- [x] Enabled virtual bridge across network interfaces so both can be used
- [x] Make them VLAN aware
	- [ ] *In future - create one virtual interface for each physical to isolate them - one for LAN & one for management*

## SMB Share:
- [Video going over general setup & optimisation steps](https://www.youtube.com/watch?v=qmSizZUbCOA) --> ==finish going through!!==
### Enabling IMMOU passthrough:
- https://pve.proxmox.com/wiki/PCI_Passthrough ==finish going through & check passing GPU correctly!!==
- [x] Using [this guide](https://github.com/TechHutTV/homelab/blob/main/storage/README.md#ensure-iommu-is-enabled) & this video
- https://forum.level1techs.com/t/beelink-me-mini-proxmox-on-mmcblk-mini-howto/231244/2
### LXCs & VMs & services
- [5 Best Services to Run on Proxmox (What I Always Use)](https://www.youtube.com/watch?v=qFUieNOFYO4)
- [Install tailscale](https://www.youtube.com/watch?v=JC63OGSzTQI)
- 