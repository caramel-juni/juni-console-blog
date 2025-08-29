---
title: Music Metadata Identification - in MusicBrainz Picard
date: 2025-08-29
description: Music Metadata Identification - in MusicBrainz Picard
toc: true
math: true
draft: true
categories:
  - metadata
  - musicbrainz picard
tags:
  - musicbrainz
  - navidrome
---
For identifying metadata sassociated with plain `.mp3`s based on filenames, audio fingerprints, and more!

Say you have a large library of esoteric tunes, all of a manner of poorly-named files and few containing complete (or any!) metadata at all, making indexing via something like jellyfin or navidrome borderline impossible.

Well, try out musicbrainz picard!

# Pre-requisites:

Ensure your base folder (wherever files will be **MOVED TO** when saving) is set within **Preferences**. This defaults to your **user's home music folder on your computer**, which can be annoying if you're accessing files remotely on your `NAS` like I am over SMB, as it results in unecessary network R/Ws. I've set my base folder to a **staging folder on my NAS** (accessed via SMB) so I don't have to re-copy them over the network after Picard has bulk-renamed & sorted them.
   ![](Screenshot%202025-08-29%20at%2010.29.33%20pm.png)



# Now, for the workflow:

1. Import files/folder of files, which will appear as `Unclustered Files`. Select the desired files, and press `Lookup`. Tracks that are identified via the filename + musicbrainz lookup, will have metadata added & be **classified in the right hand pane** - **sorted by album** by default (just for viewing - these are not yet saved like this).
2. Files that are left ***unidentified*** by `Lookup` will remain within `Unclustered Files` on the left pane. 
   Re-select them, and click `Scan`. This will perform a more detailed lookup by `AcoustID` audio fingerprint, and add any it finds to the right pane.
3. Once that's identified any stragglers, and they're automatically organised by album with metadata added from `MusicBrainz` in the right pane, **select your file/folder renaming script of choice.** For me, I want to use my `Artist/Album/Track - Title` script for easy identification in Navidrome --> **SEE BELOW FOR CREATING THIS, OR USE THE `Preset 1: Default File Naming Script`**. **Select your script of choice**, and ensure that the `Move Files`, `Rename Files` and `Save Tags` options are ticked in `Options`. 
   **For me, my final config looks like this:**
   ![](Screenshot%202025-08-29%20at%2011.30.34%20pm.png)
4. **Select the MusicBrainz-metadata-enriched titles in the right pane**, and click `Save` to **rename** & **move** based on your script structure + base file path, and **write the smart-identified, MusicBrainz-enriched tags** to the file metadata.
5. **For any stubborn files that `Lookup` & `Scan` fail to identify** (still in left pane) - if they have **SOME** metadata (i.e. that required by your script - for me, `albumartist`, `album`, `tracknumber` and `title` tags) - just **select them** and press **Save** to **rename** & **move** them based on your script structure & **re-write their existing tags.**
6. For any **completely unidentifiable files**, you'll... **have to add the missing metadata manually yourself.** I just stick with the basics i mentioned before to get them into Navidrome. **You can always follow the following workflow to triage them for later categorisation on a rainy day, though:** 
	- `Cluster` them, `Tag` them with your dummy tag linked in a script for unsorted files (for me, `Mood`) with a value like `[UNSORTED] `.
	- **Select & activate** your `Unsorted Files` file naming script (see below for details on how to create this)
	- **Select** the problematic files, then press `Save` to have `[UNSORTED] ` appended to them + relocated for later manual identification!


# Setting your custom folder/file structure naming script:
As I'm aiming to import these into my music manager, `Navidrome`, I want the files to be organised like so: 
``` bash
	Artist/
	  Album/
	    01 TRACKNAME1.mp3
	    02 TRACKNAME1.mp3
	    ... etc.
```
For this, I could either use the default file naming script, as it includes a bunch of extra conditionals to try and get *roughly* this from the variously-formatted & identified files, metadata & filenames. But a simple custom saved script to achieve the above layout would be:
	`%albumartist%/%album%/$num(%tracknumber%,2) - %title%`
	![](Screenshot%202025-08-29%20at%2011.21.34%20pm.png)
   Please note these scripts rely on the presence of metadata (the `albumartist`, `album`, `tracknumber` and `title` tags) so be sure to try and identify them using the `Scan` & `Lookup` tools first (or... manually).

# Triaging unidentified files by appending [UNSORTED] to their filename (Script):
1. Mark any unidentifiable files (from `Lookup` and `Scan`) with a set tag you'd never use (for me, `Mood`).
   ![](Screenshot%202025-08-29%20at%2010.40.25%20pm.png)
2. Create a custom filenaming script that appends the value of `Mood` to each filename upon **Saving**, in `Options - Open File Naming Script Editor`, then ensuring the `File Naming Script Editor` is selected, and going again to `Script --> Add a new script`.
   Then, to append your chosen tag whilst keeping the filenames intact, use the following script: `%tagname-here%%_filename%`. This will just append the tag to the filename, but leave it functionally unchanged if that leading tag (for me, `mood`) is not present. *Check the preview down the bottom to see how this would affect your files.*
   ![](Screenshot%202025-08-29%20at%2011.06.13%20pm.png)
   Make sure to give this script a name, and just click `Make It So!` to save it for future use.
3. Ensure your newly-created file renaming script is selected in `Options --> Select file naming script`, **AND** that `Rename Files` is ticked. **These options will be applied upon selecting your files & clicking `Save`** in the UI.
   ![](Screenshot%202025-08-29%20at%2010.51.33%20pm.png)
4. Then, once you're all done, select the files and click `Save`, and voila! They should be renamed with the `[UNSORTED]` tag in my case, and saved/moved wherever your base folder is (see above for setting that).    ![](Screenshot%202025-08-29%20at%2010.54.37%20pm.png)

