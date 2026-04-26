---
title: setting up explo & soulseek to "discover" weekly - without spotify!
date: 2026-04-22
description: ""
toc: true
math: true
draft: true
categories:
tags:
  - self-hosted
  - trueNAS
  - slskd
  - explo
  - yt-dlp
  - music
---

<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking

it all began with a brilliant video released by the venerable [Dammit Jeff](https://www.youtube.com/@DammitJeff/videos) - [How to ACTUALLY quit spotify](https://youtu.be/3d2cATPt8Nk)! A fairly engaging introduction into the weird and wonderfully rewarding world of reclaiming ownership over our digital media, but much of what i already knew... until ***[the last 6 minutes](https://youtu.be/3d2cATPt8Nk?si=NkAIzURtSrVFasvG&t=1845)***.

#### Discoverability.

the golden bullet to the self-hosting revolution. the word that plants the first seed of doubt into the hearts of all those who self host, well, *anything*. because streaming services and platforms have slowly become not only the dominant way to *engage with* media, but also to *discover* what is, and has, been made. 

their business model is an insidiously two-pronged approach; not only controlling access to what you can *watch*, but slowly, what you even **know *exists*.**

and, at risk of going down a rabbit hole utterly plastered in tinfoil, **that's a scary combination to place in the hands of several large, for-profit companies** that prove to us time and time again that their respect for their customers is akin to that issued to the mighty sea cucumber *(the unsung hero of our ocean floors.)*

**so.** what i propose, and have put together is **far from perfect.** it IS **a lot more effort,** at least to get set up. but there's something akin to tending to a garden with all this for me, and above all, i've enjoyed being able to take back some control, cast my vote (through abstinence) for directional and institutional change within these monolithic media moguls. and spend the money that used to "stream" straight into the pockets of the fat cats at Netflix, Spotify and co. with the several dozen subscriptions I had, into instead **directly supporting the artists I love.** 
concerts, merch, festivals and vinyls. ***god***, seeing `Tool` live and getting told to, *"shove our phones up our asses for the furation of the gig—and who knows, you might enjoy it, and remember it!"*

**money can't buy that.**

---
# my setup:
my (opinionated) picks below!
## music server:
- [Navidrome](https://www.navidrome.org/) | **Hosted:** on my TrueNAS Server, [TrueNAS Store app](https://apps.truenas.com/catalog/navidrome/) (although also achievable via a docker-compose `YAML`, which I'd do next time)
  *Manages my music library (collection of folders with artists & playlists, needs a good cleaning & organising but 80% of the way there). Exposes it for streaming via other clients via the [Subsonic API](https://www.subsonic.org/pages/index.jsp).* 

## music client/app:
- **Mobile:** [Symfonium](https://www.symfonium.app/) (Android-only) | **7-day free trial, then `$7` one-time purchase**
- **Web/Desktop:** [Feishin](https://github.com/jeffvli/feishin) | **Free**
*Simply provide your Navidrome credentials for these apps to log in with, and stream your library straight from Navidrome!*

## music discovery:
***"Discover Weekly" for self-hosted music systems***
- [explo](https://github.com/LumePart/Explo/) | **Hosted:** on my TrueNAS Server, custom app (via docker-compose `YAML`: [my `.yaml` deployment file here](/files/docker-compose/explo.yaml)) 

### download clients:
- [qbittorrent](https://www.qbittorrent.org/) | **Hosted:** on my TrueNAS Server, [TrueNAS Store app](https://apps.truenas.com/catalog/navidrome/)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) | **Hosted:** inside the [explo](https://github.com/LumePart/Explo/) docker app, as part of the image downloaded.
- [slskd](https://github.com/slskd/slskd/) (downloader for [Soulseek](https://www.slsknet.org/) P2P music file sharing network) | **Hosted:** on my TrueNAS Server, custom app (via docker-compose `YAML`: [my `.yaml` deployment file here](/files/docker-compose/slskd.yaml))  
### download sources:
**i'll be straight here** - whilst i *do* purchase & own media, the *vast* majority of my library has come from "various sources" (be it youtube downloads, "other" download sites, media ripping, etc.). this is a nuanced and complex issue, **discovering/sampling/engaging with art** and the question of **payment**, but one that i believe ultimately descends from the larger problem of media decentralisation, distribution & preservation strategies. with many artists having to compromise their values & creativity to even get their music *out there*—and partnering with lecherous contract-makers & labels to then often be treated like trash and their soulful work taken for companies/record labels/streaming services to rent out to people as they please and profit off—i don't want to be a part in supporting that exploitative process. 

**but i also want to support the artists i do end up caring about.** 

we do not always know whether we will *like* what we purchase, and there is just **so much music out there** that making the argument to purchase it all *before knowing* what you actually vibe with, is a bit of a ridiculous one. and there is no "perfect" answer to this, while we operate within the current music production system.

so, well, **fuck that.** the system sucks, so **build a new one that doesn't hurt others, based on your own values & what you are/aren't willing to compromise**

**reclaim and own your media**. discover NEW media by SAMPLING, EXPLORING and EMBRACING the impossibly large and ever-expanding world of art. and ***then,*** with your newfound liberation and heavier pockets, **MOST IMPORTANTLY**: ***go and support the artists you care about where and if you are able.*** the sad reality is that not everyone has the funds to listen to or build a music library akin to what spotify offers (*[chuckles](https://cybernews.com/security/shadow-library-releases-music-scraped-from-spotify/)*) through entirely legal means (or, if you do, you're most likely not losing sleep at night about any of this "ethical" shit anyways). and so in my eyes, the ***"try before you then buy/support what you can"*** model is my best attempt at a solution to this messy system. so at least, i know **my money** is going **directly to the people who make art that speaks to me**, and not some intermediary who siphons off 80%, dolls out the remaining pennies to the intended recipients, and then decides to remove my access to it all at the change of the wind. 
#### ways to support artists directly:
- **[bandcamp](https://bandcamp.com/)**
- buying **merch**!
- buying **physical releases** (vinyls, CDs, etc. - often come with stunning supplementary art, and**their own digital downloads** to add to your library when on the go!)
- going to **concerts/gigs**
- **spreading the word**
- **sharing their music** with others

#### so... the download clients?
these sites are **always changing** as things go offline/up/down, so for the most up to date places - go check ***[the bible, here](https://www.reddit.com/r/Piracy/wiki/megathread/music/)***. and keep it quiet, and for those who *actually* want to seek it out. don't go shouting them from the rooftops (i consider my blog a fairly low garden shed, if anything, so i think this is fine). my go-to's are:
- **direct filesharing from other audiophiles on the soulseek network** (set up slskd download client, register an account via the desktop app, and then supply those credentials to any slskd download client you set up to access the network. and in the good spirit of it all, for god's sake - **share your music library as you do so.**)
- lucinda.to
- squid.wtf
- torrentleech (invite-only)
- again, [check the bible, here](https://www.reddit.com/r/Piracy/wiki/megathread/music/). 




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

## resources:
- https://github.com/slskd/slskd/blob/master/docs/docker.md

In TrueNAS SCALE, create a new Custom App for `slskd`.
**Docker Compose for slskd:**
YAML

```
services:
  slskd:
    container_name: slskd
    environment:
      - PUID=568
      - PGID=568
      - SLSKD_REMOTE_CONFIGURATION=true
      - SLSKD_USERNAME=your_soulseek_username
      - SLSKD_PASSWORD=your_soulseek_password
      - SLSKD_WEB_AUTHENTICATION_USERNAME=your_webui_username
      - SLSKD_WEB_AUTHENTICATION_PASSWORD=your_webui_password
      - SLSKD_SHARED_DIR=/music        # shares your entire library
      - SLSKD_DOWNLOADS_DIR=/music/00-EXPLO  # downloads go into the subfolder
    image: slskd/slskd:latest
    ports:
      - '5030:5030' # webui HTTP
      - '5031:5031' # webui HTTPS
      - '50300:50300' # sharing port
    restart: always
    volumes:
      - /mnt/rei/configs/slskd:/app
      - /mnt/tank/data/media/music:/music:rw  # entire library, rw so 00-EXPLO i
```

- **Go to `http://[TrueNAS-IP]:5030`, login using your credentials in the ENV ocker compose file, and go to **Settings - API** to generate your **API Key**.

### How slskd works:
- **Shared dir** — what you _expose to others_ on the Soulseek network to browse and download from you
- **Downloads dir** — where files others send _to you_ get saved, and also where your own downloads land


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

