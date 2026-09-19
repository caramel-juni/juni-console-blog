---
title: ""
date: 2026-08-04
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking

### Misc. Resources:
- https://slava-moskvin.medium.com/extracting-firmware-every-method-explained-e94aa094d0dd
- https://ivanorsolic.github.io/post/hardwarehacking1/
- https://www.hardbreak.wiki/

### Dissasembly:
https://www.insidegadgets.com/2018/01/02/inside-the-netgear-telstra-cable-adapter/
- Interestingly there are 2x4 pin headers, labelly nicely, one reads **UART0 (BBS)** and the other **UART1 (LINUX)**
  ![](Screenshot%202026-08-11%20at%2012.11.31%20am.png)![](77911.jpeg)![](Screenshot%202026-08-11%20at%2012.09.58%20am.jpeg)

[25L6433F(M2J-08G) SPI flash chip](https://www.digikey.com/en/products/detail/macronix/MX25L6433FM2J-08G/28264861?utm_source=findchips&utm_medium=aggregator&utm_campaign=buynow) ([search here](https://www.alldatasheet.com/distributor/view.jsp?Searchword=MX25L6433F))

[Closest datasheet](https://www.alldatasheet.com/html-pdf/1244754/MCNIX/MX25L6433F/1281/7/MX25L6433F.html): 
![](Screenshot%202026-08-15%20at%204.25.19%20pm.png)

- Set tigard to `SPI` mode, as well as set power mode to `VTGT` (voltage provided by target, i.e. modem, while holding down reset button to isolate flash chip (?))
- Clip on flash to 8-pin chip, as above, aligning the red wire with chip select (dot)


## Summary:
Found 3 potential UART interfaces, photographed. The linux one doesn't seem to stream debug logs, no measurable voltage difference, but the BBS one does stream logs & seems to enter into a bootloader menu:
- Chip: **BCM3383ZD-B0**
- SPI flash: **JEDEC `0xc22017`, 8 MB, 64 KB blocks**
- Bootloader identifies two firmware images.
- Image 1 is at **`0x20000`**.
- Image 2 is at **`0x400000`**.
- Each image is **1,781,860 bytes** compressed.
- The bootloader explicitly says it detected **LZMA** and decompresses the image.
- The running image is **eCos**, not Linux.

We can interrupt the boot process with `p` to access **Broadcom bootloader's full maintenance menu**:
 - Could potentially set up an ethernet interface to extract firmware over ETH, but reading memory addresses (must be in offsets of 4, otherwise crashes - see second pic) is extremely tedious and doesn't seem to be easy to dump without serious reversing.
![](Screenshot%202026-08-10%20at%209.01.52%20pm.png)

![](Screenshot%202026-08-10%20at%209.14.31%20pm.png)

## Analysing reboot logs:
From holding reset/rebooting the router, bootloader reveals a number of interesting elements:

1. Dump flash - via CH341A easiest
``` bash
SPI flash ID 0xc22017
size 8MB
block size 64KB
```
2. Pressing `s` EARLY during boot & examine - `LOG: If you pressed the 's' key before this point, we will skip driver initialization...` - see if this changes bootup process
3. `LOG: Enter '1', '2', or 'p' within 2 seconds or take default...` - Try **`1`**, rather than `2`, on one boot. 
4. ==Parse entire opening debug logs for more clues== - running services, config files, etc.
5. Pressing one reset SEEMS to reveal a persistent set of creds, unsure what they're for/what usage they are, though.
   `Password:Password: dmnnnnbbnbbbkedghqiu 2guqw8q98ujjsk`
   ==But== this may also just be the TX logs overflowing: as when you're in this bootloader, every time you press a key you're prompted with a `Username:` and `Password:` that need to be entered to interact further.
   Due to the constant scanning stream output (`xxxxxxxx Hz`...) this makes the console noisy, but you **can** enter a full username (e.g. `admin`) and it will be logged as `Username: admin`, so the auth seems to work. However, the provided "password" of `dmnnnnbbnbbbkedghqiu`  yields no success, so is either unrelated, for a diff user, or just useless spam.![](Screenshot%202026-08-10%20at%208.37.08%20pm.png)

## Finding the Firmware `.bin` itself
Revealed the actual firmware file in the bootloader logs:
```text
CM450_1TLAUS_V1.01.03u_160812.bin
```
Can use when searching for an **official firmware image** or vendor release elsewhere.

The bootloader identifies the image as:
```text
Signature: a119
Major Rev: 0003
Minor Rev: 0000
File Length: 1781860
Load Address: 80004000
Filename: CM450_1TLAUS_V1.01.03u_160812.bin
HCS: 9780
CRC: 32dca52a
```


The normal bootloader says:
```text
Found image 1 at offset 20000
Found image 2 at offset 400000
```
So the firmware layout is already partly mapped:
```text
0x000000 ┌──────────────────────────────┐
         │ Bootloader                   │
0x020000 ├──────────────────────────────┤
         │ Image 1                      │
         │ 1,781,860 bytes              │
         │                              │
         │ CM450_1TLAUS_V1.01.03u...    │
         │                              │
0x1F2... ├──────────────────────────────┤
         │                              │
         │ unused / other data          │
         │                              │
0x400000 ├──────────────────────────────┤
         │ Image 2                      │
         │ 1,781,860 bytes              │
         │                              │
         │ CM450_1TLAUS_V1.01.03u...    │
         │                              │
0x800000 └──────────────────────────────┘
```

The exact boundaries need calculating from the actual flash contents, but we already know the image start addresses.

## Firmware analysis:
- https://ia600103.us.archive.org/view_archive.php?archive=/33/items/netgearfirmwaresgpl/CM450_1TLAUS_V1.01.03_160812.zip
However... The source archive itself is explicitly identified as CM450 source, so don't assume that the source is identical to your particular binary yet.

Want to look through the downloaded firmware for matching version strings, filenames, copyright strings, etc., with the known firmware version on the device.

``` bash
# grab firmware based on google search for CM450_1TLAUS_V1.01.03_160812

wget 'https://archive.org/download/netgearfirmwaresgpl/CM450_1TLAUS_V1.01.03_160812.zip'


```

- https://ecos.wtf/2021/03/12/ecos-firmware-analysis-with-ghidra

### Where to from here - need CH341A to dump firmware first
---


Ah, yes — and the log you just uploaded gives us **a very good roadmap for getting the firmware**. In fact, this is much more useful than I initially realised.

This isn't a Linux-based bootloader followed by Linux. It's a **Broadcom BCM3383 eCos cable-modem platform**, and the UART you're calling **BBS** appears to be the early Broadcom/eCos diagnostic console.

A few things in your capture are particularly valuable:

- Chip: **BCM3383ZD-B0**
    
- SPI flash: **JEDEC `0xc22017`, 8 MB, 64 KB blocks**
    
- Bootloader identifies two firmware images.
    
- Image 1 is at **`0x20000`**.
    
- Image 2 is at **`0x400000`**.
    
- Each image is **1,781,860 bytes** compressed.
    
- The bootloader explicitly says it detected **LZMA** and decompresses the image.
    
- The running image is **eCos**, not Linux.
    

So we can approach this in several ways.

## 1. The easiest target: dump the 8 MB SPI flash

The log literally tells us:

```text
SPI flash ID 0xc22017
size 8MB
block size 64KB
```

So the entire firmware/storage contents should only be:

```text
8,388,608 bytes
```

That's tiny.

If you can get your CH341A working again, an external dump would be my **preferred method** because it gives us everything:

```text
0x000000 ────────────────┐
                         │ bootloader
0x020000 ────────────────┤
                         │ Image 1
                         │
0x400000 ────────────────┤ Image 2
                         │
                         │ nonvolatile/config/etc.
0x800000 ────────────────┘
```

And importantly, **don't erase or write anything**. We only want:

```bash
flashrom -p ch341a_spi -r modem_spi.bin
```

Once you have the raw 8 MB, we can carve the two images ourselves.

---

# 2. But the BBS UART may let us do it without the programmer

This is actually the avenue I'd investigate next.

Your log shows the bootloader has a fairly sophisticated storage abstraction:

```text
Loading BootloaderStore driver...
Loading ProgramStore driver...
Loading NonVol driver...
```

and then:

```text
ProgramStoreDeviceDriver::ProgramStoreDriverInit
```

That means the eCos environment has code capable of accessing the SPI flash.

The really interesting line is:

```text
Enter '1', '2', or 'p' within 2 seconds or take default...
```

followed by:

```text
Performing CRC on Image 2...
Detected LZMA compressed image... decompressing...
Executing Image 2...
```

That means **there is definitely an interactive bootloader input path**.

The fact that pressing a key gets you:

```text
Username:
Password:
```

makes it even more interesting.

There may be a hidden/service bootloader console.

---

# 3. The `s` key is especially interesting

Your captured firmware log says:

```text
If you pressed the 's' key before this point, we will skip driver initialization...
```

That's an enormous clue.

So I'd definitely test this deliberately.

At power-on:

```text
picocom -b 115200 ...
```

then press:

```text
s
```

**very early in boot**.

Don't send a whole bunch of characters — just `s`.

The firmware itself tells us that `s` has special significance during startup.

It may give you a reduced diagnostic environment before all the modem drivers initialise.

---

# 4. The "Password" you saw may be a different thing than we thought

Looking at this complete log changes my interpretation of your earlier capture.

The firmware starts an enormous amount of eCos infrastructure:

```text
/dev/BrcmTelnetIoDriver
/dev/ttydiag
/dev/tty0
/dev/haldiag
/dev/ser0
/dev/ser1
/dev/ser2
```

And later starts:

```text
Telnet server thread running...
```

So the `Username:` / `Password:` prompt could be coming from a **Broadcom diagnostic/service console**, rather than being the normal modem's Linux login.

That would explain why you can interrupt startup and suddenly get:

```text
Username:
Password:
```

while the rest of the diagnostic threads continue spewing output.

---

# 5. There is also a potentially easier extraction route

The bootloader knows the image locations:

```text
Image 1 → 0x20000
Image 2 → 0x400000
```

and knows their lengths:

```text
1,781,860 bytes
```

So if we can get **any sort of bootloader memory/flash read command**, we don't need to understand the entire flash layout.

For example, conceptually we'd want something equivalent to:

```text
read SPI 0x20000 1781860
```

and:

```text
read SPI 0x400000 1781860
```

But **don't try random commands yet**. We first need to identify what console you're actually entering.

---

## 6. I'd do this next

Since you're trying to acquire firmware rather than modify the device, I'd work completely read-only.

### Step A — capture the earliest boot

Start:

```bash
picocom -b 115200 /dev/cu.usbserial-XXXX
```

Power cycle the modem and capture everything.

### Step B — test `s`

On the next boot, press:

```text
s
```

as early as possible.

Save the resulting output separately.

### Step C — test the bootloader selection

You already have:

```text
Enter '1', '2', or 'p' within 2 seconds or take default...
```

Try **`1`**, rather than `2`, on one boot.

Don't experiment with `p` yet.

We know:

```text
1 → Image 1
2 → Image 2
```

at least according to the bootloader's prompt.

### Step D — document the login prompt

When you get:

```text
Username:
Password:
```

don't try random credentials yet.

Instead, send one character at a time and record exactly what happens.

For example:

```text
a
```

then Enter.

We're interested in whether it responds with:

```text
Username:a
```

or:

```text
Username:
```

or something else.

That tells us whether the login is echoing input and potentially what console implementation we're dealing with.

---

# 7. And the physical flash is very promising

Your flash ID:

```text
C2 20 17
```

is a **Macronix/MXIC SPI NOR device**, and the bootloader reports 8 MB.

That is an unusually manageable target.

So if you can repair/reconnect the programmer, the goal should simply be:

```text
8 MB raw SPI dump
```

rather than trying to somehow download a huge modem filesystem through UART.

And because the bootloader itself gives us:

```text
0x20000
0x400000
```

we already know exactly where to start carving.

Once you have `modem.bin`, we can do something like:

```bash
dd if=modem.bin of=image1.lzma bs=1 skip=$((0x20000)) count=1781860
dd if=modem.bin of=image2.lzma bs=1 skip=$((0x400000)) count=1781860
```

and then inspect the LZMA/eCos images.

**One correction to my previous answer:** I was treating your BBS output as though it were likely a conventional Linux/bootloader console. This log establishes that it is much more specifically a **Broadcom BCM3383 eCos/BFC environment**, with its own serial devices, Telnet diagnostic infrastructure, program store and nonvolatile storage.

That makes the **`s` early-boot path and the `1/2/p` bootloader prompt** the two things I'd investigate before doing anything destructive.




# ALSO - after pressing p


**YES — that's the breakthrough.** 😄

You've found the **Broadcom bootloader's full maintenance menu**. And, importantly, it gives us a **read-only path to dump the flash without needing the CH341A**.

Your sequence:

```text
Enter '1', '2', or 'p' within 2 seconds or take default...

...
# Main Menu:

b) Boot from flash
g) Download and run from RAM
d) Download and save to flash
e) Erase flash sector
m) Set mode
s) Store bootloader parameters to flash
i) Re-init ethernet
r) Read memory
w) Write memory
j) Jump to arbitrary address
X) Erase all of flash except the bootloader
z) Reset
```

is essentially giving you a bootloader-level memory interface.

### The one we want is:

```text
r) Read memory
```

**Do not use:**

```text
d  Download and save to flash
e  Erase flash sector
s  Store bootloader parameters
w  Write memory
j  Jump to arbitrary address
X  Erase all of flash
```

Those can modify the device.

---

## The really good news

The bootloader has already told us:

```text
SPI flash ID     0xc22017
Flash size      8 MB
```

and:

```text
Image 1 → 0x20000
Image 2 → 0x400000
```

So we have a very good chance of extracting the firmware **entirely through this console**.

The menu's:

```text
r) Read memory
```

is exactly what I'd investigate.

### But don't enter an address yet

First, press:

```text
r
```

and **show me exactly what it asks for**.

It may say something like:

```text
Address:
Length:
```

or:

```text
Read address:
Read length:
```

or perhaps offer a destination/output mechanism.

**Don't enter anything destructive.** Just `r` and paste the resulting prompt here.

---

## Also: the `p` menu explains your weird UART output

This part:

```text
Board IP Address  [0.0.0.0]:
Board IP Mask     [255.255.255.0]:
Board IP Gateway  [0.0.0.0]:
Board MAC Address [00:10:18:ff:ff:ff]:
```

explains why your earlier characters were appearing all over the boot output.

You entered `p`, and the bootloader immediately switched into its **network configuration/setup mode**.

Then:

```text
Internal/External phy? (e/i/a)[a] e
Using GMAC0, phy 0

Enet link up: 1G full
```

is particularly useful.

You've got **Ethernet connectivity from the bootloader itself**.

That potentially gives us an even better firmware-extraction route than UART.

---

# We may be able to dump the whole 8 MB over Ethernet

The menu explicitly contains:

```text
g) Download and run from RAM
d) Download and save to flash
```

and the bootloader has:

```text
Board IP Address
Board IP Mask
Board IP Gateway
Board MAC Address
```

plus:

```text
Enet link up: 1G full
```

So this bootloader almost certainly has some sort of network download functionality.

The key distinction is:

```text
g = download → RAM → execute
d = download → flash
```

We **do not want either of those right now**.

But `r) Read memory` may allow us to get memory contents out, and there may be a TFTP-oriented mechanism behind the download functions.

---

## There's another huge clue in your original log

The normal bootloader says:

```text
Found image 1 at offset 20000
```

and:

```text
Found image 2 at offset 400000
```

So the firmware layout is already partly mapped:

```text
0x000000 ┌──────────────────────────────┐
         │ Bootloader                   │
0x020000 ├──────────────────────────────┤
         │ Image 1                      │
         │ 1,781,860 bytes              │
         │                              │
         │ CM450_1TLAUS_V1.01.03u...    │
         │                              │
0x1F2... ├──────────────────────────────┤
         │                              │
         │ unused / other data          │
         │                              │
0x400000 ├──────────────────────────────┤
         │ Image 2                      │
         │ 1,781,860 bytes              │
         │                              │
         │ CM450_1TLAUS_V1.01.03u...    │
         │                              │
0x800000 └──────────────────────────────┘
```

The exact boundaries need calculating from the actual flash contents, but we already know the image start addresses.

---

# And we now know the model/firmware name

Your bootloader actually gives us:

```text
CM450_1TLAUS_V1.01.03u_160812.bin
```

That's an excellent identifier for searching for an **official firmware image** or vendor release elsewhere.

The bootloader identifies the image as:

```text
Signature: a119
Major Rev: 0003
Minor Rev: 0000
File Length: 1781860
Load Address: 80004000
Filename: CM450_1TLAUS_V1.01.03u_160812.bin
HCS: 9780
CRC: 32dca52a
```

So before even dumping anything, we can potentially search for that **exact filename**.

---

## Your next move

You're sitting at a **very valuable recovery/maintenance console** right now.

I'd do only this:

```text
r
```

and paste **the exact prompts it gives you**.

Don't select `w`, `e`, `X`, `d`, `s`, or `j`.

If `r` asks for an address and length, we'll work out a **safe read of the SPI flash** from the information you've already obtained. The goal will be to get a complete `8 MB` dump while making **zero writes to the modem**.

---

## Could dump manually with primitive memory read:


Yes — **if that bootloader's `Read memory` command can address the flash mapping**, you can use picocom's logging to capture the output and reconstruct a binary dump. But there's an important distinction:

> You don't want to dump _every address from `0x80000000` upward_ blindly. First determine which virtual address range maps to the flash, then automate the reads and parse the log.

Your current interface is actually a promising primitive for this.

### 1. Picocom can log the raw terminal output

Start picocom with logging, for example:

```bash
picocom -b 115200 --logfile memory_dump.log /dev/ttyUSB0
```

or, depending on your device:

```bash
picocom -b 115200 --logfile memory_dump.log /dev/cu.usbserial-XXXX
```

Everything printed by the bootloader should then be captured in `memory_dump.log`.

You can verify:

```bash
tail -f memory_dump.log
```

### 2. The problem is generating thousands of commands

Manually doing:

```text
Read memory. Hex address: 0x80000000
Read memory. Hex address: 0x80000004
Read memory. Hex address: 0x80000008
...
```

would obviously be painful.

You can automate the **serial input** from another terminal using Python/pyserial, while picocom logs the output.

For example, conceptually:

```text
address → bootloader
             ↓
       "Value at XXXXXXXX: YYYYYYYY"
             ↓
          logfile
             ↓
       parser extracts
       address + uint32
             ↓
          dump.bin
```

The important part is that we'd send addresses in **4-byte increments**, because you've established that unaligned addresses crash it.

### 3. We need to find the flash mapping first

This is the part I'd do before attempting a huge dump.

Your MIPS system may have flash mapped somewhere such as a KSEG1 address, commonly in the general:

```text
0xA0000000
```

range, but **don't assume that**. The actual mapping depends on the SoC/bootloader.

You already have a useful clue from the bootloader:

```text
0x80000000 → 08fe08c7
0x80000004 → 00000000
0x80000008 → 409af800
0x8000000c → 3c1a83f9
0x80000014 → af400000
```

We should identify what those regions actually are before dumping gigabytes of address space.

### 4. We can also use your existing bootloader code to figure it out

This is probably the **best next step**.

You have:

```text
EPC = 0x83f84350
RA  = 0x83f84324
```

Try reading aligned addresses around the fault:

```text
0x83f84320
0x83f84324
0x83f84328
0x83f8432c
0x83f84330
0x83f84334
0x83f84338
0x83f8433c
0x83f84340
0x83f84344
0x83f84348
0x83f8434c
0x83f84350
0x83f84354
0x83f84358
0x83f8435c
0x83f84360
```

Paste those results.

We can decode the MIPS instructions and determine exactly what the read routine is doing. In particular, I'd like to establish whether it's something like:

```asm
lw   v0, 0(a1)
```

and what `a1` is being used for.

---

### Once we identify flash, yes, we can reconstruct it

Suppose we discover that, for example:

```text
0xA0000000 → flash offset 0
```

and the flash is 64 MiB.

We could have a script send:

```text
0xA0000000
0xA0000004
0xA0000008
...
0xA3FFFFFC
```

and parse:

```text
Value at A0000000: 12345678
Value at A0000004: 9ABCDEF0
...
```

into a binary file.

There is one **endianness issue** we'll need to handle carefully. If the bootloader prints the result of a MIPS `lw` as:

```text
12345678
```

that doesn't necessarily mean the four bytes in the reconstructed flash file should simply be:

```text
12 34 56 78
```

We need to establish the CPU/flash byte ordering from a known structure (e.g. a SquashFS magic, uImage header, ELF header, etc.).

Given the firmware you've previously been working with, this is particularly useful: once we have a candidate dump, we can run:

```bash
file dump.bin
binwalk dump.bin
```

and look for the known firmware structures.

**So yes: picocom logging + automated serial reads + a parser can absolutely turn this into a firmware dump.** But I'd first dump the instructions around `0x83f84350`; that gives us a much safer and more reliable understanding of the read primitive before we point an automated script at a flash-sized address range.




----

## Encrypted flash dump:

A few things clarify what's going on here.

**The `-c` chip selection isn't your problem.** Those six "matches" (MX25L6405, 6405D, 6406E/6408E, 6436E/6445E/6465E, 6473E, 6473F) are all JEDEC-ID-identical or near-identical 8MB Macronix parts that share the same read/erase/write opcodes. flashrom just can't tell them apart from the ID bytes alone, but for a plain read operation they're functionally the same chip — that's exactly why you got byte-identical dumps no matter which one you picked. Your real chip, the MX25L6433F, isn't in flashrom's chip database at all, but it's electrically compatible with this family, so reading via `MX25L6473F` is fine and your dump is very likely accurate.

**The real story is in the data, and it lines up with the hardware.** I looked up your board — this is a Netgear CM450-1TLAUS (Telstra-branded DOCSIS cable modem), built around a **Broadcom BCM3383** SoC, with exactly a Macronix 25L6433F SPI flash. That header you found at 0x400000 (`a119 0005...` followed by the filename string `CM450_1TLAUS_V1.01.03u_160812.bin`) is a variant of Broadcom's cable-modem firmware header format (similar in spirit to the `bcm_hcs` struct used on Broadcom's BCM33xx/63xx cable modem SoCs — magic/control/revision fields, build date, file length, load address, then an embedded filename). What that tells you: the entire firmware _update package_ — the same file Netgear would push as an OTA image — appears to have been written directly into flash as one blob, starting at 0x400000, with the bottom 4MB of the chip genuinely unprogrammed (all 0xFF). That's plausible and not a read error: cost-reduced modems like this sometimes reserve the lower half for a second/failsafe image bank that's simply never been used.

**Why binwalk finds nothing after the header:** DOCSIS cable modems are required by CableLabs' code-verification rules to ship cryptographically signed (often encrypted) firmware images, specifically to prevent exactly what you're trying to do. The bytes immediately following the header in your hexdump are high-entropy noise, not compressed data with recognizable structure — that's consistent with AES-encrypted payload, not a filesystem or a standard compressor. You can confirm this quantitatively:

```
binwalk -E mx25l6433f.bin
```

If the entropy plot is flat and pinned near 8.0 bits/byte across that whole region, it's encrypted (compression usually shows some texture/variation; encryption doesn't).

