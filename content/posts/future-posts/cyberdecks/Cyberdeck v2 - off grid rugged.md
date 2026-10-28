---
title: ""
date: 2026-10-22
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking
switch 
https://www.aliexpress.com/item/1005009632232679.html?


# PART 2: Deck 2 "OUTPOST" (Pelican-style off-grid multi-tool)

## 2.1 Concept
![](Screenshot%202026-10-22%20at%2010.29.12%20am.png)

A hard waterproof case holding a 1,280 Wh LiFePO4 battery in the base, a ply or 3D-printed deck plate above it carrying a 12 V mini PC, fuse block and converters, a 14" screen in the lid, a keyboard in a lift-out tray, and an external MPPT charger fed by a folding solar panel. It runs a full Linux desktop (Kali/Debian/Ubuntu), SDR, Wi-Fi assessment tools, a mesh-radio node, and works as a power bank for your phone/camera.

## 2.2 Compute choice (decide first)

|                                                                            |                                            |                                                             |                                                                          |
| -------------------------------------------------------------------------- | ------------------------------------------ | ----------------------------------------------------------- | ------------------------------------------------------------------------ |
| Option                                                                     | Price (est.)                               | Pros                                                        | Cons                                                                     |
| **A. N150 mini PC** (16 GB / 512 GB, 12 V DC input)                        | A$250-400 new                              | Runs on 12 V directly; 6-15 W; fast enough for VMs and Kali | Check the exact input voltage tolerance; new memory prices are inflated  |
| **B. Used ThinkCentre Tiny / EliteDesk Mini** (i5-8500T class)<br>i5-9500T | A$150-250 used                             | Cheapest per performance; upgradable                        | Needs 19 V input (add a 12 V to 19 V boost), higher idle draw (~10-20 W) |
| **C. Raspberry Pi 5 4GB/8GB**                                              | US$110 / US$180 + case, cooler, NVMe board | GPIO, very low power                                        | Price after Oct 2026 hikes makes it poor value; weaker for heavy tools   |

**Recommendation: Option A.** Cheaper and simpler than a Pi 5 right now, and it needs no 19 V converter.

## 2.3 Case choice

- **Genuine Pelican** (1500-1620 class) is the "ideal" at ~A$250-350 for the size you need; use the **purge valve** and pick a model with enough depth.
- **Budget**: generic IP67 hard cases from Amazon AU/AliExpress at A$80-150, or Plano/Nanuk/other mid-priced brands. The functional requirements are the same: rigid, sealed, roomy, with removable foam.
- **Fit check**: the LiTime/Redodo **"Mini" 100 Ah** LiFePO4 is only ~230x138x208 mm (about 9.0x5.4x8.2 in) and ~8.7 kg, much smaller than a standard 100 Ah (~330x172x214 mm). Plan about 250x230x160 mm of interior footprint for the battery lying flat, plus space above for the deck plate. Measure the interior of any case you buy.

## 2.4 Bill of materials

