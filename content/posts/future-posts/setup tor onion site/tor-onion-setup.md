---
title: Setting up TOR .onion site
date: 2025-08-13
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

1. spinup AWS server (6mo free credit) on ec2 - for me, debian trend3.micro with 30GB storage. download `.pem` key and connect via `ssh`. **Ensure you set it up so it is NOT allowing access via `HTTP(S)` - we will be hosting the site via tor only, not over any locally-opened `HTTP` or `HTTPS` ports on the machine!**
2. Login to your AWS sever, and [setup `tor` `apt` repository](https://support.torproject.org/apt/tor-deb-repo/)  (to get latest stable `tor` version updates earlier than debian does by default). Make sure to replace `<DISTRIBUTION>` with your distro, outputted from `lsb_release -c` !
	- **tip:** to run a whole set of piped commands with `sudo`, spawn a new shell with `sudo bash -c 'command1 | command2'`
3. Install tor with: `sudo apt install tor`, and enable it & check status with `sudo systemctl enable tor` & `sudo systemctl status tor`.
4. Install `nginx` & host a simple webserver - see [here](https://www.bentasker.co.uk/posts/documentation/security/290-hosting-tor-hidden-services-onions.html)
5. Setup tor site, with `torrc` containing at minimum the following for a POC:
``` bash
   SocksPort 0 # Default: Bind to localhost:9050 for local connections
   SocksListenAddress 127.0.0.1 # Bind to this address:port too.
   
   RunAsDaemon 1
   
   DataDirectory /var/lib/tor
   
   HiddenServiceDir /var/lib/tor/hidden_service/
   HiddenServicePort 80 127.0.0.1:9070

   ```
6. Ensure tor is running with: `sudo systemctl status tor@default.service`. Restart it if need be with `sudo systemctl restart tor@default.service`. Troubleshoot with `journalctl -xeu tor@default.service`
   ![](Screenshot%202025-08-12%20at%2012.30.37%20am.png)
7. Once running successfully, find your site's generated `.onion` link with `cat /var/lib/tor/hidden_service/hostname`, replacing the path with your value for `HiddenServiceDir` in `torrc` + `/hostname`.
8. Then, just change your `nginx` site `server_name` to this `.onion link`, within `/etc/nginx/sites-available`, and ensure both `nginx` and `tor@default.service` are running, & set `nginx` to start at boot with `sudo systemctl enable nginx`. Then, you should be able to access your site via `tor` right away!
   ![](Screenshot%202025-08-12%20at%2012.43.44%20am.png)
9. To take it down, simply run `sudo systemctl stop tor@default.service`, and can start again when needed! *Recommended to do this before you've fully hardened the site.*
#### Helpful Links:
- [Create Your Own Dark Web Website](https://www.youtube.com/watch?v=YXoS8wd1DJo)
- https://community.torproject.org/onion-services/setup/
- https://onionsites.org/how-to-set-up-a-hidden-service-on-tor/
- https://www.bentasker.co.uk/posts/documentation/security/290-hosting-tor-hidden-services-onions.html


### Next steps: Basic OpSec and site hardening
- https://www.bentasker.co.uk/posts/documentation/security/290-hosting-tor-hidden-services-onions.html
- https://support.torproject.org/faq/staying-anonymous/
- https://riseup.net/en/security/network-security/tor/onionservices-best-practices#onion-services-can-be-found
- user management on linux as a whole, nginx hardening

### Generating a vanity `.onion` address!
- https://www.bentasker.co.uk/posts/documentation/linux/708-generating-a-vanity-address-for-version-3-onions.html

