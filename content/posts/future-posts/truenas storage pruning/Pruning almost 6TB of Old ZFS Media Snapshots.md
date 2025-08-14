---
title: Pruning almost 6TB of Old ZFS Media Snapshots
date: 2025-08-13
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---
Even after going through my qbit downloads and pruning over 400+ unused/pure ratio torrents & associated content files, my 8TB of remaining storage was still at... 8TB remaining. Yet the content files (as seen in my FileBrowser app, or via the `CLI`) were definitely gone.

The culprit?

`ZFS` snapshots.

To see them, navigate to the **culprit dataset snapshot location in the TrueNAS `GUI`** (where there will likely be a lot more than seen below, if you've set them up to be periodic... this was *after* I deleted the old 50+ snapshots):
![](Screenshot%202025-08-13%20at%201.38.26%20am.png)

Or, for a **more concise comparison of how much storage is currently being taken up by these snapshots**, open a root shell session in the TrueNAS `CLI` with `sudo -i` and then run `zfs get usedbysnapshots path/to/dataset` to determine **the total space your snapshots are consuming for that dataset**. This is, as was for me, the likely culprit for any remaining file usage showing up as still "present" after "deleting" the files in something like qbit or the file explorer:

![](Screenshot%202025-08-13%20at%201.33.10%20am.png)
As you can see above, these snapshots originally took up `5.45TB` of space (which I had just cleared via deleting the torrent files). As I removed the slew of old `tank/data` snapshots **via the TrueNAS `GUI`** (as it felt a bit "safer" to do it this way, because it's recommended by TrueNAS to do in this fashion/more "officially" supported), you can see the referenced space trickle down to a measly `1.07MB` difference from the storage space the files occupy on disk. You can think of this number as the **"difference"**, per se - so there are now **very few** deleted files being referenced (and thus showing up in storage) in past snapshots.

- *You can also list **all** snapshots with `zfs list -t snapshot`, but will need to likely `grep` the output to narrow it down.*

**Total savings:** `8.5TB` free space --> `14.29TB` free space

***Hope that helps for future pruning!*** 
