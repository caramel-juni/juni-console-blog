---
title: spotdl cookie wrappers, and further configuration!
date: 2025-09-02
description: ""
toc: true
math: true
draft: false
categories:
  - spotdl
  - yt-dlp
  - musicbrainz picard
tags:
  - spotify
  - yt-dlp
  - youtube-music
---
I encountered some *issues* downloading complete albums due to some songs being age-restricted because they, **GOD FORBID**, may have had the f-word (and other OBSCENITIES) in their titles... so here's my workaround for an automated solution that simplifies this:

``` yaml
spotdl download URLHERE --format opus --cookie-file ~/Documents/SpotifyRips/cookies.txt --bitrate disable --audio youtube-music --overwrite metadata.... etc. etc.
```

into **this**:

``` yaml
spotdl.sh URLHERE
```

**ALSO:** This largely, if not COMPLETELY, **negates** my need to **post-process with MusicBrainz Picard...** as much as I has loved my time with it. This is, quite frankly... ***massive*** for me, as Navidrome seems to do well enough with the metadata pulled natively with `spotdl`, and saves ***actual hours*** of my time and bandwidth with musicbrainz API calls (for negligible benefit), so... **yippee!!!!!**

**Let's dive right in!**

# Setting up the `spotdl` config file

I began by saving my "regular" flags into my `config.json`, by generating it with `spotdl --generate-config`, then adding/editing the following lines in the generated `~/.spotdl/config.json`:

``` yaml
    "format": "opus",
    "overwrite": "metadata",
    "bitrate": "disable",
	"m3u": "{artist} - All Albums.m3u8",
    "output": "{album}/{track-number} - {title}.{output-ext}",
    "print_errors": true,
    "save_errors": "/Users/kupteraz/Documents/SpotifyRips/spotdl-errors.txt",
    "album-type": "album",

```

**These:**
- **specify file format** (`opus` for a balance of quality, filesize, & open-source-ness as a format ;)
- **what action** to do when **finding duplicate files** (overwrite metadata only - can also "`skip`")
- **ensure the max quality is downloaded** with `bitrate disable` (see [here](https://spotdl.readthedocs.io/en/latest/usage/#youtube-music-premium))
- **create a `m3u` playlist file for all the artist's albums** (optional, personal preference). **Note:** it doesn't seem to dynamically generate the artist name with `{artist}`, so filling this in after generation is now the ONLY extra step.
- specify the **output filename/folder structure to save files in**, e.g `OK Computer/01 - Airbag.opus`
- **saves any errors** to a `.txt` file
- limits downloads to **main albums only** (no singles/EPs - optional, personal preference)

---

*"But juni!" I hear my non-existent readers cry. "Where are the cookies passed?"*


I hear you, friend. But due to cookies being rotated in-browser/expiring, relying on a static `.txt` file is largely inefficient, as they seem to expire every hour or so (browsers will likely behave differently). As `spotdl` uses `yt-dlp` to work under the hood, and was just erroring out with `AudioProviderError: YT-DLP download error` whenever my cookies expired, I went to `yt-dlp` to confirm my suspicions that manually passing my old static `cookies.txt` was the culprit:

``` go 
WARNING: [youtube] The provided YouTube account cookies are no longer valid. They have likely been rotated in the browser as a security measure. For tips on how to effectively export YouTube cookies, refer to https://github.com/yt-dlp/yt-dlp/wiki/Extractors#exporting-youtube-cookies.
```

**Couldn't be clearer!** 

As `spotdl` doesn't have a native `CLI` flag, afaik, to read current cookies from browser, we can utilise the dynamic `--cookies-from-browser` flag that `yt-dlp` has to grab cookies from your current YoutubeMusic session without relying on a static `cookes.txt` file generated with something like the [`cookies.txt extension.`](https://addons.mozilla.org/en-US/firefox/addon/cookies-txt/)

To do this, I created a small folder within my user's `PATH` (& `~/.zshrc`) to hold this script, and any other future wrappers I make:
``` bash
## making & adding ~/bin (for my private user scripts) to $PATH
mkdir ~/bin
export PATH="$HOME/bin:$PATH"
# check is in $PATH
echo $PATH | tr ":" "\n" | grep /Users/youruser/bin
# add the following to your ~/.zshrc to have it persist across new shells:
export PATH="$HOME/bin:$PATH"

```

Next, I just make the script below that simply grabs & saves a fresh cookie file from my browser in `NETSCAPE` format, by searching a [totally randomly chosen video](https://music.youtube.com/watch?v=dQw4w9WgXcQ) (& silencing all output through redirection to `/dev/null`). Then, running `spotdl` with that newly-generated cookie file & passing all user arguments (like the song/playlist to be downloaded) with `"$@"`.

``` bash
#!/bin/bash
# wrapper to run spotdl with fresh cookies from your browser of choice (firefox, for me)

# save fresh cookies to temp file
yt-dlp --cookies-from-browser firefox --cookies /tmp/yt_cookies.txt https://music.youtube.com/watch?v=dQw4w9WgXcQ -O id > /dev/null 2>&1

# now run spotdl with that cookie file
spotdl --cookie-file /tmp/yt_cookies.txt "$@"

```

(remember to `chmod +x ~/bin/spotdl.sh` after!)

Now, all I have to run to grab a playlist of songs from an artist I'd like is:

``` yaml
spotdl.sh URL
```

Optionally, if I feel that the given playlist may have missed some songs, I can tack on `--fetch-albums` and it'll ensure it grabs the full albums for me, too! 

Now, all that's left to do is **sail away**, and, most importantly, **use your cancelled spotify fees to **support the artists directly instead!!!!!** 

<div style="display: flex; justify-content: center; align-items: center; gap: 10px; width: 100%;">
  <img src="https://web.archive.org/web/20091022160937im_/http://www.geocities.com/multilogan/ca154.gif" style="max-width: 200px; height: auto;">
  <img src="https://web.archive.org/web/20091027010028if_/http://ar.geocities.com/lossusti/images/ahorasi.gif" style="max-width: 200px; height: auto;">
</div>

# *extra!! extra!!:* see this [excellent article](https://lunamouse.bearblog.dev/day110/) by my good friend on a related topic:
It's *somewhat* the "inverse" to my article (which is largely digital) but... I still feel holds relevance. Taking back control of **what "ownership" means**, in the ways & formats that are **unique to the individual using them.** To make a larger difference overall through small steps that lead to greater pushback. Be it `DVDs`, or `.mp3s` (or, `opus`'s, lol) - one rip at a time. **[What would clippy do?](https://www.youtube.com/watch?v=2_Dtmpe9qaQ)**

Further, here's another spectacular video (part of a series) on [a more mindful/intentional use of media & assessing the notion of "consumption"](https://youtu.be/VzKr-tMr8qQ?si=uJFdcvmkx3b6jpRr) in the modern era.