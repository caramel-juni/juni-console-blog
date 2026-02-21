---
title: "media ripping on linux with k3b - a guide!"
date: 2026-02-20
description: ""
toc: true
math: true
draft: false
categories: k3b
tags: 
- linux
- cd
- media ripping
- retro
- freexp
- q4os

---

<img src="https://juniblog.goatcounter.com/count?p=/media-ripping-linux/" style="display: none">

**My most recent endeavour:** transforming my cute lil second-hand `Panasonic LetsNote CF-SX2` into a retro, `Windows-XP`-era (because my childhood absolutely ***demands*** it) **`Linux` media ripping and burning machine!**

![](/posts/35/attachments/retroburn-0.jpeg)

---

# OS of choice: [FreeXP](https://xpq4.sourceforge.io/) *(Q4OS, debian-based distro)*
Ensure to grab the - [FreeXP live CD image](https://sourceforge.net/projects/xpq4/files/freexp/) for the retro windows goodness!

1. Flash to USB drive with rufus/BalenaEtcher, or drop onto a Ventoy drive.
2. Boot into live OS, tweak settings to your liking, and once done, click on the `install Q4OS` (or similar) shortcut on the desktop to write the changes to your disk. Don't worry, you can always customise more later (the same app configuration shortcuts will be present when you re-enter the OS after installing)
3. Once installed on disk, log in and use the `Desktop Profiles` (or, just the` Software Packages`) tool to kit your desktop with your desired programs. For me, I went with the `Q4OS Basic` suite of apps/system packages, and installed additional software (notably, [k3b](https://github.com/KDE/k3b/tree/master)) using the `Software Packages` tool. These can also be done via the `CLI` with the regular `sudo apt install...`.
4. **[Optional]** I downloaded the latest self-updating & contained binary of `yt-dlp` separately (as the `apt` version is very out of date, given how this tool needs to be bleeding-edge to adapt to YouTube's changing API restrictions), made it executable with `chmod +x yt-dlp`, then moved it to `~/.local/bin`. I then made the `~/.local/bin` path accessible system-wide by adding it to my `~/.bashrc` with `echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc`, and reloaded my shell with `source ~/.bashrc` for the changes to take place.
5. Enjoy downloading, burning and ripping music with `k3b` (see below for my workflow!)

---

# [k3b](https://github.com/KDE/k3b/tree/master) `CD` burning process
- [Handy `k3b` manual](http://www.converttolinux.com/sbc/k3b.pdf)
- [`k3b` github](https://github.com/KDE/k3b/tree/master)
- [Media_Class: Rip and BurnCDs](http://wiki.freegeek.org/index.php/Media_Class:_Rip_and_Burn_CDs) (with `k3b`)

*⚠️ **BIG CAVEAT** ⚠️ - upon later research, `CD-Text` may not even be possible to embed within the files themselves in the large majority of cases, or even be read consistently across various `CD` players... **[see here for details and (very few) alternatives](https://unix.stackexchange.com/questions/798286/how-to-insert-metadata-in-audio-cd-tracks-with-linux)**. However, [`k3b` at least writes `CD-Text`, so this is the closest thing I could find in my (brief) search.](https://forums.linuxmint.com/viewtopic.php?t=204116)*

1. Install required dependencies to enable helpful `k3b` plugins. The only *essential* one for me was to **normalise audio** (`k3b` will prompt you when attempting to select this option in the burning menu if it can't detect it), ensuring your media has a generally cohesive volume profile. For me, this just required `sudo apt install normalize-audio` and restarting `k3b`.
2. Insert your `CD`, and drag your desired music files from the `Source Pane` (top) into the `Model Pane` (bottom). Add/remove/reorder tracks as you please with the (right click-accessible) context menu. **Ensure that the correct disc size is detected, and be wary that your songs must not exceed BOTH the disc's FILE SIZE limit**, AND the **TOTAL TIME LIMIT.** This tripped me up, as I chose my set of songs based on the disc's **file size alone** (700mb), and was **way** over the supported ~`80min` listening time for my `CD` (this is displayed visually in `k3b` at the bottom).
3. Once you're set, you can optionally do a `Simulation` run to test the disk writing speed. It can occasionally error out if it's too high, for either your CD burner or the CD itself. So I tested mine (which was rated up to `24x`) on the `16x` setting to be safe, and that only took 7min and completed fine, so I stuck with that given my `CF-XS2` ain't the newest thing.
4. For CDs, I'd recommend setting the burning type to `Disk At Once (DAO)` mode ([see why here](https://www.inshame.com/2025/04/cd-recording-modes.html)), and adjust the time between tracks by **selecting all** of the tracks in the `Model Pane` (bottom) and clicking `Properties --> Options` and adjusting `Post Gap`.
5. Now, for the real deal. Here are the settings I triple check are selected:
	- `Advanced --> Normalise` the audio. Select `Misc --> Normalize`, note the popup reminding you that it can't do this on the fly, and then go back to `Writing` to check that at least `Create Image` has been auto-selected. This selection is REQUIRED to *first* **temporarily write the normalised files to your computer's filesystem**, after which the burning process of these normalised files to the `CD` disk can commence. Select `Remove Image` if you want `k3b` to clean these files from your computer's filesystem immediately afterwards (they are cleaned upon closing the app/rebooting though, too.)
	- `CD-Text --> Write CD-Text`. **Ensure** this is checked! Leave the fill-in text boxes blank unless you want to override the existing values that `k3b` has detected on your files (shown in the `Model Pane`).
	- `Speed` - don't set this too high, determine what your CD type & disc burner type is capable of with a `Simulate` run (as shown above). Because if the process errors out due to setting it too high, unless you're using a rewritable `CD` (`CD-RW`), you can't add any more beyond where the burning process terminated!

	![](/posts/35/attachments/k3b-settings.png)
	![](/posts/35/attachments/k3b-normalise.png)
	![](/posts/35/attachments/k3b-writecd.png)

6. Then, after **triple checking** the above, click `Burn` and watch the magic happen!
7. To check whether the files and `CD-Text` were written correctly, re-insert the disc and check that all the tracks & text are present within the `Source` pane (see below).

	![](/posts/35/attachments/k3b-metadata.png)
	
	***Note:** the files may have to be manually re-tagged with **file metadata** (I haven't tested or tried this, though) to show up correctly in digital music player applications like [`Strawberry Music Player`](https://www.strawberrymusicplayer.org/), but I believe with a `CD-Text` present, some car audio systems will be able to display the file metadata. Hopefully... otherwise perhaps [try this guide here](https://www.hanselman.com/blog/how-to-write-or-burn-a-cd-cdr-that-includes-cdtext-with-imgburn), or see the ⚠️ **BIG CAVEAT** ⚠️ section above.*

---

# `k3b` Plugins
I found that enabling some of the `k3b` plugins was a bit troublesome on debian, with rather [sparse documentation](https://github.com/KDE/k3b/blob/master/INSTALL.txt) regarding the additional packages needed, so I'll list what I had to additionally install below to get the plugins working. The following work fine (as of `debian 12`) just installing with `apt`, and were enough for my needs.
- `normalize-audio`
- `vcdimager`

... the rest were either deprecated (note - this software, and burning CDs in general, is *old!*) or required manual pulling/building from source of the older programs to use. 

- `emovix` [(src)](https://askubuntu.com/questions/1112473/18-04-lts-is-there-a-installation-candidate-for-the-emovix-package)
- `transcode` [(src)](https://forums.linuxmint.com/viewtopic.php?t=425848) - just install & use [handbrake](https://handbrake.fr/) instead...

![](/posts/35/attachments/k3b-plugins.png)


---
# Tip: Writing `CD-Text` Data to files before burning:

*⚠️ **BIG CAVEAT** ⚠️ - upon later research, `CD-Text` may not even be possible to embed within the files themselves in the large majority of cases, or even be read consistently across various `CD` players... **[see here for details and (very few) alternatives](https://unix.stackexchange.com/questions/798286/how-to-insert-metadata-in-audio-cd-tracks-with-linux)**. However, [`k3b` at least writes `CD-Text`, so this is the closest thing I could find in my (brief) search.](https://forums.linuxmint.com/viewtopic.php?t=204116)*

Given that general metadata "tags" (applied by programs like Exiftool, and MusicBrainz) and `CD-Text` data can occasionally not always be entirely transferrable, often using an audio-specific tagging tool to rewrite the tags as `CD-Text` data for the specific filetype (e.g. `.mp3`) can help. Well, it did in my case, at least.

After just adding the song names as the general "`Title`" metadata tag in Musicbrainz, when processing the files in `k3b`, it did **not** populate the `Title (CD-Text)` field with these added `Title` values. 

If this happens for you, I recommend using a tool like [`eye-d3`](https://eyed3.readthedocs.io/en/latest/installation.html) to rewrite these `Title` tags properly so they are processed as `CD-Text`-valid tagsn `k3b`. Here are the commands I used to do so below:

`bash`:
``` bash
#nstall a tool like eyeD3
brew install eye-d3

# This command sets the "Title" CD-Text data to the extension-stripped version of your file's name. 
# E.g. "track01.mp3" --> Title=track01. 

for f in *.mp3; do name="${f%.mp3}" eyeD3 --title "$name" "$f"; done
```

After that, upon loading them into `k3b` to burn, the `Title (CD-Text)` column was populated properly!

![](/posts/35/attachments/k3b-titles.png)


⭐️ ***~ hopefully this helps some other nostalgic media (pirate? 🏴‍☠️) on their own journey to CD-freedom on Linux!*** ⭐️