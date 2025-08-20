---
title: kiwix - self host the internet
date: 2025-08-20
description: ""
toc: true
math: true
draft: false
categories:
  - truenas
  - kiwix
tags:
  - trueNAS
  - docker-compose
  - docker
---
Here's a small tutorial to satisfy your Peak Paranoia Needs: installing the `kiwix` server to **"self host the internet (well, manuals & documentation &... wikipedia) before it's TOO LATE!11!1!!!"** with a custom TrueNAS app via `YAML` (`TrueNAS SCALE Fangtooth 25.04.01`).

# Inspo vids:
- [Wikipedia Offline - IT'S SO EASY!](https://www.youtube.com/watch?v=xKLO3WRU2MY)
- [self-host the INTERNET! (before it's too late)](https://www.youtube.com/watch?v=OC67FoXVRPE&t=418s)

# Steps:
1. Within TrueNAS Scale, create the folder to contain your `.zim` library. For me, this was `/mnt/tank/data/kiwix/data`, & `chown` it to have the correct `PUID` (for me, `apps`, `568`).
2. Download a couple test `.zim` files to get the container running - otherwise will crash on spinup if it doesn't detect anything in the `/data` folder. I just downloaded [freecodecamp_en_all_2025-07.zim](https://browse.library.kiwix.org/viewer#freecodecamp_en_all_2025-07) & [archlinux_en_all_maxi_2025-07.zim](https://browse.library.kiwix.org/viewer#archlinux_en_all_maxi_2025-07) (btw ;) to get started, `~40MB`. Can either do so with `wget` within TrueNAS, or copy/upload via a share - but just ensure it's in the `/data` folder created in step 1, and can be accessed by the `apps` user.
3. Create a TrueNAS custom app with `YAML` like the following, passing in the path to your folder created in step 1:
   
``` yaml
services:
  kiwix-serve:
    command:
      - '*.zim'
    environment:
      - PGID=568
      - PUID=568
    image: ghcr.io/kiwix/kiwix-serve:latest
    ports:
      - '2334:8080'
    restart: unless-stopped
    volumes:
      - /mnt/tank/data/kiwix/data:/data

```
   
   This will run the following `command` on startup: `/usr/local/bin/kiwix-serve --port=8080 [command]`, with the value specified in the compose file replacing `[command]`. So, by passing `*.zim`, it will detect & build all the `.zim` files contained within the root (`/data`) directory.
4. So, every time you add new `.zim` files, just **restart the container/app**, and they should get auto-built & loaded up in your database, accessible over your localhost/server `IP:2334` (in my case, defined in compose file).![](/posts/25/Screenshot%202025-08-20%20at%209.57.04%20pm.png)
5. I also recommend when [downloading new `.zim` files](https://library.kiwix.org/#lang=eng), use `.torrent` links and map your torrent client to write them directly to your mounted `/data` folder, so they can auto-appear with the correct file permissions and so you can additionally avoid manually uploading them yourself.

This is only scratching the surface here at what [`kiwix`](https://kiwix.org/en/) can do, but it's enough for my paranoid-tinfoil-hat backup-the-internet needs for now!
![](/posts/25/91951.png)