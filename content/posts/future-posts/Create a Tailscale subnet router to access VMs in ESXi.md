---
title: ""
date: 2025-06-06
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

- subnet router vs exit node & use cases
	- [Subnet routers · Tailscale Docs](https://tailscale.com/kb/1019/subnets) - use for accessing devices on a network that do/cannot have tailscale installed
	- [Exit nodes (route all traffic) · Tailscale Docs](https://tailscale.com/kb/1103/exit-nodes) - use to route ALL internet traffic thru this machine


### document VM spinup & setup process here



### script used to harden ssh & install tailscale



``` bash
'
THE BELOW SCRIPT SETS UP THE FOLLOWING ON A DEBIAN BASED DISTRO:
- SSH ACCESS + AUTHORIZED KEYS
- ufw

LINES TO CHANGE BASED ON ENVIRONMENT

line 65 - ssh key (insert yours)
lines 71 onwards --> uncomment to install tailscale and set up as an exit node/subnet router, need to replace with desired IP etc.

'

# first, run manually to create a root acc without pw
sudo passwd -d root

su root


#!/bin/bash

## THE BELOW ASSUMES YOU ARE RUNNING AS ROOT USER. 

## --------------------------
## INSTALL REQUIRED PACKAGES
## --------------------------


sudo apt update && sudo apt -y upgrade && sudo apt -y autoremove && sudo apt clean




## ---------------
## Setup UFW
## ---------------

ufw limit 22/tcp
ufw limit 22/tcp6
ufw enable
ufw logging on
ufw status


## ---------------
## Harden SSH
## ---------------

sudo sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' \
        -e 's/PasswordAuthentication yes/PasswordAuthentication no/' \
		-e 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' \
        -e 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
		
		
## tell ssh where to look for known keys (universal)
sudo touch /etc/ssh/authorized_keys	
sudo echo "AuthorizedKeysFile /etc/ssh/authorized_keys" >> /etc/ssh/sshd_config

## remove any conflicting settings for password auth
sudo sudo rm -rf /etc/ssh/sshd_config.d/*


## write known good SSH key to the authorized_keys file. REPLACE WITH YOUR SSH PUBLIC KEY (.pub file) generated when using ssh-keygen (its contents begin with "ssh-rsa AAAAB3...")

sudo echo "ssh-rsa [key]= [usr]@[domain/hostname]" >>  /etc/ssh/authorized_keys

## Lock the root account
passwd -l root



```


***(will need to run tailscale commands manually if first device connected to the tailnet and can't access remotely via ssh)***


```bash

---------------------------------------------------
ADDITIONAL SETUP FOR TAILSCALE:

## setup tailscale & services 

sudo apt install net-tools firewalld tailscale

echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf


## Linux optimizations for subnet routers and exit nodes

NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
sudo ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off

## as settings do not persist upon reboots, the following script configures these settings on boot (if systemctl is-enabled networkd-dispatcher is enabled)
printf '#!/bin/sh\n\nethtool -K %s rx-udp-gro-forwarding on rx-gro-list off \n' "$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")" | sudo tee /etc/networkd-dispatcher/routable.d/50-tailscale
sudo chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale

## test if works:
sudo /etc/networkd-dispatcher/routable.d/50-tailscale
test $? -eq 0 || echo 'An error occurred.'

## if using firewalld:
firewall-cmd --permanent --add-masquerade

## set up machine as a subnet router (enables local network access for tailscale-connected clients, need to replace with desired IP/range)

sudo tailscale up --advertise-routes=XXX.XXX.XXX.XXX/XX --accept-routes

--------------------------------------------------


```


