---
title: setting up explo & soulseek to "discover" weekly - without spotify!
date: 2026-05-03
description: the great music streaming exodus
toc: true
math: true
draft: false
categories:
tags:
  - self-hosted
  - trueNAS
  - slskd
  - explo
  - yt-dlp
  - music
  - docker-compose
  - docker
---

<img src="https://juniblog.goatcounter.com/count?p=/explo-soulseek-sans-spotify/" style="display: none">

it all began with a brilliant video released by the venerable [Dammit Jeff](https://www.youtube.com/@DammitJeff/videos) - [How to ACTUALLY quit spotify](https://youtu.be/3d2cATPt8Nk)! A fairly engaging introduction into the weird and wonderfully rewarding world of reclaiming ownership over our digital media, but much of what i already knew... until ***[the last 6 minutes](https://youtu.be/3d2cATPt8Nk?si=NkAIzURtSrVFasvG&t=1845)***.

#### Discoverability.

the golden bullet to the self-hosting revolution. the word that plants the first seed of doubt into the hearts of all those who self host, well, *anything*. because streaming services and platforms have slowly become not only the dominant way to *engage with* media, but also to *discover* what is, and has, been made. 

their business model is an insidiously two-pronged approach; not only controlling access to what you can *watch*, but slowly, what you even know ***exists.***

and, at risk of going down a rabbit hole utterly plastered in tinfoil, **that's a scary combination to place in the hands of several large, for-profit companies** that prove to us time and time again that their respect for their customers is akin to that issued to cockroaches, or even the mighty sea cucumber *(the unsung hero of our ocean floors.)*

**so.** what i propose, and have put together is **far from perfect.** it IS **a lot more effort,** at least to get set up. but there's something akin to tending to a garden with all this for me, and above all, i've enjoyed being able to take back some control, cast my vote (through abstinence) for directional and institutional change within these monolithic media moguls. and spend the money that used to "stream" straight into the pockets of the fat cats at Netflix, Spotify and co. with the several dozen subscriptions I had, into instead **directly supporting the artists I love.** 

concerts, merch, festivals and vinyls. and ***by god***, seeing `Tool` live and getting told to, *"shove your phones up your asses for the furation of the gig—and who knows, you might enjoy it, and even remember it!"*

**money can't buy that.**

---
# my setup:
my (opinionated) picks below!
## music server:
- [Navidrome](https://www.navidrome.org/) | **Hosted:** on my TrueNAS Server, [TrueNAS Store app](https://apps.truenas.com/catalog/navidrome/) (although also achievable via a docker-compose `YAML`, which I'd do next time)

**Purpose:** *Manages my music library (collection of folders with artists & playlists, needs a good cleaning & organising but 80% of the way there). Exposes it for streaming via other clients via the [Subsonic API](https://www.subsonic.org/pages/index.jsp).* 

## music client/app:
- **Mobile:** [Symfonium](https://www.symfonium.app/) (Android-only) | **7-day free trial, then `$7` one-time purchase**
- **Web/Desktop:** [Feishin](https://github.com/jeffvli/feishin) | **Free**
*Simply provide your Navidrome credentials for these apps to log in with, and stream your library straight from Navidrome!*

## music discovery: ***"Discover Weekly" for self-hosted music systems***
- [explo](https://github.com/LumePart/Explo/) | **Hosted:** on my TrueNAS Server, custom app (via docker-compose `YAML`: [my `.yaml` deployment file here](/files/docker-compose/explo.txt)) 

### download clients:
- [qbittorrent](https://www.qbittorrent.org/) | **Hosted:** on my TrueNAS Server, [TrueNAS Store app](https://apps.truenas.com/catalog/navidrome/).
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) | **Hosted:** inside the [explo](https://github.com/LumePart/Explo/) docker app, as part of the image downloaded.
- [slskd](https://github.com/slskd/slskd/) (downloader for [Soulseek](https://www.slsknet.org/) P2P music file sharing network) | **Hosted:** on my TrueNAS Server, custom app (via docker-compose `YAML`: [my `.yaml` deployment file here](/files/docker-compose/slskd.txt))  
## download sources:
> *small rant incoming:* **feel free to skip, recommendations at bottom of section**


**i'll be straight here** - whilst i *do* purchase & own media, the *vast* majority of my library has come from "various sources" (be it youtube downloads, "other" download sites, media ripping, etc.). this is a nuanced and complex issue, **discovering/sampling/engaging with art** and the question of **payment**, but one that i believe ultimately descends from the larger problem of media decentralisation, distribution & preservation strategies. with many artists having to compromise their values & creativity to even get their music *out there*—and partnering with lecherous contract-makers & labels to then often be treated like trash and their soulful work taken for companies/record labels/streaming services to rent out to people as they please and profit off—i don't want to be a part in supporting that exploitative process. 

**but i also want to support the artists i do end up caring about.** 

we do not always know whether we will *like* what we purchase, and there is just **so much music out there** that making the argument to purchase it all *before knowing* what you actually vibe with, is a bit of a ridiculous one. and there is no "perfect" answer to this, while we operate within the current music production system.

so, well, **fuck that.** the system sucks, so **build a new one that doesn't hurt others, based on your own values & what you are/aren't willing to compromise**

**reclaim and own your media**. discover NEW media by SAMPLING, EXPLORING and EMBRACING the impossibly large and ever-expanding world of art. and ***then,*** with your newfound liberation and heavier pockets, **MOST IMPORTANTLY**: ***go and support the artists you care about where and if you are able.*** the sad reality is that not everyone has the funds to listen to or build a music library akin to what spotify offers (*[chuckles](https://cybernews.com/security/shadow-library-releases-music-scraped-from-spotify/)*) through entirely legal means (or, if you do, you're most likely not losing sleep at night about any of this "ethical" shit anyways). and so in my eyes, the ***"try before you then buy/support what you can"*** model is my best attempt at a solution to this messy system. so at least, i know **my money** is going **directly to the people who make art that speaks to me**, and not some intermediary who siphons off 80%, dolls out the remaining pennies to the intended recipients, and then decides to remove my access to it all at the change of the wind. 
#### ways to support artists directly:
- **[bandcamp](https://bandcamp.com/)**
- buying **merch**!
- buying **physical releases** (vinyls, CDs, etc. - often come with stunning supplementary art, and **their own digital downloads** to add to your library when on the go!)
- going to **concerts/gigs**
- **spreading the word**
- **sharing their music** with others

## so... the download sources?
these sites are **always changing** as things go offline/up/down, so for the most up to date places - go check ***[the bible, here](https://www.reddit.com/r/Piracy/wiki/megathread/music/)***. and keep it quiet, and for those who *actually* want to seek it out. don't go shouting them from the rooftops (i consider my blog a fairly low garden shed, if anything, so i think this is fine). 

my go-to's are:
- **direct filesharing from other audiophiles on the soulseek network** (set up slskd download client, register an account **via the desktop app**, and then supply those credentials to any slskd download client you set up to access the network. and in the good spirit of it all, for god's sake - **share your music library as you do so.**)
- lucinda.to
- squid.wtf
- torrentleech (invite-only)
- again, [check the bible, here](https://www.reddit.com/r/Piracy/wiki/megathread/music/). 

---

# setup overview!

i'll skip the setup for most of the TrueNAS store apps, as there are perfectly good guides that are likely more updated in places [like here](https://wiki.serversatho.me/) (YT versions linked on most pages), as well as on youtube with a quick search.

### prerequisites checklist (guides linked):
- [ ] **[Navidrome](https://wiki.serversatho.me/en/navidrome)**
- [ ] **[qbittorrent](https://wiki.serversatho.me/en/qBittorrent)** (optional regarding music downloading as explo/slskd handles the discovery playlist download part, but handy to have)
- [ ] A [ListenBrainz](https://listenbrainz.org/) account

### apps to set up (detailed below):
- [ ] [`explo`](https://github.com/LumePart/Explo) - spotify's "Discover Weekly" for self-hosted music systems !
- [ ] [`slskd`](https://github.com/slskd/slskd/)-  download client for the P2P Soulseek network

---
# explo setup:
**Resource:** [The Explo Wiki](https://github.com/LumePart/Explo/wiki/)

### 1. create required folders
explo will require:

- a folder to store its config, including the all-important `.env` file
- a dedicated sub-folder inside your music library to place downloaded music.

in TrueNAS, create a new dataset (type: `Apps`, meaning explo will run with `UUID=568`) for explo's config. leave ACL permissions as is, as long as type: `Apps` is set. This will create the `explo` config directory, as a dataset (to have it show up inside TrueNAS GUI).

then hop over to the shell (`System > Shell`), and create our startup files inside the config directory;
- `touch .env`
- If using an exported `cookies.txt` to help `yt-dlp` download more videos (see details on generation [here](https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp). i used [Cookie-Editor](https://addons.mozilla.org/en-US/firefox/addon/cookie-editor/?utm_source=addons.mozilla.org&utm_medium=referral&utm_content=search) & downloaded in `Netscape` format), copy it to here with `scp`, or `touch cookies.txt` and copy paste in the contents of your generated one.

ensure these folders are recursively owned by the `Apps` user, by running this inside the TrueNAS shell:
- `chown -R 568 /path/to/explo-folder`

Then, check permissions with `ls -lahs`. Should look similar to:
![](/posts/38/attachments/63453.png)

then, navigate to your Navidrome music library, and create a new folder for explo to store downloads in. Repeat above process to ensure `Apps` owns this.
- `mkdir /path/to/navidrome/music-library/00-EXPLO` (or whatever you want to call it)

### 2. editing the `.env.` file

using your text editor of choice (`vi/vim` for me), set your config-specific setup here depending on what in-built download client you want to use, and it's behaviour. it can also be helpful to `cat .env` while in the TrueNAS shell, copy the output, and paste it into an editor like VS-Code if you're more of a GUI kinda gal.

for an easy setup, i recommend using the built-in `yt-dlp`. it does a decent enough job, **just can be hit or miss with correct metadata embedding**, as it doesn't seem to be configure inside explo to do this super well by default. for this, you'll need to **generate & add in a YouTube API key** - details on how to do so [here](https://helano.github.io/help.html).

if you want to link your `slskd` instance (described later in this guide), provide the necessary ***SoulSeek network*** credentials, your `slskd` downloader app credentials, and `API` key.

there is a lot inside this `.env` file, and so i've provided a [link to a sanitised version of mine here](/files/config-files/explo-env.txt) detailing my exact setup and the fields to replace. Skip the `slskd` section if you're just using `yt-dlp`, and the HTTP notify if you don't care to set notifications (i use my self-hosted [gotify](https://gotify.net/) instance for this).

Once done, save it, **check it's still owned by the `apps` user with `ls -lahs`**, and move on!

### 3. create custom explo TrueNAS App
using `Apps > Discover Apps > 3 dots next to "Custom App" > Install via YAML`.

grab the [docker-compose template from the explo wiki](https://github.com/LumePart/Explo/blob/dev/docker-compose.yaml), or if using my [docker-compose setup](/files/docker-compose/explo.txt), copy it. 

then, change at least following variables:

- `EXECUTE_ON_START=` - change to `TRUE` if you want explo to generate your discovery playlist based on the settings, useful to test after setup. set to `FALSE` for normal weekly operations
- `WEEKLY_EXPLORATION_SCHEDULE=...` and similar: Specify when you'd like your playlists downloaded, use [crontab.guru](https://crontab.guru/) to help generate the cron syntax if needed!
- `/mnt/tank/configs/explo/.env:` - change to the path to your `.env` file, which you created in the previous step. everything after the `:` is the docker internal mapping (what it looks like within the app when it's spun up) - can leave this.
- `/mnt/tank/data/media/music/00-EXPLO:` - change to your music directory you want explo to have access to. **highly recommended to use a dedicated subfolder inside your music library.**
- `/mnt/tank/configs/explo:` - change to path to your explo config folder, where cookies are stored & for explo to store cached files.
- `/mnt/tank/configs/explo/cookies.txt:` - an optional volume mapping where you store a pre-generated `cookies.txt` to help `yt-dlp` download more videos, see details on generation [here](https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp). i used [Cookie-Editor](https://addons.mozilla.org/en-US/firefox/addon/cookie-editor/?utm_source=addons.mozilla.org&utm_medium=referral&utm_content=search) & downloaded in `Netscape` format.

now, time to test! set `EXECUTE_ON_START=TRUE`, press save, and wait for the container to pull, and generate it's first playlist! it will:
- communicate with listenbrainz & generate a list of 50 songs based on your listening history/genres/artists you like
- download any using your download client into it's `explo` folder inside your media library. can configure this inside `.env` to download only missing songs, or all songs. if only missing ones, it will find and auto-link to existing songs inside your library to pull them into the playlist without moving them.
- once done, it will **create a playlist of all the songs directly in Navidrome**, so it won't show up anywhere as a file, but rather exist in Navidrome's database. To delete it, go to Navidrome and do so.

watch the logs (**purple highlight below**) or drop into the in-app CLI (less useful, **red highlight**) for any troubleshooting, and especially on first run to see what it's doing. 

the logs are particularly helpful for determining whether anything is amiss, and **it's usually a misconfigured `.env` file.** to edit it, stop the container, and use your text editor to made adjustments. my workflow is keeping a local copy in a visual code editor to check for formatting quirks/typos, and then replacing the entire `.env` file inside the TrueNAS shell once done.

![](/posts/38/attachments/77585.png)

you can stop here if you're just using `yt-dlp` - if all is well, a test run should create subfolders for your playlists inside your explo folder in your music library! depending on how you're linking your music, and whether the songs on the discovery playlist already exist in your library (in which case, explo won't download duplicates and just link to existing files), you might see some downloaded files in here like below: 

![](/posts/38/attachments/80871.png)

**if you have any questions, please feel free to reach out to me [via email](mailto:juniblog.imitation270@passmail.net) :)**


---

# slskd setup:

### resources:
- https://github.com/slskd/slskd/blob/master/docs/docker.md

### preamble - what is SoulSeek, and `slskd`?

> "Soulseek is an ad-free, spyware free, just plain free file sharing network for Windows, Mac and Linux. Our rooms, search engine and search correlation system make it easy for you to find people with similar interests, and make new discoveries!"

to clarify for any confused souls like me:
- `Soulseek`: the P2P filesharing **network** itself, which you can login to, browse other's files, and download them.
- `slskd`: a **download client** which **connects to the `Soulseek` network** to download files. this is what will be setup below, for explo to contact and use.

#### How `slskd` works:
- **`shared music directory`** — what you _expose to others_ on the Soulseek network to browse and download from you
- **`your slskd downloads dir`** — where your own downloads will be saved.

### prerequisites:
- [download the SoulSeek client app](https://www.slsknet.org/news/node/1), and during installation, **create your SoulSeek network account.** this will be used to communicate over the **Soulseek P2P network** and is **essential**, and doing it via the app download is, afaik, the most straightforward way to register for one.
- run the app, create your account, and ensure you can access the network and browse files. look up any issues you have, others likely have had them too, but it's fairly plug-and-play.

once you have your **Soulseek network credentials**, and have verified you can connect to the network itself and browse files, we can move on!

### 1. create slskd download client dataset

`slskd` will require:
- a folder to store its config
- a dedicated folder to store downloads

so, in TrueNAS, create a new dataset (type: `Apps`, meaning `slskd` will run with `UUID=568`) for slskd's config. leave ACL permissions as is, as long as type: `Apps` is set. this will create the `slskd` config directory, as a dataset (to have it show up inside TrueNAS GUI).

then, navigate to your Navidrome music library, and create a new folder for `slskd` to store downloads in. repeat above process to ensure `Apps` owns this.
- `mkdir /path/to/navidrome/music-library/00-slskd-downloads` (or whatever you want to call it)

### 2. create slskd download client custom TrueNAS app
similar to above process, create a new custom `YAML` app, and paste in my docker-compose template, changing the below variables (more details in my [linked `docker-compose` file](/files/docker-compose/slskd.txt)):

- `SLSKD_SLSK_USERNAME` & `SLSKD_SLSK_PASSWORD` - your **Soulseek NETWORK** credentials, created above
- `SLSKD_USERNAME` & `SLSKD_USERNAME` - **create your own credentials here**, to be used to log into the `slskd` apps's local webUI.
- `SLSKD_API_KEY` - replace with a randomly generated API key to use for interacting with the `slskd` client programatically. **explo will need this set in it's `.env` file once created.** you can create this yourself via a `rand` function, or by (after creating the `slskd` app) dropping into it's own `console` (highlighted red below and accessed via the trueNAS Applications GUI) and running `--generate-secret`.
  ![](/posts/38/attachments/64027.png)
- `/mnt/rei/configs/slskd:` - change to the path of your slskd config directory created above.
- `/mnt/tank/data/media/music:` - change to the path to your music library. this will be shared with over the `Soulseek` network for people to download from.
- `SLSKD_DOWNLOADS_DIR=/music/00-slskd-downloads` - this will be where your slskd client saves all downloaded files. i recommend creating a dedicated folder for this, as done above.
- `'5030:5030'` - unfortunately due to how explo won't trust self-signed slskd certificates (i tried, it's the explo app itself that prevents this), all API communication between them will have to be done via the `HTTP` port, at `5030:5030`. so ensure to have this enabled.

then save, and monitor logs (purple highlight above) to check if anything is amiss! you should see that you've connected to the **Soulseek Network**, and if not, **double check your `SLSKD_SLSK_USERNAME` & `SLSKD_SLSK_PASSWORD`**. 

![](/posts/38/attachments/54847.png)


### 3. testing the slskd downloader webUI

you can log into the slskd download client webui at `http://[Your-TrueNAS-IP]:5030`, using the webUI credentials in your compose file. if you're all setup and connected, check you're sharing your music folder:
![](/posts/38/attachments/69504.png)

and you're good to go! this client can also be used to view past downloads & logs of people currently downloading your files (which is always cool to see):
![](/posts/38/attachments/58073.png)

and you can even search the network for an artist's name via `Search`, and then browse others' folders & download their music!
![](/posts/38/attachments/36944.png)


### 4. (optional) tweaking the slskd `.yml` config

if desired, go to your slskd client's config directory (for me, `/mnt/rei/configs/slskd`), and edit `slskd.yml`. However, most is pre-filled via the above docker-compose variables, and the security defaults are sensible ones. 

here is an [example one](https://github.com/slskd/slskd/blob/master/config/slskd.example.yml) (uncomment lines for them to take effect) for what the generated the file will look like, and **please read the [full documentation](https://github.com/slskd/slskd/blob/master/config/slskd.example.yml) if you intend on changing anything here.**

e.g. I changed my webUI credentials here at some stage, and then forgot to update them in my `docker-compose` file, and couldn't figure out why I couldn't login to the WebUI. so, just choose one place to manage them.


---
# connecting slskd and explo!

now, all you need to do to connect the two is update the following values in explo's `.env` file. adjust any other `slskd` specific parameters, using [my compose file](/files/docker-compose/slskd.txt) as a template/for examples & details.

```
## inside your explo .env file:

# point explo to your slskd instance
SLSKD_URL=http://SLSKD-DOWNLOADER-WEBUI-IP:5030 
SLSKD_API_KEY=YOUR-GENERATED-SLSKD-API-KEY

# tell explo to move files out of slskd's folder into the final Explo folder (this only kind of works...?)
MIGRATE_DOWNLOADS=true
RENAME_TRACK=true

# if you want to prefer slskd downloads over yt-dlp (good to test)
DOWNLOAD_SERVICES=slskd,youtube
```

now, to test, set `EXECUTE_ON_START=TRUE` inside explo's `docker-compose`, press save, and watch the logs to see explo try and generate a new weekly recommended playlist with `slskd`!

---

# a few notes:

- you'll need to follow [`troi-bot`](https://listenbrainz.org/user/troi-bot/) on ListenBrainz to get `DAILY_PLAYLISTS` generated. however, you'll need a **considerable amount of ListenBrainz streaming history** for this to work, and even with a few months of [scrobbling enabled for me via Navidrome](https://www.navidrome.org/docs/usage/features/scrobbling/), it still fails.
- **metadata can be hit or miss**. i'm working on a solution by integrating a [`beetz`](https://docs.linuxserver.io/images/docker-beets/) container with this setup to periodically run cleans of my auto-downloaded songs & embedding metadata properly, but it's a WIP. 
  if it really bothers you, open your music directory via an SMB/NFS share in TrueNAS and run MusicBrainz Picard over the downloaded files, to clean up metadata. Remove any auto-generated `folder.jpg` files from the explo weekly discovery playlists to prevent them taking priority and letting the embedded metadata work in your listening clients.

---

# and... that's all folks... for now!

that's it for now - a long post for sure, but a very rewarding process. i feel a little more in control, and connected to the `toonz` i'm listening to. hopefully a post on metadata cleaning with [`beetz`](https://docs.linuxserver.io/images/docker-beets/) is coming soon.

#### once again, **thank you endlessly to the maintainers of these amazing programs and networks** - go show them love and support, help others, and spread the good word <3

**also, bonus tip** check out [RadioBOB!](https://www.radiobob.de/alternative-rock-stream), and other worldwide radio stations, for more recommendations for music. i have this on nearly *constantly*, and use the open-source webUI listening client [Radiolise](https://radiolise.com/) to switch between channels, save songs I hear while listening to look up/download later, and browse channels. 

- here's my [radiolise config](/files/radiolise-channels.txt) for my most listened-to channels!

<div style="text-align: center"><img src="https://gifdb.com/images/high/looney-tunes-that-s-all-folks-r4g5udvwj0j6pmpk.gif" style="width:600px"></div>