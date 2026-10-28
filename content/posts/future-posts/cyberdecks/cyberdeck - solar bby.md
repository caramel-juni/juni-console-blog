---
title: ""
date: 2026-07-10
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking

**idea:** e-ink solardeck for writing
5.5in x 4in

- repurpose kindle screen? (second hand kindle more $ unless donated)


![](Screenshot%202026-07-10%20at%2010.57.52%20am.png)
- [e-ink solardeck](https://hackaday.io/project/191818-the-solar-box)

Inspo videos:
- [Solar deck](https://www.youtube.com/watch?v=sVnjyTWPwnc&t=57s)
- [e-ink computer for writing](https://www.youtube.com/watch?v=lm_WU4u6OcY)

- [off grid deck](https://www.youtube.com/watch?v=AwwY2zp_qHE)
![](Screenshot%202026-10-22%20at%2010.29.12%20am.png)


|                   | Deck 1 "SOLARFREAK"          | Deck 2 "OFF GRID"                                  |
| ----------------- | ---------------------------- | -------------------------------------------------- |
| Purpose           | Read + write, days off-grid  | Portable off-grid computing / security lab / radio |
| Brain             | Raspberry Pi Zero 2 W        | N100 mini PC (12 V native)                         |
| Screen            | 7.5" e-paper (B/W)           | 14" portable 1080p LCD                             |
| Battery           | 1S4P 21700 Li-ion, ~72 Wh    | 12 V 100 Ah LiFePO4, 1,280 Wh                      |
| Solar             | 6 V 10 W panel + CN3791 MPPT | 100 W folding panel + 20 A MPPT                    |
| Typical draw      | ~1-1.5 W                     | ~20-35 W                                           |
| Autonomy (no sun) | ~40+ hours                   | ~35-50 hours                                       |
| Est. cost         | A$340-420                    | A$1,050 bare-bones / ~A$1,700 loaded               |




----






# Two Cyberdecks: Build Plans & Guides

_Prepared 22 Oct 2026 for a builder in Adelaide, SA. Prices are AUD_ **_estimates_** _unless marked US$ (US$ figures were found in live listings this week; I use ~US$1 = A$1.5 for rough conversion, plus shipping/GST). Always re-check before buying: 2026 is a volatile year for memory and flash pricing._

## 0. Read this first

**The two builds**

|   |   |   |
|---|---|---|
||Deck 1 "FERN"|Deck 2 "OUTPOST"|
|Purpose|Read + write, days off-grid|Portable off-grid computing / security lab / radio|
|Brain|Raspberry Pi Zero 2 W|N100 mini PC (12 V native)|
|Screen|7.5" e-paper (B/W)|14" portable 1080p LCD|
|Battery|1S4P 21700 Li-ion, ~72 Wh|12 V 100 Ah LiFePO4, 1,280 Wh|
|Solar|6 V 10 W panel + CN3791 MPPT|100 W folding panel + 20 A MPPT|
|Typical draw|~1-1.5 W|~20-35 W|
|Autonomy (no sun)|~40+ hours|~35-50 hours|
|Est. cost|A$340-420|A$1,050 bare-bones / ~A$1,700 loaded|

**The 2026 RAM crunch changes the shopping list.** Raspberry Pi raised prices again on 1 Oct 2026: the Pi 5 2GB is now US$77.50, 4GB US$110, 8GB US$180, 16GB US$305. A Pi 5 is no longer the "cheap" option, which is why Deck 1 uses a Pi Zero 2 W (still about A$30 at Core Electronics, because it uses older memory) and Deck 2 uses an Intel N100 mini PC or a used business mini PC instead of a Pi 5. SSD/NAND and DDR pricing are also inflated, so shop around and consider used.

**Tools you need for both** (about A$120 if you own none): temperature-controlled soldering iron, multimeter, wire strippers, hammer or ratchet crimper for lugs, heat-shrink + heat gun/lighter, flush cutters, small screwdrivers, a hot-glue gun, and a drill/hole saw. Jaycar, Bunnings and Supercheap Auto cover most of this.

**Where to buy (Australia)**: Core Electronics (Pi boards, Waveshare, Adafruit, Pololu, same-day dispatch from Newcastle), Jaycar and Altronics (cables, fuses, connectors, panels), Little Bird, Amazon AU, eBay AU, AliExpress (cheap modules; 2-4 week shipping), Bunnings and Supercheap Auto (cases, wood, cable, fuses, marine hardware). For LiFePO4: LiTime AU and Redodo ship from AU stock or direct; VoltX and similar AU brands exist, check current pricing.

**Safety rules (non-negotiable)**

1. Fuse every positive wire as close to the battery as possible. Lithium batteries can deliver hundreds of amps into a short.
2. Never mix cell brands/capacities, and match cell voltages (within 0.05 V) before paralleling them.
3. Keep all wiring extra-low-voltage DC. Do **not** build 240 V AC wiring into either deck; use certified AC chargers outside the box.
4. Check polarity twice with a multimeter before connecting any battery.
5. Do not charge lithium below 0 C or leave panels connected to unattended, unfused wiring.
6. Batteries over 100 Wh (including the Deck 2 pack) cannot go on a plane. Plan road/courier transport.



![](3196.png)

---


# PART 1: Deck 1 "FERN" (e-ink reader/writer)

## 1.1 Concept
- https://github.com/MostlyFunctionalEngineering/pocket-computer
	- [Video](https://www.youtube.com/watch?v=sdcX1ghOkFM&t=792s)
- https://penkesu.computer/
- [How I made a 60fps Eink Monitor, the Modos Flow](https://www.youtube.com/watch?v=nHbA2-_qzH4)

![](Screenshot%202026-07-10%20at%2010.57.52%20am.png)
![](49816.png)
![](66514.jpeg)
A clamshell or slab-style wooden writing deck with a 7.5" e-paper screen, a real keyboard, and a hinged "leaf" solar panel on the back. It sleeps most of the time (e-paper holds the image with no power), so it can run for days on one charge and top up from window or outdoor sun.

**Retro nature theme**: timber shell (recycled Tasmanian oak/pine offcuts, a cigar box, or a hand-sawn pine box from Bunnings), cork lining, brass corner caps and screws, moss-green keycaps, and a pressed-botanical sleep screen. Use botanical plates converted to 800x480 dithered B/W as screen-saver art. Boot splash: ASCII fern.

## 1.2 Hardware

|        |                                                                                                                                                  |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |                         |                                                                          |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ------------------------------------------------------------------------ |
| #      | Part                                                                                                                                             | Pick                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Est. price              | Where                                                                    |
| 1      | Computer                                                                                                                                         | [Raspberry Pi Zero 2 W](https://core-electronics.com.au/raspberry-pi-zero-2-w-wireless-soldered-male-headers.html) (pre-soldered header)<br><br>**I have:** <br>- Raspberry Pi Zero (1)<br>- Raspberry Pi Zero 2 (Caitlyn, need to buy off)<br>- Raspberry Pi 4 4GB/8GB (Caitlyn, need to buy off)                                                                                                                                                                                                                                                                                                                                                             | A$34                    | [Core Electronics](https://core-electronics.com.au/added/?product=56397) |
| 2      | e-Ink Display<br><br>OR<br><br>Small one AND a LCD display for terminal commands... see [here](https://hackaday.io/project/191818-the-solar-box) | [Waveshare 7.5" e-Paper HAT, **black/white V2, 800x480** ](https://www.waveshare.com/7.5inch-e-Paper-HAT.htm)(US$98AUD w shipping direct from Waveshare)<br><br>[7.5inch E-Ink Display HAT 800x480 Resolution SPI interface Compatible with Raspberry Pi 3B/3B+/Zero](https://www.aliexpress.com/item/1005005121813674.html?) - $48<br><br>[6inch eink kindle screen](https://www.aliexpress.com/item/32223475924.html) $22<br><br>[9inch screen](https://www.aliexpress.com/item/1005009467511725.html) $37<br><br>or:<br>$400 BOOX Go Tablet, [hacked](https://gist.github.com/carlosonunez/a0ec3f02576867329bc313bae889563d), higher refresh rate & powered | A$50-110 incl. shipping | Waveshare, Core Electronics, Amazon AU, Aliexpress                       |
| 3      | Storage                                                                                                                                          | [128/256 GB A1/A2 microSD](https://www.amazon.com.au/micro-sd-card-a2/s?k=micro+sd+card+a2) $60-90                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | A$60-90                 | Amazon, Officeworks                                                      |
| 4      | Keyboard                                                                                                                                         | [Compact wired USB 65% with wooden keycaps](https://www.aliexpress.com/item/1005007389046368.html) - $42                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | A$40-70<br>             | AliExpress                                                               |
| ~~5~~  | ~~USB OTG~~                                                                                                                                      | ~~Micro-USB OTG cable (or the Pi Zero 3-in-1 essentials kit, A$3.50)~~                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | ~~A$4-8~~               | ~~Core~~                                                                 |
| 6      | Solar panel                                                                                                                                      | [30W High Efficiency Panel 5V Plate With USB Safe Stabilize Charger For Power Bank Phone Outdoor Camping Home RV Gift Travel Boat](https://www.aliexpress.com/item/1005013152157269.html)<br>- $10                                                                                                                                                                                                                                                                                                                                                                                                                                                             | A$20-35                 | Jaycar, Altronics, eBay, AliExpress                                      |
| ~~7~~  | ~~Solar charger~~                                                                                                                                | ~~[CN3791 MPPT 1S Li-ion module, 6 V version](https://www.aliexpress.com/item/1005004139590336.html?) - $4                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | ~~A$4~~                 | ~~eBay, AliExpress~~                                                     |
| 8      | Cells                                                                                                                                            | [4x genuine 21700 5000](https://www.dicksmith.com.au/da/buy/office-catch-4-pack-50e-21700-5000mah-15a-rechargeable-battery-high-capacity-power-cell-for-tools-e-bikes-flashlights-10214950502721/) mAh (e.g., Samsung 50E class, or Molicel/LG equivalents) - $45                                                                                                                                                                                                                                                                                                                                                                                              | A$45                    | Reputable AU cell retailer (avoid unbranded "9900 mAh" cells)            |
| 9      | Cell holder                                                                                                                                      | [4-slot 21700 holder](https://www.aliexpress.com/item/1005005491570611.html?) (parallel) - $2 OR [21700 18650 Battery Case Holder 4 Slots 3.7V 14.8 Volt DIY Battery Storage Box in Parallel](https://www.aliexpress.com/item/1005005418296167.html) - $5                                                                                                                                                                                                                                                                                                                                                                                                      | A$2-5                   | Aliexpress                                                               |
| 10     | Protection                                                                                                                                       | [1S 3.7 V protection board (PCM/BMS), 5-10 A](https://www.aliexpress.com/item/1005007629849009.html?) - $3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | A$3                     | eBay, AliExpress                                                         |
| 11     | 5 V boost                                                                                                                                        | [Adafruit PowerBoost 1000 Basic](https://core-electronics.com.au/powerboost-1000-basic-5v-usb-boost-at-1000ma-from-1-8v.html) (has low-battery output) - $29                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | A$29                    | Core Electronics                                                         |
| 12     | Fuse                                                                                                                                             | 5A fuse - [5PCS Glass Fuse Holder 5*20mm 6*30mm Screw Type with 22-14 AWG Wire Cable 250V Fuse Tube Casing for Electrical Circuit Protection](https://www.aliexpress.com/item/1005007846817140.html) - $4                                                                                                                                                                                                                                                                                                                                                                                                                                                      | A$4                     | aliexpress                                                               |
| 13     | Switch                                                                                                                                           | [Latching SPST rocker or toggle ](https://www.jaycar.com.au/spst-standard-toggle-switch/p/ST0570)(brass for retro feel) - $3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | A$3                     | Jaycar                                                                   |
| 14     | Buttons                                                                                                                                          | [3-4 tactile buttons](https://www.aliexpress.com/item/32815969627.html?) (page turn, mode, refresh) - $3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | A$3                     | Aliexpress                                                               |
| ~~15~~ | ~~Wire/connectors~~                                                                                                                              | ~~22 AWG silicone wire, JST-PH/XH pigtails, heat-shrink, M2.5 standoffs~~                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | ~~A$15~~                | ~~Jaycar, Core~~                                                         |
| 16     | Enclosure                                                                                                                                        | Timber, cork sheet, brass hinges/corners, M3 brass screws                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | A$25-50                 | Bunnings, Spotlight, op shop                                             |
|        | **Total**                                                                                                                                        |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | `$340-$440`             |                                                                          |
| 17     | usb-c liopo charger                                                                                                                              | gottem eyyyy                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |                         |                                                                          |

## 1.3 Power plan

- Average draw: ~1-1.5 W (Pi Zero 2 W with HDMI off, Wi-Fi/Bluetooth off when not syncing, keyboard idle, e-paper only drawing power while refreshing). Measure yours; settings change this a lot.
- Pack: 4x 5000 mAh at 3.6 V nominal = ~72 Wh. After boost-converter losses (~85%), about 60 Wh usable, so **roughly 40+ hours** of mixed use.
- Solar: a 10 W panel realistically gives 4-7 W in good sun. Two sunny hours covers a full day of reading/writing. Even a windowsill gives a trickle.

## 1.4 Wiring

```text
               +-----------------+
 6V 10W panel -> CN3791 MPPT     |
                | (set to 4.20 V) |
                +--- OUT+ / OUT- -+
                         |
   +---------------------+------------------------------+
   |  Protection board (1S)                             |
   |   P+ / P-  <-- charger and load both connect here  |
   |   B+ / B-  --> 4x 21700 in parallel (1S4P)         |
   +---------------------+------------------------------+
                         |
               [3A fuse]--+-- [rocker switch]
                         |
                  PowerBoost 1000 Basic (BAT in)
                         | 5V USB-A out
                         v
          USB-A -> micro-USB cable -> Pi Zero 2 W PWR port

  PowerBoost LBO (low battery) --> Pi GPIO (e.g. GPIO 26, pull-up)
  Pi Zero 2 W 40-pin header ---- Waveshare e-Paper HAT (SPI)
  Buttons: GPIO 5/6/13 to GND (internal pull-ups)
  Keyboard: USB via OTG cable (data port)
```

Why this layout: charging and loading both go through the protection board so over-discharge and short protection apply to everything. Powering the Pi through the USB port keeps its onboard protection in the path instead of back-feeding GPIO pins.

## 1.5 Build steps

1. **Bench-test power before touching the Pi.** Power the CN3791 from a bench supply or the panel, no battery connected, and confirm the output reads 4.20 V. If it does not, adjust per its datasheet/board instructions before connecting cells.
2. **Match the cells.** Charge each cell separately to 4.2 V (or measure and ensure all within 0.05 V), then place them in the parallel holder.
3. **Assemble the pack**: cells (B+/B-) into the protection board, then P+/P- to the fuse, switch and PowerBoost, and also to the CN3791 battery terminals.
4. **Verify** PowerBoost output with a multimeter: 5.0-5.2 V before plugging in the Pi.
5. **Flash the SD card** with Raspberry Pi OS Lite using Raspberry Pi Imager; preconfigure Wi-Fi, SSH, hostname and username.
6. **Mount the e-paper HAT**, enable SPI in `raspi-config`, install the Waveshare/omni-epd Python library, and run the vendor demo to confirm the panel works.
7. **Wire the buttons and LBO line.** Add `dtoverlay=gpio-shutdown,gpio_pin=<your pin>` (check polarity with a multimeter and the PowerBoost documentation) so low battery triggers a clean shutdown.
8. **Apply power-saving settings**: disable HDMI output, disable Bluetooth if the keyboard is wired, set the CPU governor to powersave, disable the activity LED, and turn Wi-Fi off by default (`rfkill`).
9. **Install writing and reading software** (see 1.6).
10. **Build the shell**: cut a recess/window for the 7.5" panel, mount the Pi on standoffs, secure cells in a lidded compartment, mount the keyboard in a lift-out tray or use a foldable kickstand design, hinge the panel "leaf" on the lid.
11. **Run a 24-hour burn-in** on a desk, logging battery voltage, before taking it outside.

## 1.6 Software plan
- [zerowriter](https://hackaday.io/project/193902-zerowriter/details) - custom software
- RPiOS, entirely terminal based writing TUI programs

runs a text-only Linux console and mirrors it onto the e-paper, so any terminal program works unchanged. Start with the framebuffer-mirror method below, and only build a custom terminal bridge if it falls short.

**The method: mirror the console framebuffer.** The [pocket-computer repo](https://github.com/MostlyFunctionalEngineering/pocket-computer) does this on a Pi Zero 2 W with a 4.2" (400x300) panel. `config.txt` forces a fake HDMI mode that matches the panel, so `/dev/fb0` has the same pixel count. A Python service reads the framebuffer about once a second, thresholds it to black and white, and pushes it to the panel with Waveshare's driver. Changed frames use a partial refresh, and a full refresh runs every 15 minutes. The `refresh` and `clear` aliases force a full refresh. The repo is MIT-licensed, tiny (3 commits) and tested only on the 4.2" panel with Raspberry Pi OS Lite (Bookworm), so treat it as a template. Its [OS setup page](https://github.com/MostlyFunctionalEngineering/pocket-computer/blob/main/docs/os-setup.md) lists what its installer does.

**Is it fast enough?** The panel sets the limit, not the software. With partial refresh at 0.4 s, steady typing updates the screen about twice a second, so words appear in small bursts. That suits drafting prose, but it is too slow for fast editing or scrolling. Use the three modes for different jobs:

|   |   |   |
|---|---|---|
|Mode|Time|Use it for|
|Partial|0.4 s|Typing and small edits|
|Fast|1.5 s|Opening an editor, page turns, anything that changes most of the screen|
|Full|4 s|Clearing ghosting: every 20-30 partials, plus a manual `refresh` alias|

**Changes needed for the 7.5" panel (800x480)**

1. Flash Raspberry Pi OS Lite 64-bit (Bookworm, as the repo tested; Trixie is untested there). Its service files expect the username `pocketcomputer` unless you edit them.
2. Fork the repo. In its `config.txt` snippet, change the forced mode from 400x300 to 800x480, then confirm with `cat /sys/class/graphics/fb0/virtual_size`.
3. In `main_display.py`, swap the 4.2" driver (`epd4in2_V2`) for `epd7in5_V2` and the 800x480 frame size. Use the driver's partial and fast init calls; check the exact method names in the Waveshare commit the installer pins.
4. Set the poll interval to about 0.5 s. Use a partial refresh by default, a fast refresh when most pixels change, and a full refresh after a set number of partials.
5. Drop the CardKB service. A USB keyboard works with the console natively.
6. Choose a console font with `console-setup`. Terminus 10x20 gives an 80x24 grid and 8x16 gives about 100x30; check with `stty size`.
7. Make the cursor visible and steady. The repo hides the console cursor, but you need one for writing. Turn off blinking (the kernel exposes a setting at `/sys/class/graphics/fbcon/cursor_blink`; verify on your image) so the cursor does not trigger refreshes.
8. Keep the forced HDMI mode on, because it provides the framebuffer. This replaces the "disable HDMI output" idea in step 8 of section 1.5. Keep Wi-Fi and Bluetooth off when not syncing.
9. Auto-login on `tty1`, start `tmux`, and run the mirror as a `systemd` service.

**Fallback: a terminal bridge.** If the framebuffer method feels too clumsy, run the TUI inside a virtual terminal (`pty` plus the `pyte` emulator), draw only the changed lines with Pillow and a bitmap font, and push those regions to the panel. You get a drawn cursor, custom fonts and smaller refresh areas, at the cost of maintaining more code. Community projects such as ZeroWriter-style builds already do this; check each repo's licence and activity first.

**Option: add a small LCD for fast typing.** A second screen gives instant feedback while the e-paper handles the page view and reading. It adds about A$15-45, a little wiring and some power draw, so build the single-screen version first and add this once it works.

- Parts: one 2.8"-3.5" SPI LCD (ST7789, ILI9341 or ILI9486 class, 320x240 or 480x320), mounted in the lid's side margin if it is 2.8" or smaller (measure the module first), plus a small transistor for backlight switching.
- Wiring: share SPI0 with the e-paper HAT but use chip-select CE1, plus its own data/command, reset and backlight pins. Keep those pins clear of the pins the HAT uses.
- Software: point the console at the LCD's framebuffer (`fbcon=map:` or `con2fbmap`). This replaces the fake-HDMI mirror above, so the forced HDMI mode is no longer needed. Confirm your kernel supports the LCD controller (or the module ships a vendor overlay) before ordering.
- E-paper role: a small Python "paper renderer" watches the file you are editing and, about 1.5 s after you stop typing, redraws its last 20-25 lines in a larger serif font with a 0.4 s partial refresh. Trigger it from the editor's autosave or `inotifywait`/`entr`. Mid-document edits need an editor hook that writes the cursor line so it shows the right part. In reading mode the e-paper shows the book and the LCD is the command line.
- Power: the LCD adds roughly 0.5-1 W, so autonomy falls from about 40 hours to about 30. Switch the backlight off after about 30 s idle and wake it on a keypress to recover most of it.
- Cheaper alternative: a small I2C OLED (about A$10) that shows only the line you are typing, drawing about 30 mA.

**Writing and reading tools**

- Writing: `micro` is the easiest TUI editor; `nano`, Vim or Neovim with a distraction-free plugin also work. Turn off line numbers, syntax colour and status clocks, because every redraw is a screen update. Write in Markdown and export with `pandoc`.
- Reading: `epr` and `bk` read EPUBs in the terminal, `glow` renders Markdown, and `less` handles plain text. Convert PDFs to text or EPUB first.
- Notes and sync: keep everything in a `git` repo and push over Wi-Fi when it is switched on, or use `rsync` or Syncthing.
- Sleep screen: keep a botanical plate for shutdown or idle; e-paper holds the image with no power.


## 1.7 Known issues and how to navigate them

| Issue                                                                                                                                      | What to do                                                                                                                        |
| ------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| **Wrong panel variant**: the 3-/4-colour (red/yellow) 7.5" Waveshare panels do **not** support partial refresh, which makes typing painful | Buy the black/white V2 panel and confirm "partial refresh" in its Waveshare wiki page before ordering                             |
| Typing latency                                                                                                                             | Refresh by word/line, run a dedicated low-overhead editor, and avoid a full desktop environment                                   |
| Ghosting                                                                                                                                   | Periodic full refresh; avoid long periods without one                                                                             |
| Cold weather reduces e-paper speed and cell capacity                                                                                       | Keep it inside a coat pocket/bag below ~5 C                                                                                       |
| Pi brownouts from weak boost converter or thin wire                                                                                        | Use 22 AWG or thicker, short leads, a quality boost board, and check the 5 V under load                                           |
| CN3791 set to the wrong voltage/MPPT point                                                                                                 | Verify 4.20 V first; buy the 6 V panel variant matching the board, or re-tune the MPPT divider per the datasheet for other panels |
| Parallel cells with mismatched voltage                                                                                                     | Equalise before connecting, always                                                                                                |
| Fragile e-paper ribbon cable                                                                                                               | Mount the panel rigidly, route the cable with a gentle bend, never flex it                                                        |
| Header-pin collisions between HAT and extra wiring                                                                                         | Use the Pi's USB port for power and plan GPIO usage up front: the HAT uses SPI and a few control pins                             |
|                                                                                                                                            |                                                                                                                                   |

# PART 3: Purchase and build order

**Suggested order (reduces wasted money):**

1. Build **Deck 1 first** (cheaper, teaches soldering, protection boards and solar charging at low risk).
2. For Deck 2, buy the **battery + MPPT + fuse hardware** first and test the power system with a bench lamp or 12 V fan before the PC goes in.
3. Buy the **mini PC** next and finish the software while the box is still on the bench.
4. Add **radios, SDR and Wi-Fi** last so the core system is stable.

**Things to verify before ordering anything**

- [x] Waveshare panel variant has **partial refresh** (Deck 1).
- Mini PC accepts a regulated 12 V supply and its barrel size (Deck 2).
- Battery dimensions fit your case's interior.
- Return policy for batteries, panels, and the case.
- Current prices at Core Electronics, Jaycar and Amazon AU against the estimates above.
