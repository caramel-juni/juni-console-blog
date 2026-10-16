---
title: "baby's first decrypted firmware analysis: stack(smashing) open the w2250a v2.2"
date: 2026-10-16
description: "we used ghidra, whoopee! is it our time for the NSA or what...?! /s"
toc: true
math: true
draft: false
categories: reverse-engineering
tags: 
- ghidra
- linux
- binwalk
- firmware
- decrypting
- hacking
---
<img src="https://juniblog.goatcounter.com/count?p=/decrypting-w2250a-firmware/" style="display: none">

Welcome to my first little foray into reverse engineering an AES ECB-128 decryption key found within an earlier version (v1.1) of the desired firmware (v2.2) for the W2250A serial-to-wifi device server. This was ascertained by analysing the entropy of both the versions, which (upon comparison) shows that v2.2. is likely encrypted (high level of entropy) whereas v1.1 contains a readable/extractable filesystem that we can analyse.
<div style="text-align: center; margin-bottom: 1em">
<img src="https://web.archive.org/web/20090901175224im_/http://geocities.com/kirbo90/graficos/pika01.gif" style="width: 25%">
<img src="https://web.archive.org/web/20090901175224im_/http://geocities.com/kirbo90/graficos/a_mail2.gif" style="width: 15%">
<figcaption><i>(let's see where this bouncing ball takes us...)</i></figcaption></div>

---
## Disclaimer:
*Before we go on - please note that this is my first (ever) attempt at reverse engineering, and as such, I am following the helpful [stacksmashing's tutorial here](https://www.youtube.com/watch?v=4urMITJKQQs). Please go and show them some love!*

*This will also be a very disorganised disassembly of both a problem and the binary, but hey - I'm focusing on just playing around, learning, and doing as much hands-on stuff as I can, as opposed to pretty writeups!*

---
# Cracking the bad boy (w2250a) firmware v2.2. open 
*...using `v1.1` 🤭*

## New Firmware Version [v2.2](https://www.moxa.com/Moxa/media/PDIM/S100000210/moxa-nport-w2150a-w2250a-series-firmware-v2.2.rom) (encrypted):
Checking entropy with `binwalk -e`:
![](/posts/43/attachments/moxa-nport-w2150a-w2250a-series-firmware-v2.2.rom.png)
Yah. Abnormally high entropy usually means *preeeeetty* encrypted.

## Older firmware version ([v1.1](https://www.moxa.com/Moxa/media/PDIM/S100000210/moxa-nport-w2150a-w2250a-series-firmware-v1.11.rom)) (not encrypted):
Checking entropy with `binwalk -e`:
![](/posts/43/attachments//moxa-nport-w2150a-w2250a-series-firmware-v1.11.rom.png)
Interestingly, the release notes reveal **this is needed to decrypt subsequent firmware versions... so it likely contains some implementation of the encryption key!**

Extracting & analysing the old firmware (v1.1.) with `binwalk -e` reveals several file systems:
![](/posts/43/attachments/Screenshot%202026-10-16%20at%208.49.43%20pm.png)
However, need to extract the filesystem manually via the offsets with `dd` as binwalk's `squashfs` extractor is broken on my mac:

``` bash
FW='moxa-nport-w2150a-w2250a-series-firmware-v1.11.rom'

# Using image beginning at decimal offset 1944048, with "image size: 5365377 bytes"
dd if="$FW" of='squashfs1.bin' bs=1 skip="1944048" count="5365377" status=progress

# Using image beginning at decimal offset 7309844, with "image size: 1537896 bytes"
dd if="$FW" of='squashfs2.bin' bs=1 skip="7309844" count="1537896" status=progress

# Extract each into own directory:
unsquashfs -d rootfs1 squashfs1.bin
unsquashfs -d rootfs2 squashfs2.bin

# Fix permissions:
chmod -R +x rootfs2/*
```

![](/posts/43/attachments/Screenshot%202026-10-16%20at%208.56.29%20pm.png)

The video directs our attention to an upgrade library `libupgradefirmware.so`. Given the release notes for` v1.1` mentioned **this `v1.1` binary was needed to decrypt & run `v2.2`**, *presumably* this `libupgradeFirmware.so` is invoked in the firmware upgrade process & **contains some form of clue to the encryption key/process!**
![](/posts/43/attachments/Screenshot%202026-10-16%20at%209.05.34%20pm.png)

So lets open it within a new Ghidra project:

![](/posts/43/attachments/Screenshot%202026-10-16%20at%209.10.46%20pm.png)![](/posts/43/attachments/Screenshot%202026-10-16%20at%209.11.51%20pm.png)
Clicking on the `.so` file in the project opens it, then `Yes` to analyse (checking `Decompiler Parameter ID` afterwards at the prompt, to help improve analytical progress).
![](/posts/43/attachments/Screenshot%202026-10-17%20at%2012.22.06%20am.png)
([src](https://www.youtube.com/watch?v=qCEZC3cPc1s))

After analysis, heading to the **Functions** in the symbol tree reveals some intriguing ones, such as `AES_set_decrypt_key`, and `fw_decrypt`. Can see it's using an ECB-128 ([Electronic Code Book](https://www.geeksforgeeks.org/computer-networks/electronic-code-book-ecb-in-cryptography/)) encryption method, which is one of the simplest AES block ciphers. [No bueno!!](https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Electronic_Codebook_(ECB)) [](/posts/43/attachments/Screenshot%202026-10-16%20at%209.16.23%20pm.png)

We can check which functions are called by `fw_decrypt` with the `Window --> Function call graph`. So:
- `fw_decrypt` --> `ecb128Decrypt` --> `AES_set_decrypt_key` (potentially where we can RE the key!)![](/posts/43/attachments/Screenshot%202026-10-16%20at%209.23.56%20pm.png)

A handy hint before we do so, to click & highlight all examples of a given variable: `File --> Options --> Cursor Text Highlight`
![](/posts/43/attachments/955.png)

Ghidra already guessed at some of these values, so we can fill them in ourselves too:
- position `0` --> userKey
- position `1`--> `0x80`=`128` (bit key)
- position `2` --> `AES_KEY`
![](/posts/43/attachments/Screenshot%202026-10-16%20at%209.27.11%20pm.png)![](/posts/43/attachments/Screenshot%202026-10-16%20at%209.28.35%20pm.png)

After renaming them, we can glean the following information:
- function initially copies 16 bytes from `param_4` to the `user_key`
- `in` & `out` are passed as input & output into the `AES_ecb_encrypt` function
- `in` & `out` are based on offsets into `param_1` and `param_2`, which are `unsigned char pointers`, which we can now define at the top (using `Command + L`, `Retype Variable`) to clean up the code a bit:![](/posts/43/attachments/Screenshot%202026-10-16%20at%2010.01.22%20pm.png)
- For the `for` loop, we can assume `iVar1` is the `i` value to iterate, and also that `param_3` is the size of `param_1` and `param_2`, so the `decrypt_size`.![](/posts/43/attachments/Screenshot%202026-10-16%20at%2010.05.28%20pm.png)
So the function takes an encrypted buffer `decrypt_in`, decrypts the entirety of it (with `decrypt_size`) with the supplied `decrypt_key` into an output buffer (`decrypt_out`):
```c
void ecb128Decrypt(uchar *decrypt_in,uchar *decrypt_out,int decrypt_size,char *decrypt_key)
```

### Full labelled function `ecb128Decrypt()`:
``` c
void ecb128Decrypt(uchar *decrypt_in,uchar *decrypt_out,int decrypt_size,char *decrypt_key)

{
  int i;
  uchar *out;
  uchar *in;
  AES_KEY aes_key;
  uchar userKey [20];
  
  strncpy((char *)userKey,decrypt_key,16);
  AES_set_decrypt_key(userKey,128,&aes_key);
  in = decrypt_in + 40;
  out = decrypt_out + 40;
  for (i = 0; i < decrypt_size + -40; i = i + 16) {
    AES_ecb_encrypt(in,out,&aes_key,0);
    in = in + 16;
    out = out + 16;
  }
  memcpy(decrypt_out,decrypt_in,40);
  decrypt_out[14] = '\0';
  return;
}
```

## `fw_decrypt`:
Looking into this function, we can name some variables in use as discerned from the previous function:

- `decrypt_size = *param_2;` --> `fw_buf_size`
- `uVar1 = 0xffffffff` --> can **change this variable type to signed integer** (as hovering over it produces `-1` in decimal, so this substitution and assumption makes sense), naming it `return_value`. This also **changes the function signature to signed integers**, which clears up the code quite a bit and reveals `return_value` is set to `-1` in this first `if` statement:![](/posts/43/attachments/Screenshot%202026-10-16%20at%2010.20.39%20pm.png)

### `passwd.3309`
The `passwd.3309` variable (which is given into ECB128 as the `decypt_key`) seems to be particularly interesting. Some XORs are being performed on it, which is a strong sign of **some form of basic obfuscation being performed by the program**. We can take the raw bytes this is performed on and reimplement the XOR logic using python to see what's happening, and hopefully decrypt the key (or whatever `passwd.3309` is) by mirroring the described operations on the original byte data: 
  ![](/posts/43/attachments/Screenshot%202026-10-16%20at%2010.27.21%20pm.png)

Double click on `&passwd.3309` and open the `Bytes` window to jump to its address & copy the raw bytes stored there.
![](/posts/43/attachments/93062.png)

After putting these bytes into a python array (ensuring the bytes are formatted as a hex array by prepending `0x`), we can reimplement the XOR logic with a loop and the hex values used in the original code:
![](/posts/43/attachments/Screenshot%202026-10-16%20at%2010.46.49%20pm.png)Then, we can try and print the resulting characters in `passwd` and see whether we get printable characters... and we do: `2887Conn7564`!

Printing it as hex, we get what could be the **firmware hexadecimal decryption key**:
![](/posts/43/attachments/57076.png)
- `hex(c)` converts the integer to a hexadecimal string, including the `0x` prefix.
- `[2:]` slices the string from index 2 onward, removing the `0x` prefix.
- `end=""` prevents `print()` from adding a newline or space after each value.

Now we have the firmware key in hex, `32383837436f6e6e373536340000`, we can decrypt the firmware using OpenSSL (as it contains an ECB128 function OOB).

...**HOWEVER!** Remember in the `ecb128Decrypt` function, where this encryption function is called? This decryption loop was only performed where `i < decrypt_size -40` --> so **performed at an offset of 40**.
![](/posts/43/attachments/91225.png)
This means we need to use `dd` to carve this offset of `40` from the encrypted `v2.2.` firmware file before decrypting it:
![](/posts/43/attachments/6074.png)

We can now decrypt this with: 
```bash
openssl aes-128-ecb -d -K "32383837436f6e6e373536340000" -in firmware_offset.encrypted -out firmware.decrypted
```

NOW when running `binwalk` on this decrypted `v2.2.` firmware (`firmware.decrypted`)... we get some recognisable filesystems! 
![](/posts/43/attachments/5057.png)
These can then be carved out with `dd` and `unsquash`ed to analyse the previously encrypted firmware!
``` bash
# Using image beginning at decimal offset 1944300, with "image size: 5376520 bytes"
dd if=firmware.decrypted of='squashfs1-v2.2.bin' bs=1 skip="1944300" count="5376520" status=progress

# Using image beginning at decimal offset 7322384, with "image size: 1550307 bytes"
dd if=firmware.decrypted of='squashfs2-v2.2.bin' bs=1 skip="7322384" count="1550307" status=progress

# Unsquashing them into filesystems:
unsquashfs -d v2.2/rootfs1 squashfs1-v2.2.bin
unsquashfs -d v2.2/rootfs2 squashfs2-v2.2.bin
```

**We've now decrypted the original v2.2. firmware using the AES key reverse-engineered out of v1.1**, and can begin to analyse it as well! This decryption process is evidenced by the new `v2.2` `binwalk -E` entropy analysis revealing significantly less entropy, & the resulting legible filesystem `tree` following `unsquash`ing the carved binaries!
![](/posts/43/attachments/72813.png)
![](/posts/43/attachments/Screenshot%202026-10-16%20at%2011.13.30%20pm.png)

From here, we could dive into the decrypted firmware for more vulnerabilities, have a cookie or two, and give ourselves a pat on the back for persevering and learning something new :)

<div style="text-align: center; margin-bottom: 1em">
<img src="https://web.archive.org/web/20091021131818im_/http://www.geocities.com/amichimaru/lain1.gif" style="width: 20%">
<img src="https://web.archive.org/web/20091021131818im_/http://www.geocities.com/amichimaru/r497452-71.gif" style="width: 42%">
<img src="https://web.archive.org/web/20090901175224im_/http://geocities.com/kirbo90/graficos/pika07.gif">
<figcaption><i>(me when i learn something new)</i></figcaption></div>
