---
title: part 2 - uh... *liberating* your spotify library!
date: 2025-08-30
description: ""
toc: true
math: true
draft: false
categories:
  - spotdl
  - musicbrainz picard
tags:
  - spotify
  - youtube-music
  - yt-dlp
---

**Please note:** *this is a downloading service that uses public spotify playlist information to download songs from YOUTUBE MUSIC, which is a service that I PAY FOR with a YOUTUBE PREMIUM SUBSCRIPTION. Please understand the intentions behind using this tool, and adjust your use accordingly.* **Above all, ensure that you support the original artists that bring media you value to your life.**

[`spotdl`](github.com/spotDL/spotify-downloader) is an **AWESOME** little project that uses [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) & [`ffmpeg`](https://ffmpeg.org/) (at a high level) to scrape data from a provided public spotify playlist/song link, and download each corresponding song from **YouTube Music**.

# Here's how to install & use `spotdl` (on mac).
- [Install Guide](https://github.com/spotDL/spotify-downloader)
- [The docs (to read, even!)](https://spotdl.readthedocs.io/en/latest/)

1. [Install `pip`](https://www.geeksforgeeks.org/python/how-to-install-pip-in-macos/), ensure you have the latest version, & that [python](https://www.python.org/downloads/) is accessible within your `PATH` (see linked guide)
2. Open the terminal & install spotdl, **specifically the slightly older version** (see [here - known issue](https://github.com/spotDL/spotify-downloader/issues/2470)), with `pip install spotdl==4.4.0
3. Then, either [read the docs](https://spotdl.readthedocs.io/en/latest/usage/) or run `spotdl --help` to find out more. Navigate to your directory where you'd like the files, decide on the [supported format](https://spotdl.readthedocs.io/en/latest/usage/#audio-formats-and-quality) you'd like to download in, and it's as simple as:
   `spotdl download [playlist-url] --format [format]`. 
   **e.g.** `spotdl download https://open.spotify.com/playlist/0l7earlfnbGy39sGdYhMt2\?si\=73c7dsdc4fe624dc --format opus`
4. **(Optional)** I also open the folder in Musicbrainz to sort it into artist/album/song folders, and check all the metadata is there, before copying it over to my music library!

<div style="display: flex; justify-content: center; align-items: center; gap: 10px; width: 100%;">
  <img src="https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExNW9rcmRrYmY1ZTNqN2ZieTc2ZTh4eTYyaHo2NDVqNnlvM2hpMXI5ZyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/n4H4kEDHa0ByHkslC2/giphy.gif" style="width: 50%; height: auto;">
  <img src="https://media1.tenor.com/m/NSScQEBfZPQAAAAd/captain-sparrow-smiles.gif" style="width: 50%; height: auto;">
</div>
