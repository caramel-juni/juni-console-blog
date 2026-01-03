---
title: Configure an unprivileged Proxmox LXC as a Tailscale Subnet Router (2026)
date: 2026-01-03
description: ""
toc: true
math: true
draft: false
categories:
  - tailscale
  - proxmox
tags:
  - linux
  - subnet-router
  - exit-node
---

After spinning up a new unprivileged Proxmox LXC with an installed (but not yet configured) Tailscale node, using something like a PVE helper script, you may want to turn it into a [subnet router](https://tailscale.com/kb/1019/subnets) to access your internal LAN devices remotely. Now... **how did I do this again?**

***Full disclaimer:** this is nothing spectacularly new, but rather just a conglomerate of the collected instructions from the following two pages in the Tailscale docs, specific to unprivileged `LXCs` in **`Proxmox Virtual Environment 9.1.1`**. I figured I'd put it all together just to simplify it for myself/future installs/other souls out there.*

**Main References:**
- [Subnet Router - Tailscale Docs](https://tailscale.com/kb/1019/subnets)
- [Tailscale in (unprivileged) LXC containers](https://tailscale.com/kb/1130/lxc-unprivileged)

---

Previously, I ran a Tailscale node as **both** a subnet router **and** an exit node with a spaghetti tailscale config in my last Proxmox environment, so I figured I'd try and take the time to step through it properly this time and write it up.

# 1. Enable LXC access to `/dev/net/tun`
First, when running the Tailscale subnet router as an unprivileged `LXC` in Proxmox, open a `PVE` root shell and add the following lines to the Tailscale container's config file. E.g. for the Tailscale container with `id=101`, run `vi /etc/pve/lxc/101.conf` and add:

``` bash
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

This allows the LXC to create and access the `/dev/net/tun` device to form privileged tunnelled connections.

After saving this, start the container (id `101`) with `pct start 101`.

---
# 2. Installing & Configuring the Tailscale daemon

Once inside the container, if you haven't installed Tailscale already, do so with:
`curl -fsSL https://tailscale.com/install.sh | sh` (see [here](https://tailscale.com/download/linux) for the latest command to run for linux, as this may change)

Before starting the Tailscale node, you need to adjust the Tailscale config file to allow `IP` forwarding. For linux distros that use `/etc/sysctl.d/99-tailscale.conf` (you'll know this if `/etc/sysctl.conf` doesn't exist), run the following commands to edit the file:
``` bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

Otherwise, run the below commands to do the equivalent to `/etc/sysctl.conf`:
``` bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
```

Now, ensure that the Tailscale daemon is set to run at boot with:

``` bash
sudo systemctl enable tailscaled
sudo systemctl start tailscaled
sudo systemctl status tailscaled
```

... and ensure the container will auto-boot by checking, from the Proxmox GUI, that `Options > Start at Boot` is set to `Yes` for the Tailscale container. 

---
# 3. Enabling the Tailscale node as a Subnet Router

As mentioned earlier, we need to configure the Tailscale node to start as a **[subnet router](https://tailscale.com/kb/1019/subnets)**, in order to access devices in our internal network that don't have a tailscale client installed (such as homelab services). The distinction between a [subnet router](https://tailscale.com/kb/1019/subnets) and an [exit node](https://tailscale.com/kb/1103/exit-nodes) is important, with the following snippet from the Tailscale docs providing a fairly clear explanation:

### *[Subnet routers and exit nodes](https://tailscale.com/kb/1019/subnets#subnet-routers-and-exit-nodes)*

*Subnet routers and exit nodes serve different purposes in the Tailscale ecosystem, though they both involve routing traffic. Understanding the distinction helps you deploy the right solution for your networking needs.*

***Exit nodes route outbound internet traffic from your tailnet devices, effectively functioning as VPN servers.** When you connect to an exit **node, your internet traffic appears to come from the exit node's location**. This is useful for accessing geo-restricted content or improving privacy.*

*In contrast, **subnet routers provide access to specific private subnets. They enable tailnet devices to reach non-Tailscale devices within those subnets, but don't affect internet traffic routing.** If you need to **access private networks** like office LANs or cloud VPCs, **subnet routers are the appropriate solution**.*


So, let's set the node to start with subnet routing on, as well as some extra tweaks (with explanations for each flag below):
``` bash
sudo tailscale set --advertise-routes=192.168.10.0/24,192.168.0.0/24 --accept-routes --ssh --accept-dns=false

sudo tailscale up
```

- `--advertise-routes=192.168.10.0/24,192.168.0.0/24` - replace with your specific local subnets that you want to be advertised and accessible remotely when connected to tailscale on your device.
- `--accept-dns=false` keeps the local LAN-issued DNS for the container, as it is acting as a subnet router. This prevents `/etc/resolv.conf` from being overridden with DNS settings pushed from the Tailscale console, which is often Tailscale's MagicDNS (`100.100.100.100`) and often breaks network functionality/DNS lookups for the container itself.
- `--accept-routes` is required for linux hosts, as *"...by default, Linux devices only discover Tailscale IP addresses. To enable automatic discovery of new subnet routes on Linux devices, use the --accept-routes flag."* ([tailscale docs](https://tailscale.com/kb/1019/subnets#use-your-subnet-routes-from-other-devices))

Once Tailscale is up and running (this can be checked with `tailscale status`), log in to your [Tailscale admin console](https://login.tailscale.com/admin) and approve the requested routes to be advertised by selecting the desired Tailscale node (should now have the `Subnets` tag next to it) & clicking `Edit Route Settings`. Feel free to also change key expiry settings as preferred (I disabled mine).

Now, just check that the Tailscale settings & daemon persists on reboot by hopping back to the LXC and running a quick `reboot`. Once it's back up, if you can browse to your local network devices (such as my TrueNAS GUI on `192.168.0.25:444`) when connected via mobile data from a Tailscale-enabled device (like my phone with the Tailscale app installed), you're all good to go!


