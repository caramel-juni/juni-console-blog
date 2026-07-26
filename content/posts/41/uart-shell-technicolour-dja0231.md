---
title: baby's first UART root shell; the Technicolour DJA0231 (Gen2 Smart Modem)
date: 2026-07-26
description: rooting the Technicolour DJA0231 (Gen2 Smart Modem) the hard(ware hacker) way!
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
---

<img src="https://juniblog.goatcounter.com/count?p=/uart-shell-technicolour-dja0231/" style="display: none">

recently i've been diving into the rather intimidating but endlessly fascinating world of hardware hacking, and after a few aliexpress orders and ~~bad~~ financial decisions, I now have some of the tools required to start to poke around under the physical *and* digital hoods of electronic devices.

and why not start with my **battle-tested, age-old Telstra Gen 2 "Smart Modem"?** the white box that watched over me, my midnight queries, chats, and thoughts flowing through its gates by the thousands, millions over the years, as i grew from an anxious adolescent into... whatever the hell i am now.

so. **time to gut my old guardian and poke around at it's innards** (respectfully & good-naturedly, of course! 😋)

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/41/attachments/pic2.jpg" style="width: 70%" title="Digispark Module">
<figcaption><i>The (somewhat) Before...</i></figcaption></div>


## How to talk to the device: the UART hunt