**What will actually get you further than blind flash reading:**

1. **The onboard UART headers.** The teardown of this exact board (insideGadgets) found two labeled 4-pin headers: `UART0 (BBS)` and `UART1 (LINUX)`. That second one is huge — if you can get a serial console (115200 8N1 is the usual Broadcom default) onto the _running_ Linux side, the filesystem is necessarily decrypted in that context (Linux is mounting/executing it), so you can just `cat /dev/mtd0` or similar straight off the live system instead of fighting an encrypted flash image. On related BCM3383 devices, the bootloader console has also been documented as unlocked with memory read/dump and jump-to-address commands — worth checking `UART0` too.
    
2. **bcm2-utils** (github.com/jclehner/bcm2-utils) — purpose-built for exactly this family of Broadcom cable-modem SoC. `bcm2dump` can pull flash/RAM over serial or telnet once you have console access, and its README also points to Broadcom's own GPLv3 **ProgramStore** tool (github.com/Broadcom/aeolus/tree/master/ProgramStore), which actually understands this header format natively — far better than asking binwalk to guess at it.
    
3. **GPL source is public.** Netgear published the GPL source drop for this exact firmware version (`CM450_1TLAUS_V1.01.03_160812.zip`), mirrored on archive.org's `netgearfirmwaresgpl` collection. It won't contain the signing/encryption keys, but it will show you the real partition layout, kernel config, and rootfs contents your device is running — which may be enough for what you actually want (inspecting the rootfs) without needing to break the encrypted flash image at all.
    

