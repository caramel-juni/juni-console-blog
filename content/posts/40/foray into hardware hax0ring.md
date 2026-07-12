---
title: ""
date: 2026-07-09
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking


hello all. i have returned from the dead with a new burst of inspiration to dive into the realm of hardware haxoring, in anticipation of my halehound project (which should commencing sooooon).

here are some of the helpful, assorted links i've found:
- [Hardbreak](https://www.hardbreak.wiki/hardware-hacking/introduction) - how to get started hardware hacking, and stepping through the process
- [Voidstarsec (Blog) - brushing up on harware hacking essentials](https://voidstarsec.com/blog)

Kits (to build & RE):
- https://voidstarsec.training/products/pifex-full-kit



#### Training:
- [Rossman Training Videos](https://www.youtube.com/watch?v=D2u1zPgphiM&list=PLkVbIsAWN2ltOWmriIdOc5CtiZqUTH7GT)
- [His slides](https://docs.google.com/presentation/d/1PkeO_lC5WTPScSV3ZzEEjVuDWeQtL2eHK6jEcf7axA0/mobilepresent?pli=1#slide=id.gb813305ed3_143_934)

- [DEF CON 32 - Anyone can hack IoT- Beginner’s Guide to Hacking Your First IoT Device - Andrew Bellini](https://www.youtube.com/watch?v=YPcOwKtRuDQ)
- [IoT & Hardware Hacking for Beginners - Learn Fundamentals in 9+ Hours](https://youtu.be/j8SqZLr64NA?)

- [Matt brown](https://www.youtube.com/@mattbrwn)
- [How to solder - complete basics](https://www.makerspaces.com/how-to-solder/)

#### Elec Eng. Basics:
- **Voltage:** The potential difference between two points in a circuit, a measure of the potential energy. 
  **Voltage = latent strength, water pressure**
- **Current:** The rate of electron flow through a point in a circuit (electrons/second). 
  **Current = water flow rate**
- **Resistance:** The opposition to the flow of electrical current. Affected by material, length, temperature & thickness.
  **Resistance = narrowing the width of the water pipe**

*Electricity just wants to get to ground (0V) - so will flow through anything (components) in an attempt to get there.*

![](96372.png)


**AC vs DC**: DC is needed for electrical components as provides a flat/steady current (to be interpreted as a `0` or `1`), as opposed to AC which alternates as a wave & thus is much less precise (but works for "just power me" devices, like heaters).
So, when using AC power will need a DC converter (e.g. "power brick")

### Capacitors
- **Capacitors:** two charged plates with an insulator (dielectric) between them. They "retain/store" electrical charge, and are used to **smooth out a signal**. 
	- They **pass AC** (waving) and **block DC** (flat)
	- Can thus **take AC & convert it to DC** by **putting a capacitor to ground** on a power line.
	- This "filters out" the noisy AC by diverting it to ground through the capacitor, while the end component will get the remaining **steady DC current**.
  ![](Screenshot%202026-07-09%20at%203.41.52%20pm.png)![](Screenshot%202026-07-09%20at%203.42.13%20pm.png)
Capacitor types: Series or Parallel.
- **Series cap** → blocks DC, passes only AC → used when you want to strip away a DC level and keep the signal
- **Parallel (decoupling) cap** → DC flows past the capacitor (blocked) unaffected; but AC noise gets shunted through capacitor to ground → used to keep DC power to component clean and stable

### Shorts: when a shorter path to ground exists, it's taken.
- When a **"short"** occurs, that's because the capacitor **passes AC AND DC**, thus creating a **shorter path to ground** which the electricity will prefer & take. Caused by:
	- bridging components
	- failed component tying two signals/power lines together
		- e.g. spill water on component, capacitor explodes, then acts as a shorter path to ground
		  ![](Screenshot%202026-07-09%20at%203.48.04%20pm.png)
**Can't** determine a bad capacitor **with just a multimeter measuring voltage**, as **if they are all on the same line** soldered onto board, they will **all measure the same V**.
- Instead, can determine **which capacitor is the bad one by the heat generated** --> the broken one is acting as the path to ground & thus will heat up & be hotter.
- Warmer component = more likely to have short circuited (as all power going through it)

Can use (evaporation time):
- freeze spray
- Alcohol

**HOWEVER**

Heat generation only works when there is a **"partial short"**.

- **Partial short:** where a capacitor or component fails but still **passes SOME DC current**, means it will generate heat due to current flowing through it as the path of least resistance & the voltage difference present.
	- **Partial short:** NON-ZERO voltage, NON-ZERO current, LOTS of heat
- **A "perfect" short circuit**, where the component acts ENTIRELY as a wire & passes ALL AC & DC, means the broken component will pass a LOT of current but thus will cause NO voltage drop across the component (as is same either side)
	- **Perfect short:** HIGH current, NO voltage drop, NO heat
- An **open circuit** - when the capacitor's internal connection between plate & lead is broken, thus passes **no current** and behaving as if **infinite resistance** in both directions. Hence, will have 0A but some Voltage, but **not generate heat** as no current is passed through.
	- **Open circuit:** NO current, NON-ZERO voltage drop, NO heat
- pass no current but have a voltage drop
![](Screenshot%202026-07-09%20at%203.46.04%20pm.png)

