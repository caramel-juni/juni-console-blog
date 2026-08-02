---
title: The rooting, firmware analysis and hardcoded, reset-persistent credentials of the TP-Link TL-841N!
date: 2026-08-02
description: "round 2: rooting & analysing firmware of the TP-Link TL-WR841N"
toc: true
math: true
draft: false
categories:
  - hardware hacking
tags:
  - linux
  - shell
  - uart
  - electronics
  - tp-link
  - tl-841n
  - router
---

Now, let me just preface this with a disclaimer:

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/60124.jpeg" style="width: 70%">
<figcaption><i></i></figcaption></div>

... and get used to this puppo, as you may see this a few more times in this post :').

In light of continuing my bumbling foray into the hardware hacking landscape, I bought a bottom-of-the-line $10 [`TP-Link TL-841N(EU)`](https://www.tp-link.com/uk/home-networking/wifi-router/tl-wr841n/) router off a random fellow on Facebook Marketplace, in a *thrilling*, *high-stakes* deal conducted in the middle of... a nearby mall.

My intention behind such a daring exchange was to **practice the end-to-end process of pulling apart an IoT device** to poke at it, **access debug logs**, potentially **get a root shell**, practice **various kinds of firmware extraction** (via UART & via on-chip flash memory), and even have a **mosey about the filesystem for some potential security vulnerabilities** later down the road. 

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/21866.jpeg" style="width: 70%">
<figcaption><i></i></figcaption></div>

Here's a short overview of the journey so far, documented below:

``` bash
1. Cracking it open: Finding the UART & getting connected
   
2. Dumping the firmware (Method 1. - UART & tftp)
   
3. Dumping the firmware (Method 2. - on-chip flashrom chip extraction)
   
4. Un-squashing the root filesystem
   
5. Having a Look-see - Preliminary Snooping/Analysis
```

Hang around until the end for discovering what kinds of various **plaintext, hardcoded creds from the previous owner (censored) could be found on this device**... one of which would survive **even a full "router reset"**. 


Yeah. Kinda... no bueno? 


***Let's dig in.***

---

# 1. Cracking it open: Finding the UART & getting connected
I began by searching the router model number up on the [FCCID](https://fccid.io/TE7WR841NV13) to check for its datasheet, to get information on the PCB, voltage levels & the available chips on the board.

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-07-31%20at%209.30.22%20pm.png" style="width: 70%">
<figcaption><i></i></figcaption></div>

Opening it up and finding the very-well-labelled [UART ports for serial/debug interface access](https://www.hardbreak.wiki/hardware-hacking/interface-interaction/uart) was straightforward, with one quirk being that the flash was found on the underside of my board - model number `GD25Q64CSIG` ([datasheet](https://www.alldatasheet.com/html-pdf/1151509/GIGADEVICE/GD25Q64CSIG/3543/5/GD25Q64CSIG.html)). 

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/77135.jpeg" style="width: 40%">
<img src="/posts/42/attachments/53703.jpeg" style="width: 40%">
<figcaption><i>Finding the UART ports (four "traffic light" holes on right picture) on the shelled router (left)</i></figcaption></div>

If your device isn't as friendly with labelling, you can also use a multimeter to probe each suspected UART port at boot time to determine which pin is which - the device's `TX` pin **should have a fluctuating voltage during boot** (due to it transmitting various boot logs in the form of serial `1`s and `0`s, corresponding to fluctuations in voltage), and the `GND` pin should be `0V`.

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/sss.jpg" style="width: 70%">
<figcaption><i>Probing the suspected UART pins at boot until I found one with a fluctuating voltage level (i.e. not the standard steady 3.3V or 0V for my router), indicating it's likely the `TX` port.</i></figcaption></div>

My trusty AliExpress [USB-to-UART adapter](https://www.aliexpress.com/item/4000589447982.html?) (which I checked to confirm supports both **3.3V and 5V output**, so we don't fry anything) had the following pinout/wire colouring: 
``` bash
# Four-color DuPont terminal wiring
RED: 5V
BLACK: GND
GREEN: TX
WHITE: RX
```

So, I connected the USB `GND` to the router's `GND` port (or can just touch grounded metal on the board), USB `RX` to the discovered router's `TX` port, and USB `TX` to router's suspected `RX` port (which can be found by trying the remaining two pins, until you get a successful input by spamming a key on your keyboard once connected). 

I soldered mine in for a better/persistent connection, & plug-&-play functionality 😜.
<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/56295.jpeg" style="width: 70%">
<figcaption><i>Soldering on the `GND`, `RX` and `TX` leads to access the debug interface hands-free!</i></figcaption></div>

Once I identified what `/mnt/dev` device my USB-to-UART device was and got connected up with `picocom -b 115200 --logfile bootlog-tplink.txt /dev/tty.usbserial-1210` (using the common baud rate of `115200`, which worked), we can see we're dropped into a `root` shell once again! Too easy 😅.

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-07-31%20at%2010.12.14%20pm.png" style="width: 90%">
<figcaption><i>(I also attempted to connect my phone to the generated TP-Link Wifi network, which generated the extra logs seen above)</i></figcaption></div>

Connecting my computer directly via one of the router's LAN ports, we can be assigned an IP and access the admin console as expected:
<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/68285.png" style="width: 90%">
<figcaption><i>Home sweet home... but how do we get in?</i></figcaption></div>

# 2. Dumping the firmware (Method #1 - `UART` & `tftp`)

So, now I could see & navigate the filesystem, I wanted to dump & transfer it to my local device to perform some preliminary analysis!

Listing the flash partitions at `/proc/mtd`, as well as a few other `mount` details, gives us a good point to start:
<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-07-31%20at%2010.28.40%20pm.png" style="width: 90%">
<figcaption><i>Some preliminary details about the router's configured memory partitions</i></figcaption></div>

## Preparing our receiving TFTP server
So we can transfer the firmware files over, I installed & started a [`tftp-now`](https://formulae.brew.sh/formula/tftp-now) server with `tftp-now serve` on my Mac (with `brew`, as am on apple silicon). 

**NOTE:** Ensure to create a folder in your home directory corresponding to where you're transferring the file from on your router (for me, from `~/var`), otherwise you'll get a "No such file exists" error when the `tftp` agent attempts to `put` its remote file on your computer (as it does so at the same path that it's uploading it from, `/var/`).

To solve the (many) errors shown below, I created a temporary `var` folder inside my `~` home directory to match up with the file path the router's `tftp` *wanted* to "put" to:
<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-07-31%20at%2010.55.03%20pm.png" style="width: 90%">
<figcaption><i>tftp-now server on my Mac</i></figcaption></div>
Now, connect your analysis computer to the shelled router's LAN port, & check that it's gets assigned an IP (like `192.168.0.200`) so they can talk to one another, despite not having internet access.

Switching back to our UART connection to the router, and checking we can begin to create a dump of the first flash partition with a tool like `cat` (if your router doesn't have `dd`, like mine). 

> **NOTE:** **Keep an eye on your router's storage** - if yours is also full (like mine was - use `df` to check), write the firmware dumps **incrementally** into the `/var` directory, which is `RAM`-backed and my largest partition (still only ~6.4 MiB).

To avoid overloading the RAM, for each partition dump, **I used the below process**:
1. **Dump flash partition with `cat /dev/mtd0 > /var/boot.bin`   ![](Screenshot%202026-08-02%20at%2011.06.46%20pm.png)
2. Transfer it over to the IP address of your receiving analysis laptop with `tftp -p -l /var/boot.bin 192.168.1.100`   ![](Screenshot%202026-07-31%20at%2010.57.42%20pm.png)
3. **Delete transferred flash partition** with `rm /var/boot.bin`, and repeat.
``` bash
# Process:
cat /dev/mtd0 > /var/boot.bin 
tftp -p -l /var/boot.bin 192.168.1.100 
rm /var/boot.bin

# Repeat above process for each sector, rm'ing as you go
cat /dev/mtd1 > /var/kernel.bin
cat /dev/mtd2 > /var/rootfs.bin
cat /dev/mtd3 > /var/config.bin
cat /dev/mtd4 > /var/romfile.bin
cat /dev/mtd5 > /var/rom.bin
cat /dev/mtd6 > /var/radio.bin
```

Tedious, but how it had to be (unless performing an on/off-flash chip extraction, or you have a USB interface on your router to write to).

However, for a CLI quality of life boost as stated in [this article](https://www.zerodayinitiative.com/blog/2019/9/2/mindshare-hardware-reversing-with-the-tp-link-tl-wr841n-router), "*we can make our lives much easier by uploading our own fully-loaded BusyBox via the existing TFTP client on the device. You may find a precompiled little-endian MIPS BusyBox binary on the [official](https://busybox.net/downloads/binaries/1.21.1/) website.*" This will give us access to *significantly* more standard linux commands to use on the router.

Again, well, it should be evident, but...

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/60124.jpeg" style="width: 70%">
<figcaption><i></i></figcaption></div>

We're learning. It worked in the end. Firmware files extracted to my local computer over `tftp` & `UART`!

# 2B - Dumping the firmware (Method #2 - on-chip `flashrom` chip extraction)

An alternative way of analysing the filesystem is via an on-chip (or off-chip, if you want to desolder a tiny `IC` and have a hot air gun) firmware extraction. For this, I used the *"[poor man's flash extraction tool](https://www.youtube.com/watch?v=6Z5aWu9tqmA&t=207s)"* - the CH341A.

I first found the flash chip - on the back of the board - and checked it *was* a flash chip with it's model number. This also told me that the flash rom voltage is at 3.3V ([datasheet](https://www.alldatasheet.com/html-pdf/1151509/GIGADEVICE/GD25Q64CSIG/3543/5/GD25Q64CSIG.html)) so the CH341A i have is safe to use. Some chips run at 1.8V, not 3.3V, so before carefully placing the clip on the clip and plugging in the programmer, **check your chip’s voltage** (via online datasheets or multimeter). If it's 1.8V, use a voltage adapter (bought with the adapter) to avoid possible damage.

Also, ensure the clamp-side's red cord is in line with to `PIN 1` of the router's flash chip, which should be (typically marked with a small circle in the corresponding corner).

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/31008.jpeg" style="width: 47%">
<img src="/posts/42/attachments/49229.jpeg" style="width: 40%">
<figcaption><i>The on-chip extraction, with the circle marking where to align the corner of the clip with the red wire leading to it</i></figcaption></div>

Beginning of the chip model number often corresponds to type: so for our `25Q64CSIG`, the `25` at the start means we would position our 8 pins over the slots marked as `25 SPI BIOS`, whereas if our chip said `26`, it would go on the `EPROM I2C` side. 

After seating the PCB & connected cord in the USB programmer **with the RED cord on the top right**, as pictured below, **double check that the red cord on the clamp-side is attached to `PIN 1` of the router's flash chip** (typically marked with a small circle, as mentioned before).
<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/74752.jpeg" style="width: 40%">
<img src="/posts/42/attachments/signal-2026-08-02-18-23-49-698_012.jpg" style="width: 40%">

<figcaption><i>The on-chip extraction, with the circle marking where to align the corner of the clip with the red wire leading to it</i></figcaption></div>
- [Video explaining the CH341A connection process in detail (Matt Brown)](https://www.youtube.com/watch?v=6Z5aWu9tqmA&t=207s)

Then, simply install & fire up [`flashrom`](https://formulae.brew.sh/formula/flashrom), and run the following command to extract the firmware!
``` bash
flashrom --programmer ch341a_spi -r modem.bin
```

Now we have `modem.bin`, which (being a full flash dump) should contain inside it, the same manually-extracted flash partitions as extracted via `ftpd`. However, to analyse it more meaningfully, we can split it up into the various `boot`, `config`, `rootfs` sectors like before with `dd`.
## Manually carving out the flash sectors
Using the **memory sizes/addresses** found before with `/proc/mtd` when on the router, we can manually carve our `modem.bin` flash dump into the identified sectors for analysis.

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-07-31%20at%2010.28.40%20pm.png" style="width: 90%">
<figcaption><i>The commands run earlier on the router to map out the flash memory sectors</i></figcaption></div>

To get our first sector, `mtd0`, which presumably contains [U-Boot](https://en.wikipedia.org/wiki/Das_U-Boot) based on our observed boot logs, we can use `dd` to carve the specified chunk out of `modem.bin`:
``` bash
dd if=modem.bin of=mtd0-boot.bin bs=1 count=$((0x20000))

# Search for strings identifying u-boot
strings -a mtd0-boot.bin | grep -Ei 'u-boot|boot|version|console|baud|mtd|flash'
```

In this case, my U-boot sector wasn't initially identified by `binwalk` automatically when I first analysed `modem.bin`, due to likely being a **customised, vendor-modified version of U-boot**. Hence why I decided to carve out the sectors manually according to the router's `/proc/mnt` information, just for some additional accuracy and organisation.

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-08-02%20at%207.01.48%20pm.png" style="width: 90%">
<figcaption><i>Using `binwalk` to analyse the dumped firmware's structure</i></figcaption></div>

The presence of a customised U-boot was confirmed with `strings` finding `Ralink UBoot Version` in the `mtd1` partition (the presumed linux kernel) when this part was carved out and analysed later on, indicating this was a [Ralink](https://en.wikipedia.org/wiki/Ralink)-modified U-Boot version.

Anyway, running the `strings` command again on the extracted suspected U-boot `mtd0` partition confirms it *is* the part of the flash containing U-Boot, and helps us identify more info about it, including U-Boot's version number and behaviour.

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/18442.png" style="width: 90%">
<figcaption><i>Using `strings` to extract information about the U-Boot sector</i></figcaption></div>

I repeated the above process to carve our each sector of the firmware dump, until I had all sectors, `mtd0-mtd6`, for analysis.

``` bash
# Carving out each sector from full modem.bin flash dump
dd if=modem.bin of=mtd0-boot.bin bs=1 count=$((0x20000))
dd if=modem.bin of=mtd1-kernel.bin bs=1 skip=$((0x020000)) count=$((0x140000))
dd if=modem.bin of=mtd2-rootfs.bin bs=1 skip=$((0x160000)) count=$((0x660000))
dd if=modem.bin of=mtd3-config.bin bs=1 skip=$((0x7C0000)) count=$((0x010000))
dd if=modem.bin of=mtd4-romfile.bin bs=1 skip=$((0x7D0000)) count=$((0x010000))
dd if=modem.bin of=mtd5-rom.bin bs=1 skip=$((0x7E0000)) count=$((0x010000))
dd if=modem.bin of=mtd6-radio.bin bs=1 skip=$((0x7F0000)) count=$((0x010000))
```

I asked the friendly (?) neighbourhood AI chatbot to help map a visual summary of the chip so far:
``` bash
0x000000 ┌───────────────────────────┐
         │                           │
         │ mtd0                      │
         │ Custom U-Boot 1.1.3       │
         │ Ralink                    │
         │ 128 KiB                   │
0x020000 ├───────────────────────────┤
         │                           │
         │ mtd1                      │
         │ Linux kernel              │
         │                           │
0x160000 ├───────────────────────────┤
         │                           │
         │ mtd2                      │
         │ SquashFS                  │
         │ 6.6 MiB                   │
         │                           │
0x7C0000 ├───────────────────────────┤
         │ mtd3 config               │ 64 KiB
0x7D0000 ├───────────────────────────┤
         │ mtd4 romfile              │ 64 KiB
0x7E0000 ├───────────────────────────┤
         │ mtd5 rom                  │ 64 KiB
0x7F0000 ├───────────────────────────┤
         │ mtd6 radio                │ 64 KiB
0x800000 └───────────────────────────┘
```

If we use `binwalk -e` to extract what it can automatically from the original `modem.bin`, it also gives us the **uncompressed kernel image** (`mtd1`) in the form of `decompressed.bin`, which checks out when looking at its identified magic bytes below:

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-08-01%20at%205.40.14%20pm.png" style="width: 90%">
<figcaption><i>Verifying that `binwalk` detects the linux kernel image on our second `mtd1` sector</i></figcaption></div>

# 4. Un-squashing the root filesystem

Another reason that I had to carve out and extract the `mtd2` `squashfs` filesystem manually with `dd` was, once again, **because I'm on a mac**. And the `sasquatch` command initiated as part of `binwalk`'s extraction process (when extracting a `squashfs` sector) continued to fail for me (despite being installed...), 

Oh well. At least we know what to do from above to get and un-squash the `rootfs` for analysis:
``` bash
# extract the squashfs filesystem directly
dd if=modem.bin of=mtd2-rootfs.bin bs=1 skip=$((0x160000)) count=$((0x660000))

# check it's squashfs
file mtd2-rootfs.bin

# unsquash it (uses xz) to explore
unsquashfs -no-xattrs mtd2-rootfs.bin
```

> **Note:** If you get errors like `create_inode: could not create character device squashfs-root/dev/zero, because you're not superuser!`, don't panic. As the filesystem contains device nodes under `/dev`, your computer (MacOS for example) may not permit a normal user to create those special device files. However, they're (allegedly) not usually needed for firmware analysis, but you can use pure Linux to `unsquash` this while preserving the device nodes with `sudo`.

*(yes, i know this would've just "all worked" on linux. i am waiting for my poor mac baby to die before the final leap.)*

Comparing the two extraction methods (left done via Method 1, `tftpd`, and right via on-chip extraction, Method 2), we can see **nearly identical copies of the filesystem to analyse**!

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-08-01%20at%204.53.00%20pm.png" style="width: 90%">
<figcaption><i>Comparing the results of our two extraction methods</i></figcaption></div>

Now, we can proceed to analyse the dumped binaries/unsquashed filesystems using `strings`, `grep`, and `binwalk`, to understand how the router works and perhaps even uncover some juicy vulns later down the track...!

But, I'll leave the groundbreaking vulnerability reversing to part 2 (or more capable souls than I), as this is getting long, but thanks for sticking along for the ride! We've eztracted firmware from a router in two ways; via `tftp` over `UART`, as well as by using `flashrom` for a direct on-flash-chip firmware extraction. \

But... we should have a peek before we go, shouldn't we? Just a little?


# 5. Having a Look-see - Preliminary Snooping/Analysis

> **NOTE:** I am just poking around here to learn more about what is/isn't exposed & accessible on a fairly typical IoT device that I own and have full authority over. The device was factory reset before being sold to me, and no discovered credentials were used to access any unauthorised material.

Now, to introduce you to the cheap & nasty firmware analyst's favourite tool: `strings`.

As stated on it's `man` page, `strings` *"...looks for ASCII strings in a binary file, object, or standard input."*. So we can quickly parse compiled `.bin` files and the like for a dirty peek at any readable strings that may exist within, which is most likely to be either text the program prints, or plaintext configuration values (depending on compilation type, of course).

Examining the `mtd3-config.bin` first, where router-specific configs should live, with `strings mtd3-config.bin | less`, we can actually find the router's hard-coded WPS password in plaintext, i.e. the one printed on the back of the router!


<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-08-01%20at%205.19.00%20pm.png" style="width: 90%">
<img src="/posts/42/attachments/52004.png" style="width: 90%">
<figcaption><i>Finding the hardcoded plaintext WPS password, located on the bottom of the router</i></figcaption></div>


Well, uh, upon further research: we've stumbled upon what appears to be a previously discovered "`CVE`" ([CVE-2026-4346](https://nvd.nist.gov/vuln/detail/CVE-2026-4346?utm_source=chatgpt.com)), in fact:

> *"The vulnerability affecting TL-WR850N v3 allows cleartext storage of administrative and Wi-Fi credentials in a region of the devices flash memory while the serial interface remains enabled and protected by weak authentication. An attacker with physical access and the ability to connect to the serial port can recover sensitive information, including the router’s management password and wireless network key. Successful exploitation can lead to full administrative control of the device and unauthorized access to the associated wireless network."*

(Although I'd say, if someone's got hardware access to your router's serial interface/flash chip in the first place, you're already pretty borked. And I wouldn't call it protected by "weak authentication"... ***no*** **authentication.**)

Another gem uncovered by `strings mtd3-config.bin | grep -ri "pass"` are hardcoded credentials for what appears to be previous **[PPPoe ISP/router provisioning credentials](https://www.privateinternetaccess.com/blog/what-is-pppoe/)** (the `@unitiair` portion strongly suggesting an ISP/service-provider account).

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/31126.png" style="width: 90%">
<figcaption><i>The hardcoded plaintext PPPoe ISP customer credentials, presumably from the previous router's owner (verified via OSINT)</i></figcaption></div>

Oopsies.

And for an even *bigger* oopsies/yikes, **even after performing a router factory reset**, these credentials were ***still*** **accessible via the freshly-dumped `config` partition of the firmware**. 

Given that I am *not* the local small business whose email is listed in plaintext in the un-redacted version of the picture above, *nor* a customer of Unitiair, I don't believe I should still be seeing this after the router was "reset".

This means that **not even a FACTORY reset of the device** (holding down `RESET` button for 10 seconds, and verifying reset was performed by checking boot logs, as detailed in the [TP-Link documentation](https://www.tp-link.com/uk/support/faq/497/)), which most consumers would presume would wipe all user OR ISP-modified settings from it, **can truly erase the ISP [PPPOe WAN credentials](https://www.privateinternetaccess.com/blog/what-is-pppoe/).** 

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/70235.png" style="width: 90%">
<figcaption><i>Boot logs during the router's factory reset</i></figcaption></div>
<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/23921.png" style="width: 90%">
<figcaption><i>Comparing the initial firmware dump to the factory-reset firmware dump</i></figcaption></div>

So, **a factory reset leaves a previous subscriber's broadband authentication credential recoverable from persistent flash storage.**, in `Firmware Version: 0.9.1 4.16 v0001.0 Build 170622 Rel.64334n` (the latest for [my EU model of the router](https://www.tp-link.com/uk/support/download/tl-wr841n/v13/#Firmware))


<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/22991.png" style="width: 90%">
<figcaption><i>The router's listed firmware version</i></figcaption></div>
<div style="text-align: center; margin-bottom: 1em">
<img src="https://media1.tenor.com/m/5YsvS7VKP5UAAAAd/side-eye-side-eye-monkey.gif" style="width: 70%">
<figcaption><i></i></figcaption></div>

Whilst you don't seem to be able to authenticate to *this* ISP itself (which, luckily for them, requires an account number to login, unlike *my* ISP which uses email), user/ISP modified credentials stored in plaintext persisting after a reset is... not a great privacy sign for what is considered a "factory reset" device.

Anyway...

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/52454.png" style="width: 70%">
<figcaption><i></i></figcaption></div>

Searching for more "sensitive" strings in the extracted `root-fs` (`mtd2`), we get both the router login from `./web/help/RestoreDefaultCfgHelpRpm.htm`, as well as the hashed password of the `admin` OS user.
``` bash

grep -RniE 'password|passwd|credential|admin' . 2>/dev/null
...
./web/help/RestoreDefaultCfgHelpRpm.htm:20:<li class="admin">Default User Name<B> - admin</B>.</lI>
./web/help/RestoreDefaultCfgHelpRpm.htm:21:<li class="admin_0">Default Password<B> - admin</B>.</lI>...
./etc/passwd.bak:1:admin:$1$$iC.dUsGpxNNJGeOm1dFio/:0:0:root:/:/bin/sh
```

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-08-01%20at%2012.10.09%20am.png" style="width: 90%">
<figcaption><i>`grep`ping the admin account's password hash</i></figcaption></div>

So, we can login to the router admin interface thanks to the golden keys of... `admin:admin`. Of course!
<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-07-31%20at%2011.17.36%20pm.png" style="width: 90%">
<figcaption><i>Behind the gates we sneezed on to open...!</i></figcaption></div>

Additionally, as we recovered an UNSALTED admin hash from `/etc/shadow`, we can try and crack the `admin` OS user account's password (whose permissions are mapped to `root`, `GUID=0`, so an account that's *kinda* useful):
- [Wordlists](https://github.com/jeanphorn/wordlist/blob/master/passwords/common.txt)
``` bash
## Create password hash file
printf '%s\n' '$1$$iC.dUsGpxNNJGeOm1dFio/' > admin.hash

## check it with cat
cat admin.hash

## download a wordlist (see link) & use with hashcat to crack MD5 hash (easy, as has no salt)
hashcat -m 500 -a 0 admin.hash common.txt --status
```
Our master account password was, of course, cracked within a few seconds...
<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/42/attachments/Screenshot%202026-08-01%20at%2012.20.17%20am.png" style="width: 90%">
<figcaption><i>Cracked in 1,2,3,4...</i></figcaption></div>

`admin:1234` - **fun times.**
**i'm quaking in my boots :').**

well, until next time - see you for the [squeakquel](https://en.wikipedia.org/wiki/Alvin_and_the_Chipmunks:_The_Squeakquel)!

<div style="text-align: center; margin-bottom: 1em">
<img src="https://i.pinimg.com/originals/98/ef/8e/98ef8e8978bd59f99e703dd6dd4df80f.gif" style="width: 90%">
<figcaption><i>(Jeanette is my spirit animal)</i></figcaption></div>