Determine where the `UART` port is (or JTAG, SPI, I2C etc. but they're less common/as of yet uncharted waters for me) on the PCB. 
This is typically found by looking for 4-5 pins in a vertical/horizontal line. On my modem, this required just a *touch* of disassembly, but after prying it open (and only shearing one bit of plastic off in the process), I could slip out the internal circuit boards & found the pin row fairly easily:

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/41/attachments/pic4.jpg" style="width: 70%" title="Digispark Module">
<figcaption><i>... and The After: freshly-skinned router...</i></figcaption></div>
Some more techniques for determining what different UART ports look like across different device types can be seen [here](https://www.youtube.com/watch?v=s8s3gvZPc0c), and is a good reference. However, **safely powering it on & probing around at boot is typically the most successful method**.

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/41/attachments/pic3.jpg" style="width: 70%" title="Digispark Module">
<figcaption><i>The identified UART pins (outlined in red)</i></figcaption></div>


## Finding the `TX` pin

To interface with/connect to the router's serial interface and all of its juicy debug logs (+ if we're lucky, a potential shell), we need to identify which pins are which (`TX`, `GND` and `RX`) on the router's suspected UART interface.

1. Set a multimeter to the `DC` mode `20V` setting (i.e. it will read up to `20V`, which should encompass the range including the expected `3.3V`ish output of the pins), or your equivalent lowest range above `3.3-5V`. Then, with the meter's black wire/pin grounded (i.e. touching some form of metal), probe each pin on the suspected UART line to read the voltage, directly after powering the device on.
2. The `GND` (Ground) pin should read around **`0V.`**
3. The **`TX`** pin often measures somewhere around **2–3.3V** (for a 3.3V UART) and **may appear to fluctuate slightly** while the device is booting. This is because the multimeter is averaging the rapid voltage transitions caused by serial data transmission. Depending on the meter and the amount of serial activity, the reading may briefly jump around before settling. However, an oscilloscope or logic analyser is required to observe the actual waveform of HIGHs and LOWs representing data being transmitted as the router powers on & generates boot logs over serial, etc. UART communicates data by rapidly switching the signal between two voltage levels (typically **0V** and **3.3V**). These voltage transitions encode binary data (1s and 0s) according to the configured **baud rate** (explained, probably poorly, later)
   **NOTE:** ****THIS IS LIKELY A VASTLY OVERSIMPLIFIED AND BUTCHERED EXPLANATION BUT ITS HOW I UNDERSTAND IT IN MY HEAD AT THIS VERY EARLY STAGE IN MY HW HACKING JOURNEY***
4. [OPTIONAL/AFTERWARDS] Once the `TX` is found, later on in the guide when you're connected and have serial logs coming through on your laptop/a shell, you can find the `RX` pin by probing the remaining unknown pins & spamming your keyboard, to see which one permits data to be received from the connecting computer.

Make sure to label these once found, and even briefly solder the connections onto them — they're important!

## Setting up the serial communications interface

To set up `picocom` (or a similar terminal emulator) to talk with this UART interface, we need to determine the `/dev/` name of our USB-to-UART serial device when it's plugged into our computer of choice. This can be done in numerous ways, but I was doing this on an M1 Mac, so was a little roundabout compared to the typical linux `lsusb` (or running `dmesg -w` and checking the new line that appears when plugged in). These *may* also work on a mac as well, but did not for me, so I followed the [below method](https://stackoverflow.com/questions/48291366/how-to-find-dev-name-of-usb-device-for-serial-reading-on-mac-os):

``` bash
# Plug in USB-to-UART, and export all registered /dev/ devices to a file
ls -lha /dev/tty* > plugged.txt
# Unplug USB, then re-run the export of all registered /dev/ devices
ls -lha /dev/tty* > unplugged.txt
# Diff the two to find the device's mount path, at /dev/
diff plugged.txt unplugged.txt
# should show something like:
# < crw-rw-rw-  1 root      wheel   0x900000c Jul 22 20:47 /dev/tty.usbserial-1230
```

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/41/attachments/Screenshot%202026-07-22%20at%2010.22.41%20pm.png" style="width: 90%" title="Digispark Module">
<figcaption><i></i></figcaption></div>


So, `/dev/tty.usbserial-1230` is the UART-to-USB device's `/dev/` entry, which is required to tell `picocom` from where to expect & read the serial output!

## Getting ready to talk to the device with `picocom`

I installed [`picocom`](https://github.com/npat-efault/picocom) (or a similar terminal emulator, that supports serial device communication) on my M1 mac, to act as our terminal to talk to the device via serial.

``` bash
# install picocom
brew install picocom

# Usage example
picocom -b 115200 /dev/USBDEVICENAME

# Using my discovered plugged in USB-to-UART mount point as an example
picocom -b 115200 /dev/tty.usbserial-1230
```

This will begin listening for an active UART connection, on the mounted USB-to-UART device. May need to try different **baud rates** (`-b`) until you find the one the device uses. 

## Measuring/guessing the baud rate

The **baud rate** is the number of **discrete signal elements** (bits or symbols) transmitted per second ([ref](https://nestingnicely.com/how-to-measure-baud-rate-oscilloscope/)), and must be agreed upon between the computer & the device so that the signals the device sends are interpreted correctly & can be read. 

The baud rate of a device can be measured by hooking up an oscilloscope to the UART `TX` port, and measuring the **time (in `ms`) taken between any two given "pulses"** (**baud periods**). The baud rate is then (`1/TIME-IN-MS`). [A good explanation is here.](https://nestingnicely.com/how-to-measure-baud-rate-oscilloscope/)

*E.g., the time delay between **two** singular pulses in my case was ~18ms, so to get that as a baud rate we need (`1/TIME-IN-MS`), so `1/(17*10^-6)`, then **multiply it by 2** to get the baud rate for a **single pulse**: `117647`.* 
*This is very close to the standard/typical `115200` baud rate, so we can assume the device uses that!*

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/41/attachments/pic1.jpg" style="width: 70%" title="Digispark Module">
<figcaption><i>probing with the oscilloscope to see the binary pulse party !</i></figcaption></div>


## Connecting the wires and seeing sparks fly!

Once you've got the right baud rate (through measuring or just trying common values), ensure `picocom` is running on your laptop & the USB-to-UART is connected, then power the device on and quickly attach:
- The `GND` wire/pin from the USB-to-UART cable (typically black) to ground (any metal surface on board)
- The `RX` wire/pin from the USB-to-UART cable, to the target device's identified `TX` UART pin. If you don't know your USB-to-UART cable's `RX` wire, try different ones  from the connector **until you get an output on your `picocom` screen**, indicating that the transmission/receiving is successful. When that happens, it means that the current wire/pin is the connector's `RX`). 

If all is well, you should start to see boot logs flying past/down the screen! If the output is present but is jumbled/a mess of characters, try first changing the baud rate, and then adjusting the pin/soldering it down to get a better connection.
## And... a cheeky surprise `root` shell?

Luckily enough for this gateway, after a few minutes of booting, we were dropped into a busybox `root` shell (likely indicated by `/ #`, see [here](https://stackoverflow.com/questions/41930997/what-is-the-name-of-the-or-signs-that-indicates-if-youre-root), but uncertain - should verify with any user command like `id`, `echo $USER`, or `whoami` that is installed inside a `/bin/ash` shell).

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/41/attachments/Screenshot%202026-07-22%20at%2011.41.35%20pm.png" style="width: 70%" title="Digispark Module">
<figcaption><i>... and the skinned beast awakens!!!</i></figcaption></div>

<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/41/attachments/Screenshot%202026-07-22%20at%2011.12.37%20pm.png" style="width: 70%" title="Digispark Module">
<figcaption><i>...and after a few minutes, baby's first UART 🐚 :3</i></figcaption></div>


From here, we can browse through the system, analyse it's default security layout, the software it runs, re-capture & analyse the previous bootup logs to see what is being initialised/run at boot, and then even dump the firmware via reading the flash memory chip with something like the CH341A controller, if we can identify where that chip is on the board (likely/hopefully 8-pin IC, look up model names for each chip there & try and determine). 

Going forward, the sky's the limit! *(along with my patience & lead fume tolerance ;)* 

In any case, I'm *very* much still learning, & am sure as hell I will continue to do so as i dive deeper into the [wired... <3](https://lain.fandom.com/wiki/The_Wired).