---
# For any files that don't get properly sorted into folders:

**NOTES & CAVEATS:** 
- For roughly-well-named files, in the format: `Artist - Trackname.mp3` (e.g. renamed via musicbrainz methods above).
- Will only sort into folders **ARTIST**, not by album (unless the filename contains the album, too, in which the scripts below can be modified to create subfolders)
Use the below `CLI` scripts (work in `sh`-derived environment, like `bash` or `zsh` - not natively on windows) to add them into existing artist folders, and create ones for new artists if they don't exist. Note whether each one is just a **copy-paste `CLI` command**, or a `bash script` with the presence of the `#!/bin/bash` and any notes.
# Sort files into folders by Artist - PREVIEWS the proposed changes to files:

``` bash
for f in *.mp3; do
  [ -f "$f" ] || continue
  artist="$(echo "$f" | sed 's/ - .*//')"
  [ "$artist" = "$f" ] && artist="Unsorted"
  echo "Would move '$f' → '$artist/'"
done
```

# Sort files into folders by Artist - will MAKE the proposed changes:

#### Quick & dirty, via `CLI`: 
(may break with special unicode character & spaces)

``` bash
for f in *.mp3; do
  # Skip if not a regular file
  [ -f "$f" ] || continue

  # Extract artist (everything before the first " - ")
  artist="$(echo "$f" | sed 's/ - .*//')"

  # Handle files with no " - " by putting them in "Unsorted"
  [ "$artist" = "$f" ] && artist="Unsorted"

  # Make the folder if it doesn't exist
  mkdir -p "$artist"

  # Move the file into the folder
  mv "$f" "$artist/"
done

```

#### Safer Option via bash script:
Moves files into artist folders, appends to existing folders if they exist, and handles Unicode, spaces, and special characters, without overwriting anything. Needs to run via a script, ensure to `chmod +x` it beforehand.

``` bash
#!/bin/bash
# Run this in the folder containing your mp3 files

# Preserve original IFS
OLDIFS=$IFS
IFS=$'\n'

for f in *.mp3; do
  # Skip if not a regular file
  [ -f "$f" ] || continue

  # Extract artist (everything before the first " - ")
  artist="${f%% - *}"

  # If no " - " in filename, put in Unsorted folder
  [ "$artist" = "$f" ] && artist="Unsorted"

  # Create artist folder if it doesn't exist
  mkdir -p "$artist"

  # Determine target filename
  target="$artist/$f"

  # If a file with the same name already exists, append a number to avoid overwriting
  if [ -e "$target" ]; then
    base="${f%.mp3}"   # Remove .mp3
    ext=".mp3"
    i=1
    while [ -e "$artist/$base ($i)$ext" ]; do
      ((i++))
    done
    target="$artist/$base ($i)$ext"
  fi

  # Move the file
  mv "$f" "$target"
done

# Restore IFS
IFS=$OLDIFS

```

---

# Playlists

Organised by `.m3u` files, which are just files that point to a set of paths to files included in the playlist, in order. E.g.:

```bash
/Artist1/Album1/song1.mp3
/Artist1/Album1/song2.mp3
/Artist2/Album1/song1.mp3
/Artist2/Album2/song1.mp3
.... etc.
```

I am just organising pre-existing playlists by putting them in a folder called `/music/[0] playlists/` in my `Navidrome`-watched directory, even if it means duplicating files. This was initially due to some complexities with re-organising existing playlists by sorting into artists/albums folder structure, then merging with existing music library when the songs already may exist, given that picard won't overwrite by default but instead add a `(X)` to the filename, and THEN face the addiitional problem of finding where those playlist files now live and dynamically re-linking them by creating an `.m3u`...

## But a potential work around for neater organisation COULD be:
- For songs within `CoolPlaylist/`
	- Identify & sort by album/artist/etc as shown above in picard.
	- Rename, move & tag files WITHIN the `CoolPlaylist/` directory so they are sorted by `Artist/Album` where possible. **ENSURE TO CHANGE BASE DIRECTORY (see prerequisite section above) TO THIS LOCAL `CoolPlaylist/` FOLDER BEFORE DOING SO!**
	- THEN create the `.m3u` file based on that folder structure, so it lists their locations as: `/music/Artist/Album/song.mp3`.
	- THEN merge the artist folders & songs inside with your existing library (either manually, or by changing the base directory folder to `/music` so picard will "merge" it somewhat intelligently (but not overwrite any duplicates it finds)
	- THEN drop the `.m3u` file into your `[0] playlists` folder, which should link all the newly-homed files together
	- Run an optional cleanup script of some kind to identify any duplicates created by picard not overwriting.
*This is cleaner, but it still requires **merging the artist folders with your existing library** and on top of that, **will STILL result in duplicate files**, just better organised ones.*

# So, for my use case, I just:
1. Import the playlist into Picard & `Lookup` + `Scan` to fill in & enrich the file metadata
2. Any files that don't have an album I add to an arbitrary one called `l0st s0uls` (just via a tag) to neaten it up in navidrome a bit.
3. I ensure `Move Files` tag is OFF in `Options` (the others on), then `Save` to write the metadate & rename.
4. Then `cd` into the `playlist-folder-name/` & run the below one-liner to generate the `.m3u` linking the files together based on their expected file path within Navidrome:
```bash
for f in *.mp3; do
    echo "/music/[0] playlists/$(basename "$PWD")/$f"
done > "$(basename "$PWD").m3u"
```
5. Then, just copy the playlist over into `/music/[0] playlists/` and am good to go!
   ![](Screenshot%202025-08-30%20at%202.53.50%20am.png)

