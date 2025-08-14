---
title: ""
date: 2025-06-23
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

[For fixing npm TrueNAS App faulty update](https://forums.truenas.com/t/nginx-proxy-manager-2-12-4-multiple-issues-and-unresolved-dns-failure-rollback-required/47186/25)


### Music Streaming & self-hosted
- Music Server - [navidrome](https://www.navidrome.org/docs/) via TrueNAS app (no linuxserver.io image)
	- accessed publicly behind [nginx proxy manager](https://nginxproxymanager.com/)
- Music Streaming Client (android) - [Ultrasonic](https://gitlab.com/ultrasonic/ultrasonic) via Droid-ify/F-Droid
- Music Metadata Namer/organiser - [lidarr](https://wiki.servarr.com/lidarr/quick-start-guide) via TrueNAS app
	- on hold due to metadata/API indexing issue - tracked [here](github.com/Lidarr/Lidarr/issues/5498) (August 2025)
- 