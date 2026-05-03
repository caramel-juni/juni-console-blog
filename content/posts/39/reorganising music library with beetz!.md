---
title: ""
date: 2026-04-24
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking

Here's a comprehensive guide to doing this with beets. It's the right tool for exactly what you're describing — everything you want is achievable with the right config and plugin set.

---

## The Overall Strategy

The safest approach is to run beets **on your Mac** (or a machine with direct filesystem access to the NAS share), pointing it at your NAS via SMB. You don't need to SSH into the NAS itself.

**Phase order matters:**

1. Back up first
2. Find & confirm duplicates
3. Import + tag + reorganise
4. Fix playlists

---

## Step 1 — Back Up

Before anything else: snapshot or clone your music folder. If your NAS supports ZFS/Btrfs snapshots, take one now. If not, `rsync` to another location. Beets moves files around and you want a safety net.

---

## Step 2 — Install Beets on your Mac

```bash
pip3 install beets
pip3 install beets[fetchart,embedart,acousticbrainz]
```

Or using `pipx` to keep it isolated:

```bash
brew install pipx
pipx install beets
```

---

## Step 3 — The Config File

Create `~/.config/beets/config.yaml`:

```yaml
directory: /Volumes/NAS/music          # your SMB mount point
library: ~/beets_library.db            # keep the DB local, not on NAS

import:
  move: yes                            # move files (not copy) into new structure
  write: yes                           # write corrected tags to files
  log: ~/beets_import.log              # log everything for review
  timid: yes                           # ask before doing anything uncertain
  languages: en                        # prefer English metadata
  quiet: no                            # interactive mode — you confirm matches

plugins:
  - musicbrainz
  - fetchart
  - embedart
  - duplicates
  - scrub
  - playlist
  - missing
  - info

# Lidarr-compatible path format
paths:
  default: $albumartist/$album/$track - $title
  singleton: Non-Album/$artist - $title
  comp: Compilations/$album/$track - $title

# Zero-pad track numbers to 2 digits (e.g. "01", "02")
# $track is already formatted by beets

musicbrainz:
  genres: yes
  extra_tags: [year, catalognum, country, media, label]

fetchart:
  auto: yes
  cautious: yes                        # only fetch if confident
  sources:
    - coverart
    - itunes
    - amazon

embedart:
  auto: yes
  compare_threshold: 10

scrub:
  auto: yes                            # clean up legacy/junk tags on import

playlist:
  auto: yes                            # update .m3u paths when files move
  playlist_dir: /Volumes/NAS/music/Playlists
  relative_to: /Volumes/NAS/music
```

The path format `$albumartist/$album/$track - $title` gives you exactly the Lidarr structure you want: `Bob Dylan/Blood on the Tracks/01 - Tangled Up in Blue.flac`.

---

## Step 4 — Find Duplicates First

Before importing, run the duplicates plugin to review them:

```bash
beet duplicates
```

To see duplicates with file paths (so you can decide which to keep):

```bash
beet duplicates -p
```

To delete the lower-quality duplicate (keeps the higher bitrate version) — but **review the list first**:

```bash
beet duplicates -d    # delete duplicates (prompts)
```

The Duplicates plugin lists duplicate tracks or albums — it won't auto-delete without your say-so in interactive mode.

---

## Step 5 — Run the Import (Interactive)

```bash
beet import /Volumes/NAS/music
```

For each album beets finds, it will show you:

- The best MusicBrainz match with a similarity score
- What it would rename/retag
- You type `A` (apply), `M` (manual search), `S` (skip), or `I` (import as-is without changing tags)

**For anything it can't match**, choose `S` (skip) or `I` (import as-is). Then after the run:

```bash
grep "skip" ~/beets_import.log > ~/unrecognised_artists.txt
```

This gives you your manual review list of everything beets left alone.

To also run a pass that just lists what's unmatched without moving anything:

```bash
beet import --nowrite --nofix /Volumes/NAS/music
```

---

## Step 6 — Playlist Repair

The playlist plugin can update playlists automatically every time an item is moved or deleted, controlled by the `auto` configuration option. With `auto: yes` in your config and `playlist_dir` pointing to wherever your `.m3u` files live, beets will rewrite paths in those playlists to reflect the new locations as it moves files during import.

The key setting is `relative_to` — set it to your music root so playlists use relative paths, which survive drive remounts:

```yaml
playlist:
  auto: yes
  playlist_dir: /Volumes/NAS/music/Playlists
  relative_to: /Volumes/NAS/music
```

---

## Handling Unrecognised Artists

When beets can't find a confident MusicBrainz match, **skip** those albums during import. After everything else is done:

```bash
# List everything NOT in the beets database (still unimported)
beet import --timid /Volumes/NAS/music/[SkippedFolder]
```

Or just grep the log:

```bash
grep -E "^(Skipping|skip)" ~/beets_import.log
```

Keep a text file of these for manual tagging — tools like **MusicBrainz Picard** (free, excellent) are great for manually matching stubborn albums before re-running beets on them.

---

## Practical Tips

- **Start small** — test on one or two albums before unleashing it on your whole library
- **`--pretend` flag** — `beet import --pretend` shows what would happen without doing it
- The `timid: yes` setting in the config means beets will ask you before applying any match below ~95% confidence
- If you're on a large library (10k+ tracks), expect the initial import to take hours — it's querying MusicBrainz for each album
- MusicBrainz has rate limits; beets handles this automatically but it means slow going on big libraries

---

## Tool Summary

|Task|Tool|
|---|---|
|Metadata tagging + renaming|beets + MusicBrainz plugin|
|Duplicate detection|beets `duplicates` plugin|
|Album art|beets `fetchart` + `embedart` plugins|
|Playlist path repair|beets `playlist` plugin|
|Stubborn unmatched albums|MusicBrainz Picard (GUI, manual)|
|Tag cleanup|beets `scrub` plugin|

The whole pipeline is well-supported and battle-tested for exactly this use case. The interactive import mode means you're always in control before anything gets moved.





















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

