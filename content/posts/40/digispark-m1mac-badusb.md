---
title: a quacking good time; making a USB rubber ducky with digispark on Apple Silicon
date: 2026-07-16
description: who left that innocuous-looking cyborg ducky there?
toc: true
math: true
draft: false
categories:
  - arduino
  - badusb
  - rubber-ducky
tags:
  - digispark
  - rubber-ducky
  - badusb
  - microcontroller
  - ATtiny85
  - ATTinycore
---

<img src="https://juniblog.goatcounter.com/count?p=/digispark-m1mac-badusb/" style="display: none">

this all started when my friend gave me a surprise care package at 8:11pm on a Thursday evening while i was practicing soldering in their garage, after I'd had an *exceedingly* bad mental health day. 

> ***"here's a lil usb module. you should make it into a rubber ducky"***


<div style="text-align: center; margin-bottom: 1em">
<img src="/posts/40/attachments/13443.jpeg" style="width: 50%" title="Digispark Module">
<figcaption><i>A <a href="https://www.instructables.com/Digispark-DIY-The-smallest-USB-Arduino/">Digispark USB/microcontroller Module</a></i></figcaption>
</div> 

now, i didn't (and still don't) have the power to **turn circuit boards into plastic approximations of adorable semi-aquatic animals** (although that would admittedly be epic), so for those of you confused as to what a "rubber ducky" is, here's a link explaining it. 

In short, a rubber ducky is a small programmable device (typically with a microcontroller) masquerading as a USB drive, intended to be left in communal/office spaces with the hopes of a curious soul discovering it and plugging it into their personal device. It will then automatically run a set of pre-defined keystrokes or commands on their machine, enabling... all sorts of bad things. Or, open a funny video on YouTube. **You decide.**

in any case, I'd never DIY'd one of these for myself before, and had my first play with an Arduino & the IDE two days ago, so it made for a fun evening project (& writeup!) to dive into. Getting some **very old/borderline unsupported libraries & board controller code working** in 2026 on my **M1 ARM-based Mac** was... *fun*, so I've documented the process below :).

<div style="display: flex; justify-content: center; align-items: center; gap: 10px;"> <img src="/posts/40/attachments/ducky%201.gif" style="height: 200px; width: auto;"> <img src="https://c.tenor.com/zjNvxl9Vhp8AAAAd/tenor.gif" style="height: 200px; width: auto;"> </div>

---
# PSA: Don't plug in random USBs/Digispark modules, *even* when you buy them yourself or are gifted them by "trusted friends"!
If you ever **buy** one of these DigiKeyboard modules off Aliexpress/online or obtain one that **you didn't literally build yourself**, I would ***highly recommend***:
- Preparing a **working Arduino IDE setup** on a network-isolated computer you **don't care about**
- Making & compiling a **test/blank project file**, and uploading it
- Waiting until the `Plug in device now` prompt appears after uploading it
- **And only THEN connecting the USB**, to **first erase whatever might be on it with a fresh flash**. 
During the first 5 seconds after insertion, **it is able to be flashed** & will *not* run the code on it (yet) - so use this time period to **wipe whatever nefarious shit might've been on there.**

You might scoff at my paranoia, but I (thankfully) opened up a text file to capture any residual "gifts from the factory" before plugging my module in. It was a stock $3 Digispark module from AliExpress but was *also* given to me by a friend, so due to the latter fact that i trusted them & thus had some implicit trust, by proxy, in the device itself, i plugged it in to start developing...

...And well, after the ~5sec initialisation time, the following keystrokes were run:
![](/posts/40/attachments/Screenshot%202026-07-17%20at%2012.10.09%20am.png)
So... yeah. The rule stands: Don't plug in ANY unknown "USB" interfaces to your computer **without wiping them first**. Even when **you're the *supposedly* tech-literate one *trying* to make a Rubber Ducky to do *just this* in the first place 🦆** ... who knows what's already on there "from the factory".

---
# The process:
### 1. Setting up your Arduino Environment

