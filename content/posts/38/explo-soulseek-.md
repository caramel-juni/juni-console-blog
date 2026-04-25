---
title: setting up explo to "discover" weekly - without spotify!
date: 2026-04-22
description: ""
toc: true
math: true
draft: true
categories:
tags:
---

<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking

it all began with a brilliant video released by the venerable [Dammit Jeff](https://www.youtube.com/@DammitJeff/videos), [How to ACTUALLY quit spotify](https://youtu.be/3d2cATPt8Nk)! A fairly good introduction into the weird and wonderfully rewarding world of reclaiming ownership over our digital media, but much of what i already knew... until ***[the last 6 minutes](https://youtu.be/3d2cATPt8Nk?si=NkAIzURtSrVFasvG&t=1845)***.

**Discoverability.**


- [ ] install & setup [explo](https://github.com/LumePart/Explo) on truenas with yt-dlp
- custom [explo compose.yaml](https://github.com/LumePart/Explo/blob/main/docker-compose.yaml) app in truenas
- [sample `.env` file](https://github.com/LumePart/Explo/blob/main/sample.env) (use and fill in, see mine below)
- export yt. cookies with [CookieEditor](https://addons.mozilla.org/en-US/firefox/addon/cookie-editor/?utm_source=addons.mozilla.org&utm_medium=referral&utm_content=search) --> netscape format --> save in base config directory on truenas, ensure both that and .env are chown'd to `app` user
- [ ] Setup soulseek + musbrainz/beetz metadata hook

My config folder:
![](Screenshot%202026-04-22%20at%2011.24.08%20pm.png)

My docker-compose yaml, installed as a custom app:
``` yml
services:
  explo:
    container_name: explo
    environment:
      - TZ=UTC # same as one set on listenbrainz
      - EXECUTE_ON_START=true # set this to run immediately to test
      - WEEKLY_EXPLORATION_SCHEDULE=15 00 * * 4
      - WEEKLY_EXPLORATION_FLAGS=
      - WEEKLY_JAMS_SCHEDULE=30 00 * * 1
      - WEEKLY_JAMS_FLAGS=--playlist=weekly-jams --download-mode=normal
      - DAILY_JAMS_SCHEDULE=15 01 * * *
      - DAILY_JAMS_FLAGS=--playlist=daily-jams --download-mode=normal
    image: ghcr.io/lumepart/explo:latest
    restart: unless-stopped
    volumes:
      - /mnt/tank/configs/explo/.env:/opt/explo/.env # must be created by you, in truenas CLI, using tempate on explo's github.
      - /mnt/tank/data/media/music/00-EXPLO:/data/
      - /mnt/tank/configs/explo/cookies.txt:/opt/explo/cookies.txt

```

Environment file saved in `/mnt/tank/configs/explo/.env` - done *before* container is spun up,
# .env file:
``` yaml
# === Discovery Config ===

# Service which recommends songs (only 'listenbrainz' is supported)
DISCOVERY_SERVICE=listenbrainz
# Your ListenBrainz username
LISTENBRAINZ_USER=myuser
# 'playlist' to fetch weekly playlist (50 songs), 'api' for fewer songs (good for testing) (default: playlist)
LISTENBRAINZ_DISCOVERY=playlist

# === Music System Configuration ===

# Music system you use: emby, jellyfin, mpd, plex or subsonic
EXPLO_SYSTEM=subsonic
# Address of your media system (e.g. http://127.0.0.1:4533)
SYSTEM_URL=http://xxx.xxx.xxx.xxx:4533
# Username with access to system (required for all except mpd)
SYSTEM_USERNAME=me
# Password for the user (required for subsonic, recommended for plex)
SYSTEM_PASSWORD=password
# Optional admin username for systems like Navidrome/Subsonic (used only for triggering library scans)
ADMIN_SYSTEM_USERNAME=me
# Optional admin password for systems like Navidrome/Subsonic (used only for triggering library scans)
ADMIN_SYSTEM_PASSWORD=trespass6MERMAID.hauling3aeryn3delete
# API Key from your media system (required for emby and jellyfin, optional for plex)
# API_KEY=
# Name of the music library in your system (emby, jellyfin, plex)
# LIBRARY_NAME=
# Mark playlist as public (subsonic)
PUBLIC_PLAYLIST=false

# === Downloader Configuration ===

# Directory to store downloaded tracks. It's recommended to make a separate directory (under the music library) for Explo
# PS! This is only needed when running the binary version, in docker it's set through volume mapping
# DOWNLOAD_DIR=/path/to/musiclibrary/explo/
# Download/move tracks to a subdirectory named after the playlist
USE_SUBDIRECTORY=true
# Keep original file permissions when moving files (set to false on Synology devices)
KEEP_PERMISSIONS=true
# Comma-separated list (no spaces) of download services, in priority order (default: youtube)
DOWNLOAD_SERVICES=youtube

# Directory for writing .m3u playlists (required only for MPD)
PLAYLIST_DIR=/path/to/playlist/folder/

# === YouTube Configuration ===

# YouTube Data API key (required if using youtube)
YOUTUBE_API_KEY=JGSVDUJVWDGJHWBHBWHDBJSHDJHBSKJDBSKJBKJBSD
# Custom file extension for tracks (e.g mp3) (default: opus)
TRACK_EXTENSION=mp3
# Custom path to ffmpeg binary (default: defined in $PATH)
# FFMPEG_PATH=
# Custom path to yt-dlp binary (default: defined in $PATH)
# YTDLP_PATH=
# Path to (optional) cookies file (default: ./cookies.txt) (in docker this is set through volume mapping)
# COOKIES_PATH=./cookies.txt
# Comma-separated (without spaces) keywords to exclude from YouTube results (default: live,remix,instrumental,extended,clean,acapella)
FILTER_LIST=live,remix,instrumental,extended

# === Slskd Configuration ===

# Slskd instance address (requires running instance)
# SLSKD_URL=
# Slskd API key
# SLSKD_API_KEY=
# Whether to move downloads under the DOWNLOAD_DIR or not (default: false)
# MIGRATE_DOWNLOADS=false
# Rename migrated track in {artist}-{title} format
# RENAME_TRACK=false
# Directory where slskd downloads tracks (default: /slskd/)
# PS! This is only needed on the binary version, in docker it's set through volume mapping
# SLSKD_DIR=/slskd/
# Number of times to check search status before skipping the track (default: 5)
# SLSKD_RETRY=5
# Number of download attempts for a track (default: 3)
# SLSKD_DL_ATTEMPTS=3

## Slskd Filtering

# Comma-separated (without spaces) file extensions to download from (default: flac,mp3)
# EXTENSIONS=flac,mp3
# Minimal Bit Depth (default: 8)
# MIN_BIT_DEPTH=8
# Minimal Bitrate (default: 256)
# MIN_BITRATE=256
# Comma-separated (without spaces) keywords to avoid, when filtering slskd results (default: live,remix,instrumental,extended,clean,acapella)
# FILTER_LIST=live,remix,instrumental,extended,clean,acapella

# === Metadata / Formatting ===

# Set to true to merge featured artists into title (recommended), false appends them to artist field (default: true)
SINGLE_ARTIST=true
# Playlist name format: week (Weekly-Exploration-2026-Week5) or date (Weekly-Exploration-2026-01-31)
PLAYLISTNAME_FORMAT=date

# === Notifications ===

## Discord

# Application's (bot) token
# DISCORD_BOT_TOKEN=
# Channel ID where to send notifications (supports multiple IDs, use comma (without spaces) to separate them)
# DISCORD_CHANNEL_ID=

## HTTP

# HTTP URL to send POST requests to (supports multiple URLs, use comma (without spaces) to separate them)
HTTP_RECEIVER=https://mygotify.com/message?token=xxxxxxxx # not working

## Matrix

# User ID for Matrix
# MATRIX_USERID=
# Room ID to send notifications in
# MATRIX_ROOMID=
# Homeserver URL that the room is created in
# MATRIX_HOMESERVER_URL=
# Users Access token
# MATRIX_ACCESSTOKEN=


# === Misc ===

# Minutes to sleep between library scans (default: 2)
# SLEEP=2
# Set the log level (DEBUG, INFO, WARN, ERROR) (default: INFO)
LOG_LEVEL=DEBUG
# Set a custom HTTP timeout for music servers (in seconds) (default: 10)
# CLIENT_HTTP_TIMEOUT=10

```


## Setup soulseek + musbrainz/beetz metadata hook
---

You are absolutely right to catch that—my apologies for the confusion! You are reading the variables correctly. **Explo acts as a manager/orchestrator, but it does not contain a built-in Soulseek client.**

To use Soulseek with Explo, you need **slskd** (the "batteries-included" Soulseek daemon) running as its own separate container on your TrueNAS.

Here is the corrected "Pro" workflow for TrueNAS:

---

### 1. Step One: Deploy `slskd`

In TrueNAS SCALE, create a new Custom App for `slskd`.

**Docker Compose for slskd:**

YAML

```
services:
  slskd:
    image: slskd/slskd:latest
    container_name: slskd
    environment:
      - SLSKD_REMOTE_CONFIGURATION=true
      - SLSKD_HTTP_PORT=5030
    volumes:
      - /mnt/tank/configs/slskd:/config
      - /mnt/tank/data/media/music/00-EXPLO-INBOX:/downloads
    ports:
      - 5030:5030 # Web UI
      - 50300:50300 # Soulseek Port (Optional: Forward this on your router)
```

- **Action:** Go to `http://[TrueNAS-IP]:5030`, create your account/login, and go to **Settings > API** to generate your **API Key**.
    

---

### 2. Step Two: Connect Explo to slskd

Now, update your **Explo** `.env` with the variables you found:

Bash

```
# Point Explo to your slskd instance
SLSKD_URL=http://192.168.1.xxx:5030 
SLSKD_API_KEY=your_newly_generated_key

# Tell Explo to move files out of slskd's folder into the final Explo folder
MIGRATE_DOWNLOADS=true
RENAME_TRACK=true
```

---

### 3. Step Three: Automating the Tagger (Beets)

To handle the "Inbox" workflow on TrueNAS and fix that Aphex Twin art once and for all, use this automated Beets setup.

#### The "Watch" Script

Instead of manually running MusicBrainz Picard, you can set a **Post-Processor** script.

1. Install the **Beets** app (as described in the previous message).
    
2. In TrueNAS, go to **System Settings > Advanced > Cron Jobs**.
    
3. Add a job that runs every hour (or every morning):
    

**Command:**

Bash

```
docker exec beets beet import -q /downloads
```

- `-q` (quiet) makes it run without asking you questions.
    
- Beets will see the files Explo/slskd dropped in `/00-EXPLO-INBOX`, tag them, embed the **correct** art into the file headers, and move them to your main `/music` folder.
    

---

### Summary of the "Chain"

1. **ListenBrainz:** Tells Explo what you like.
    
2. **Explo:** Searches for those tracks and tells **slskd** to grab them.
    
3. **slskd:** Downloads the files into the `INBOX`.
    
4. **Beets (Cron Job):** Wakes up, grabs the files, fixes the tags/art, and moves them to your main library.
    
5. **Navidrome:** Sees the perfect new files and updates your Symfonium playlist.
    

**The big win here:** By the time the files reach Navidrome, the artwork is **embedded inside the file**. Navidrome won't have to guess based on "helpful" folder images, and your Aphex Twin glitch will stay in the past.

Does that layout make more sense for your TrueNAS setup?