|   |   |   |   |   |
|---|---|---|---|---|
|#|Part|Pick|Est. price|Where|
|1|Case|Genuine Pelican or IP67 hard case, deep enough as above|A$100-350|Pelican stockists, Amazon AU, AliExpress|
|2|Computer|12 V N100 mini PC, 16 GB RAM, 512 GB|A$250-400|Amazon AU, official brand stores|
|3|Battery|12 V 100 Ah **Mini** LiFePO4 with 100 A BMS (US$154-183 listed in US; allow ~A$300-420 landed in AU)|A$300-420|LiTime AU, Redodo, VoltX|
|4|Solar panel|100 W folding "suitcase" panel with MC4 or Anderson plug|A$130-200|Bunnings, Supercheap Auto, eBay, Amazon AU|
|5|MPPT charger|20 A MPPT with a lithium/LiFePO4 profile (EPEver Tracer-class, Renogy Rover-class, or Victron SmartSolar 75/15)|A$100-170|Amazon AU, Victron AU resellers|
|6|Screen|14" 1080p portable monitor (USB-C/mini HDMI)|A$110-160|Amazon AU, Kogan|
|7|Keyboard/pointer|Compact 65% keyboard + trackball, or a small keyboard/touchpad combo|A$40-80|Amazon AU|
|8|Regulator for PC|**Buck-boost** DC-DC set to 12.0 V, 10 A rated (fixed or adjustable)|A$20-35|Jaycar, eBay|
|9|USB-C / 5 V power|12 V to 5 V / USB-C PD buck module (3 A+), for hub and screen|A$15-30|Jaycar, Amazon AU|
|10|Fuse/distribution|6-way blade fuse block, battery isolator switch, 40 A MIDI/ANL fuse + holder, 20 A inline fuse, bus bars|A$60-100|Jaycar, Supercheap Auto, Bunnings|
|11|Cable/lugs|8-10 AWG (6-10 mm2) tinned copper battery cable, assorted lugs, 16-18 AWG for small loads, heat-shrink|A$40-70|Supercheap, Jaycar|
|12|Monitoring|DC voltmeter/ammeter panel or shunt meter (or the battery's Bluetooth BMS app)|A$15-35|eBay, Jaycar|
|13|Cooling|92-120 mm 12 V fan + thermal control module|A$12-25|Jaycar, Amazon AU|
|14|Wi-Fi adapter|Monitor-mode capable USB adapter (Alfa AWUS036ACM-class)|A$70-100|Amazon AU, specialist resellers|
|15|SDR|RTL-SDR Blog V4 kit with antennas|A$60-90|Amazon AU, hobby electronics stores|
|16|Mesh radio (optional)|Meshtastic LoRa node (Heltec V3 / RAK class)|A$35-60|Core, Amazon AU|
|17|USB hub|Powered 4-7 port USB 3 hub|A$20-35|Amazon AU|
|18|Storage|1 TB NVMe/USB SSD|A$90-150|Amazon AU|
|19|Panel-mounting hardware|Anderson/MC4 panel input, USB-C socket, cable glands, stand-offs, ply tray|A$30-60|Bunnings, Jaycar|
||**Bare-bones total** (items 1-13 only, cheapest picks, used PC)||**~A$1,050**||
||**Fully loaded total** (everything above)||**~A$1,700-2,100**||

To go cheaper: used mini PC, generic case, 50 Ah battery (half the runtime), and skip the RTL-SDR/Wi-Fi/mesh until later. To go bigger: a 200 Ah battery (US$359 sale price seen in 2025) needs a bigger case and a heavier panel.

## 2.5 Power budget

|   |   |
|---|---|
|Load|Draw|
|N100 mini PC|6-25 W|
|14" screen|5-8 W|
|Wi-Fi adapter|2-3 W|
|RTL-SDR|1-1.5 W|
|Hub, keyboard, fan, mesh node|3-5 W|
|**Typical total**|**~20-35 W** (45 W+ under load)|

- 1,280 Wh x ~90% usable = ~1,150 Wh, so **about 35-50 hours** at typical load and about 25 hours flat-out.
- A 100 W folding panel produces ~60-80 W in strong sun. Estimate **300-400 Wh on a sunny Adelaide spring/summer day** and about half that in winter, enough to keep the deck topped up with light use.
- LiFePO4 charge limit: charge current under 0.5C (50 A); the 20 A MPPT is well within that.

## 2.6 Wiring

```text
  SOLAR  100W folding panel --MC4/Anderson--> [15A PV fuse/breaker]
                                                    |
                                          +---------v---------+
                                          |   20A MPPT        |
                                          |  (LiFePO4 profile)|
                                          +---+---------+-----+
                                         BAT+ |         | BAT-
                                       [20A fuse]       |
                                              |         |
   +------------- LiFePO4 12V 100Ah (BMS 100A) ----------+
   |  (+)                                         (-)    |
   +--[Master isolator switch]--[40A MIDI fuse]-> BUS (+) |
                                                          |
                                                  BUS (-) <---------+

  BUS(+) --> 6-way fuse block:
      F1 10A -> buck-boost 12.0V -> N100 mini PC (12V barrel)
      F2  5A -> 12V->5V/USB-C PD module -> screen + powered USB hub
      F3  3A -> 12V thermostat fan
      F4  5A -> USB-C PD outlet (phone/camera charging)
      F5  3A -> voltmeter / BMS display
      F6 spare

  MPPT connects DIRECTLY to the battery (its own fuse), NOT through the load bus.
  Do NOT power the PC from the MPPT "load" terminals.
```

**Connection order (every time):** battery first, then the MPPT, then the panel. Disconnect in reverse order. This lets the MPPT detect the battery voltage correctly.

**Cable sizing** (short runs under ~1 m): battery to isolator and main fuse in 8 AWG (10 mm2) or thicker; MPPT to battery in 10 AWG (6 mm2); individual loads in 16-18 AWG with the right fuse. Use proper crimps, never twist-and-tape.

## 2.7 Build steps

1. **Test the compute first**: boot the mini PC from a bench 12 V supply, install your OS (Kali, Debian or Ubuntu), update it, and confirm Wi-Fi/Ethernet/USB work before putting it in a box.
2. **Plan the layout**: battery low and central, secured with straps/brackets; deck plate (plywood or 3D-printed tray) above; screen in the lid; keyboard tray; panel and charging connectors on one end. Mock it up with cardboard.
3. **Prepare the case**: cut ports for panel input, USB-C, Ethernet, antenna SMA, power switch and voltmeter. Use cable glands and rubber gaskets; keep water ingress low.
4. **Install and secure the battery** with a strap or L-brackets; keep terminals covered.
5. **Install the isolator, main fuse, bus bars and fuse block** with the isolator **open**. Crimp and heat-shrink every lug.
6. **Wire the MPPT** to the battery via its fuse; set its battery profile to **LiFePO4/lithium** (absorption roughly 14.2-14.4 V, float ~13.5 V; follow the exact figures in your battery's datasheet).
7. **Set the buck-boost to 12.0 V** on the bench with a multimeter **before** connecting the PC.
8. **Wire the loads**, close the isolator, and check voltages at each output.
9. **Add cooling**: mount the fan to pull air across the PC and exhaust through a filtered vent. Do not seal a running PC in a closed case. Run it with the lid open or the vents uncovered.
10. **Connect the panel** in sunlight and confirm the MPPT shows charging.
11. **Load test**: run a stress test for 1-2 hours; watch temperatures, voltage drop and fuse temperatures.
12. **Label everything** (fuse values, polarity, "connect battery first") on the lid.

## 2.8 Hacking/radio setup (software)

- Install Kali (or Debian + selected tools) on the mini PC; use a USB 3 SSD or the internal NVMe.
- Wi-Fi adapter: confirm the chipset has an upstream Linux driver (MT7612U-class is a common choice) and test monitor mode on your own network.
- RTL-SDR: install the V4 drivers and try `rtl_test`, SDR++/GQRX; keep the antenna outside the case and away from converters.
- Meshtastic: flash the node, set your region (Australia: use the AU frequency plan) and connect via USB or Bluetooth.
- **Legal note**: only test networks and systems you own or have **written permission** to test. Unauthorised access is a criminal offence in Australia (federal and state law). Check ACMA rules for any transmitting radio equipment.

## 2.9 Known issues and how to navigate them

|   |   |
|---|---|
|Issue|What to do|
|**Pi 5 / RAM / SSD price spike**|Buy used or N100, buy storage only when needed, avoid memory-heavy configurations|
|14.4 V charge voltage can damage a 12 V-only PC|Always run the PC through the regulated buck-boost; never straight from the battery bus|
|Brownouts/BMS cut-outs on surge|BMS is 100 A; keep loads well under it; fuse every branch; thick cable|
|RF noise from DC-DC converters ruins SDR reception|Use shielded or well-filtered converters, ferrite clamps on the USB and power leads, keep the antenna outside on a short coax, power the SDR via a hub away from converters|
|Heat from sealed case|Treat the case as a carry/transport shell; operate open with active airflow and a thermostat fan|
|Condensation/moisture|Silica gel packs, keep the purge valve closed in transit, open and vent on arrival|
|LiFePO4 cannot charge below 0 C|Choose a battery with low-temperature protection if you will camp in cold; otherwise charge indoors on frosty mornings|
|Weight (~9 kg battery + case + kit)|Add a shoulder strap or trolley; keep the panel separate|
|Panel voltage vs MPPT limit|Check the panel open-circuit voltage is well under the MPPT's max PV input (Victron 75/15 allows 75 V; most 100 W folding panels are around 22 V)|
|Shorted polarity|Colour-code all wiring, use keyed connectors (Anderson/XT60), keep the isolator open while wiring|
|Airline/courier rules on lithium|Not airline-friendly; use road transport or a dangerous-goods courier|
|Stable power for the screen|Use a quality USB-C PD buck module; a cheap one may whine or reset the display|

---