Given all that, I'd try the GPL source first (it may just hand you the rootfs directly), and treat the UART1 Linux console as your real extraction path if you need the live, decrypted-in-place filesystem — rather than continuing to fight the raw SPI dump, which is working correctly but is very likely intentionally encrypted at rest.



- `0x400000 – 0x40005B`: Broadcom-style image header (magic, control/rev fields, the embedded filename string you saw, a checksum field)
- `0x40005C – 0x400060`: 5-byte LZMA header (`props` + `dict_size`)
- `0x400061` onward: the raw LZMA compressed stream (length = 1,781,860 bytes per your bootloader log)

---

# IS AN ECOS DEVICE - no "rootfs" to explore

eCos doesn't have a "rootfs" in the Linux sense. It's a monolithic RTOS image: application code, the DOCSIS stack, and config data all statically linked into one blob, not a mounted squashfs/jffs2 filesystem. So once you decompress `image2_decompressed.bin`, don't expect binwalk to find a filesystem to unpack — there isn't one to find. What you'll actually get is more like a flat executable/data image worth exploring with `strings`, `file`, and a disassembler (Ghidra handles MIPS eCos images reasonably well) if you want to dig into the DOCSIS/config internals, rather than something `unsquashfs` or similar would ever unpack.


Can extract each half & inspect like so:

