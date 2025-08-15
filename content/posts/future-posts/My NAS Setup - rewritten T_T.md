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

---
### nextcloud
- [linuxser.io image](https://docs.linuxserver.io/images/docker-nextcloud/#version-tags) - for testing.
#### Setup guides:
- https://wiki.serversatho.me/en/nextcloud (docker & truenas app)
	- https://www.youtube.com/watch?v=ibL9qAlUZes (video version)
- [truenas app install video walkthrough](https://www.youtube.com/watch?v=1rpeKWGoMRY&t=949s)
- truenas docs [app install guide for nextcloud](https://apps.truenas.com/resources/deploy-nextcloud/)
- nextcloud docs - [choosing db & install](https://docs.nextcloud.com/server/31/admin_manual/installation/installation_wizard.html)

**Future:** After testing, and when i move to using it properly - need to move to & setup `mariadb`/`mySQL`- will need to setup new datasets for these.
- [truenas scale app version guide](https://apps.truenas.com/resources/deploy-nextcloud/)
- [docker guide](https://www.youtube.com/watch?v=C5mKYX5SClI) 
- ***may want to check [linuxserver.io image](https://docs.linuxserver.io/images/docker-nextcloud/#version-tags) to see whether compatible***