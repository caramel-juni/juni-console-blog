

### NEED TO ADD nginx WEBSERVER SETUP PORTION INSTALL



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
```