Download & install the Arduino IDE for your OS. This guide is for an M1 Mac, so I selected the [`Apple Silicon`](https://downloads.arduino.cc/arduino-ide/arduino-ide_2.3.10_macOS_arm64.dmg) image & installed it.

#### Note: *Apple Silicon Quirk*:
*Due to the M1 having to emulate several of the libraries we'll need to use, ensure Rosetta2 is installed as well ([see here](https://forum.arduino.cc/t/24-mac-m1-bad-cpu-type-in-executable/1071674/2)). Open your terminal, and run `softwareupdate --install-rosetta` and accept the agreement.*

Open a new project in Arduino IDE. **Save it first** and give it a name, so that it appears in you Arduino Projects folder (this will be important later when importing a library).

Then, select `Settings --> Additional board manager URLs`, and add the following **board manager URL** (targeting the Digispark's **[ATTinyCore](https://github.com/SpenceKonde/ATTinyCore)**) in Arduino to allow the IDE to interact with the Digispark board:

- `https://raw.githubusercontent.com/SpenceKonde/ReleaseScripts/refs/heads/master/package_drazzy.com_index.json` 

This is a (slightly... 2021 vs 2015) more up to date/maintained version of the Digispark board controller, as the [original one](https://raw.githubusercontent.com/digistump/arduino-boards-index/master/package_digistump_index.json) by Digistump (whose [website is now scrubbed](http://digistump.com/package_digistump_index.json)...) didn't seem to work for me on an M1 mac. Once you've pasted it in, select `OK` twice to save.
![](/posts/40/attachments/10008.png)

Then click on the Arduino IDE's `Board Manager` on the left, and search for & install the `ATTinyCore` package (for me, i used `v1.4.1`, which i arrived at after attempting to install the latest version, it failing, then trying earlier releases until i [got one that installed successfully](https://forum.arduino.cc/t/attiny-by-spencekonde/1434789)). This will install our means of talking to the microcontroller (the [`Attiny85`](https://www.etechnophiles.com/attiny85-pinout-specs-guide/)) on the Digispark board!
![](/posts/40/attachments/17381.png)

Once installed, select your `Board` as `ATTiny85` (or whatever `ATTiny` version corresponds with your physically-labelled chip), ignore the `PORTS`, and select `OK`.
![](/posts/40/attachments/41005.png)

### 2. Installing the Digispark libraries

Now, in order to use the device to emulate the functionality of a keyboard, we need to first **install the Digispark keyboard library**. Digistump *used* to host the `.json` file containing these libraries that you could add in `Settings --> Additional board manager URLs`, but their site now shows a `404`. 

However, an archive version *does* exist, but when adding the archived link (https://raw.githubusercontent.com/digistump/arduino-boards-index/master/package_digistump_index.json) as an `Additional board manager URL`, it **only seemed to add libraries for interacting with `azerty` keyboard layouts**, which wasn't helpful for my `QWERTY` setup...
![](/posts/40/attachments/24605.png)

So, I decided to **manually download + use the [archived Digispark git repo](https://github.com/digistump/DigistumpArduino/archive/refs/heads/master.zip)** - ***[straight from the horse's mouth!](https://en.wikipedia.org/wiki/Brave_New_World)***. 
I found & opened the default Arduino projects/sketchbook folder (`Settings --> Sketchbook location`), **downloaded + unzipped the [archived Digispark git repo](https://github.com/digistump/DigistumpArduino/archive/refs/heads/master.zip)**, and then copied the `libraries` folder into the root of my Arduino projects/sketchbook folder, as shown in the code below:
```bash 
## change to Arduino projects/sketchbook folder
cd /path/to/arduino/sketchbooks/folder

## Download & unzip old DigistumpArduino git repo
curl -L -o DigistumpArduino.zip https://github.com/digistump/DigistumpArduino/archive/refs/heads/master.zip

unzip DigistumpArduino.zip

## Move the /libraries folder into the current Arduino projects directory
mv DigistumpArduino-master/digistump-avr/libraries .
```
The key library we need inside `/libraries` is the `DigisparkKeyboard` one, which will allow programmatic interactions with the Digispark device as if it's a keyboard.
Ensure the `libraries` folder is sitting alongside each of your applicable project folders (e.g. `project1`, `project2` etc. below), so that the libraries inside can be read & imported by the projects. 
*An example folder structure is shown below:*
``` bash
├── libraries
│   ├── ...<SNIP>
│   ├── DigisparkKeyboard
│   └── ...<SNIP>
├── project1
│   └── project1.ino
└── project2
    └── project2.ino
```


### 3. Flashing code to the Digispark BadUSB!
Now, we can return to the project itself! Here's the process for flashing the chip, as it's **quite finnicky** and often takes **multiple tries on multiple USB ports** to get a successful flash over usb-to-serial.
1. Start with the Digispark USB **disconnected.**
2. Copy and paste either of the below code snippets into the Arduino IDE.
3. Make sure your board is set to `ATting85 (Micronucleus / Digispark)`: ![](/posts/40/attachments/14592.png)
4. Click **Upload**.
5. Wait for the "Plug in device now..." message in the console.
6. ***NOW*** plug in your Digispark. I suggest using a USB hub if an adapter is needed (for better voltage regulation on these older boards). You will likely need to **repeat this process with several different USB ports** if it fails, and I found it helped to **angle/press the Digispark USB pins close/flush against the USB reader socket so the contact is good**; this increased my flashing success rate ***dramatically.*** ![](/posts/40/attachments/28635.png)
7. After enough tries and plenty of errors (), you should *hopefully* get the below message that writing is complete! ![](/posts/40/attachments/49258.png)Awww, no—thank *you* for flashing it for me :3

I suggest using a **pre-made project with a visual indicator of success** (e.g. pulsing LED) to check that the flashing process itself works on your chip, before moving onto manipulating keystrokes.
#### Code snippets:
Compile & upload the below code using the above process to get a basic pulsing light working as a POC & to verify the flashing works:
### `2003RaveEnergy.so` ([src](https://envistiamall.com/blogs/learn/digispark-attiny85-development-board-user-guide))
``` c++
/*
 * Digispark Fading LED
 * Smoothly fades the on-board LED on P1
 * using PWM (analogWrite).
 *
 * Demonstrates PWM output capability
 * of the ATtiny85.
 */

int brightness = 0;
int fadeAmount = 5;

void setup() {
  pinMode(1, OUTPUT);  // P1 = on-board LED (PWM capable)
}

void loop() {
  analogWrite(1, brightness);
  brightness = brightness + fadeAmount;
  // Reverse direction at the ends
  if (brightness <= 0 || brightness >= 255) {
    fadeAmount = -fadeAmount;
  }
  delay(30);  // Controls fade speed
}

```

And then, the fun part... using the `DigiKeyboard` library we imported earlier!
The below code (on macOS) runs a series of keyboard strokes to open a very well known youtube video on the person's computer... reflecting on the spirit of this project to **Never** (Gonna) **Give** (You) **Up**.

### `Never(Gonna)Give(You)Up.so`
``` c++
#include "DigiKeyboard.h"

void setup() {
// this all only runs once, as is the nature of setup()

  DigiKeyboard.delay(5000); // let macOS enumerate the HID device

  // opens spotlight
  DigiKeyboard.sendKeyStroke(KEY_SPACE, MOD_GUI_LEFT);
  DigiKeyboard.delay(500);

  // launches terminal
  DigiKeyboard.print("Terminal");
  DigiKeyboard.delay(1000);
  DigiKeyboard.sendKeyStroke(KEY_ENTER);
  DigiKeyboard.delay(5000); // give Terminal time to open and focus

  // uses the `open` command (which respects whatever the default browser is) to open a video, and then plays the video with shortcut key 'K'
  DigiKeyboard.print("open https://youtu.be/dQw4w9WgXcQ");
  DigiKeyboard.delay(1500);
  DigiKeyboard.sendKeyStroke(KEY_ENTER);
  DigiKeyboard.delay(8000);
  DigiKeyboard.sendKeyStroke(KEY_K);
  DigiKeyboard.delay(1000);

}

void loop() {
// Prevent loop() from running again
  while(1) { DigiKeyboard.delay(1000); }
}
```

### 4. Extending your scripting capabilities!
Tweak these commands as you'd like, to run any set of keystrokes on the target device! Some more ideas can be found in the [article here](https://hacktronian.in/post/turning-your-arduino-into-a-rubber-ducky), and you can use a [converter](https://cedarctic.github.io/digiQuack/) to convert the Duckyscript samples to Digispark-compatible code!
- [Digispark USB tutorial & further resources](https://docs.spacehuhn.com/badusb/build-and-setup/digispark/#using-it-as-a-keyboard)
- [Null byte Digispark tutorial](https://null-byte.wonderhowto.com/how-to/run-usb-rubber-ducky-scripts-super-inexpensive-digispark-board-0198484/) (old but still very relevant!)
- 📄👾 [Digispark Keyboard Scripts](https://github.com/CedArctic/DigiSpark-Scripts)
- 📄👾 MORE [Digispark Keyboard Scripts Pt.2](https://github.com/MTK911/Attiny85)
- 📄👾 [Arduino Ducky Scripts](https://github.com/thehackingsage/ducky4arduino/tree/master/Arduino%20Ducky%20Scripts) (requires converting to Digispark language, see below links)
	- [DigiQuack - Duckyscript-to-Digikeyboard Converter](https://cedarctic.github.io/digiQuack/)
	- [duckify](https://duckify.spacehuhn.com/) - a BadUSB script converter tool to Digispark

Even better, once you've played with some of these (noting to **always read the code before running it to understand what you're running on your computer...**), **learning either the DuckyScript &/or Digikeyboard languages** can help you extend the functionality of this little device to your heart's content!

## Mandatory Disclaimer:
*"Be responsible, only test on devices you're authorised to use, don't be a skid,"* all of that jazz. Enjoy learning & tinkering with your new ducky friend! 

Also, the likelihood of conducting *any* successful social engineering attacks with this thing (without 3D printing/getting a case for it) is so low that it makes for a perfectly "safe" test project :3. And on that note, anyone who actually plugs this ***extremely*** suspicious-looking device into their computer is just... well, it's just natural selection at that point >.<

*(ignore the fact i totally didn't do exactly this in order to set this all up, and refer to the opening PSA of the article, okay goodbye-)*

<div style="display: flex; justify-content: center; align-items: center; gap: 10px;"> <img src="/posts/40/attachments/dance%201.gif" style="height: 200px; width: auto;"> <img src="/posts/40/attachments/duckinsane.gif" style="height: 200px; width: auto;"> </div>