``` bash
# carve the raw LZMA stream (0x400061 = decimal 4194401)
dd if=mx25l6433f.bin of=image2.lzma_stream bs=1 skip=4194401 count=1781860

# rebuild a legacy .lzma file: 5-byte header + 8-byte "size unknown" marker + payload
python3 -c "
hdr = open('mx25l6433f.bin','rb').read()[0x40005C:0x400061]
payload = open('image2.lzma_stream','rb').read()
open('image2.lzma','wb').write(hdr + b'\xff'*8 + payload)
"

# decompress (xz-utils understands legacy .lzma / FORMAT_ALONE)
xz --format=lzma -dc image2.lzma > image2_decompressed.bin
```

Gives:

![](Screenshot%202026-09-14%20at%208.55.31%20pm.png)


Can't explore filesystem per se, would need to decompile with ghidra first (or just using `strings`, `file` for secrets)

## https://ecos.wtf/
- https://ecos.wtf/2021/03/09/bcm2-utils-bootloader-dumping
- [Full breakdown & extraction](https://www.scribd.com/document/910794188/Qkaiser-Brucon-Ecos)
- https://www.thyrasec.com/blog/firmware-reversing-and-analysis-tools/
- https://www.thyrasec.com/blog/extracting-firmware-from-eeprom-flash-and-emmc/
- https://github.com/ecos-wtf/recos