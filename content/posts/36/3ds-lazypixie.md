---
title: "Rooting the 3DS with LazyPixie: A Deepdive"
date: 2026-04-13
description: ""
toc: true
math: true
draft: false
categories:
  - 3ds, reverse-engineering
tags:
  - reverse-engineering
  - exploit-development
  - 3ds
---

<img src="https://juniblog.goatcounter.com/count?p=/3ds-lazypixie/" style="display: none">

a while ago, i installed custom firmware (CFW) to my 3DS to play modded & emulated games & ROMs, following a number of [excellent guides on YouTube](https://www.youtube.com/watch?v=vHG3xUy8eXY) and the incredible project that is the [3DS.hacks wiki](https://3ds.hacks.guide/get-started.html). 

now, aside from the fact i've spent more time ***doing*** all of this than actually ***playing*** anything (which is much moreso a problem with **me** and NOT the process - it can be done in under 30min, depending on your level of tweaking, customisation and original firmware!), i never knew how the actual exploit worked under the hood, especially the privilege escalation part where code injected into the 3DS as part of the initial entrypoint (via the Camera App, in my case) is able to achieve **full kernel-level access.**

then, my friend sent my a tangentially-related but also [brilliant writeup on exploiting StreetPass](https://mrnbayoh.github.io/36c3/), which gave kudos to the "[LazyPixie](https://github.com/TuxSH/LazyPixie)" and it's author [`tuxSH`](https://x.com/TuxSH), with that being one such kernel privesc. exploit for the 3DS that allowed CFW to be run in the first place.

As i'd also watched videos like [How a Terrible Game Cracked the 3DS's Security - Early Days of 3DS Hacking](https://www.youtube.com/watch?v=ImR-TdDAIJE&t=54s) (a game that i had and played once or twice, funnily enough!), i was intrigued by how the exploits worked under the hood, 

thus, i worked through the ["LazyPixie"](https://github.com/TuxSH/LazyPixie) `README.md` + went back and forth with some AI-assisted feedback to fill in any gaps & clarifications in my understanding of the source material (i'm a bit slow sometimes), and have written it up below both for posterity, and to maybe help others understand/get into the scene!

<div style="text-align: center"><img src="/posts/36/attachments/3ds-me.gif" style="width:500px"></div>

^^ *me trying to understand this and probably still being only like 30% of the way there*

---

# What is LazyPixie?

**[LazyPixie:](https://github.com/TuxSH/LazyPixie/blob/master/README.md)aka one example of how the 3DS can be rooted:** an arbitrary kernel write exploit using the PXI inter-process communication interface buffer handling code.
- *(`PXI` being a Nintendo-based `sysmodule` containing several IPC services: see https://www.3dbrew.org/wiki/PXI_Services for more info)*

# The 3DS: Inside me are two wolves (or rather, two systems...)
In essence, there are two systems on the 3DS:
- `Arm11 MPCore` (handling main system + games)
- `Arm9TDMI` (handling storage device access & security tasks, with **one userland process `Process9` that can perform privileged operations** - *decrypting keys, accessing protected NAND storage, and performing signature checks to verify what software/code can run*)

These two systems need to talk to one another, but **can't directly share memory in a cache-coherent way**, as the **`Arm9` has no Memory Management Unit (MMU)**, and cannot process virtual addresses at all — it needs raw physical addresses. 

As a result, the `ARM11` kernel must **expose its physical memory addresses to the `ARM9` for it to read & access**. It does so via the "`PXI` descriptor" system, which uses the `ARM11`'s `pxi` sysmodule to forward all Inter Process Communication (IPC) requests and replies it receives.

This allows userland processes (apps, etc.) to ask "*here's my buffer, please write out its physical address chunks somewhere the `ARM9` can read*". This "somewhere" is a `Static Buffer`, which is just a buffer whose **location is declared in advance** (before any IPC call is made). So, the `ARM11` kernel does the virtual→physical translation work _on behalf of_ the ARM9, which is incapable of doing it itself.

# Process of reserving & using an `Static Buffer`:
- Service thread **pre-registers a 4KB-aligned physical-memory-backed buffer** in its **`TLS` (thread-local storage)**. The `TLS` is a list of instructions like, *"static buffer slot 0 is at address X"*, etc.)
- Client makes a request **referencing a source buffer**
- The `ARM11` kernel **walks the source buffer's virtual→physical mapping** (as it has an `MMU`) and **writes the resulting `{physAddr, size}` pairs** into the service's pre-registered static buffer location
- The `pxi` `sysmodule` **forwards the request over `PXI` to the `ARM9`**, which can now **read those physical addresses directly**.
**TLDR;** The `static buffer` is a **landing zone** the service sets aside specifically for receiving this physical address metadata. 

Because the kernel code **(1) allows zero-size PXI static buffers** (skipping cache-cleaning checks in the code) and **(2) doesn't check whether the requested address is actually in userland** (only checking **whether the address is page-aligned**, i.e. the lower 12 bits are zero), any malicious service can pre-register **any page-aligned address** —including ***kernel*** address space— as its "`static buffer`." 

# Using the kernel write privilege to install CFW

The kernel then happily writes physical address data there as if it were a legitimate pre-declared landing zone, allowing **arbitrary writes to privileged kernel memory**, which can ***then*** be used to manipulate page tables and achieve full kernel code execution later on.

After gaining `ARM11` kernel write privileges via LazyPixie, an attacker can **send crafted `PXI` messages from the `ARM11`** kernel to instruct `ARM9`'s `Process9` (that can execute supervisor-mode code) to **perform privileged operations**, like decrypting keys, accessing protected `NAND` storage, & bypassing/patching signature verification that decides what software can run. This allows the `ARM11` side to control & use `Process9` to permanently compromise the system and install custom firmware!

---
# Gaining an in: the entry point *before* `LazyPixie`
LazyPixie is actually a second-stage exploit, first requiring **either**:
- Code execution in an `ARM11` service
- Unprivileged code execution ***plus*** the ability to **write to a service thread's `TLS`**.

This is done via a variety of entrypoints ([depending on firmware: could be via a browser, game, or DSiWare exploit](https://3ds.hacks.guide/get-started.html)), with the entire exploit process going roughly follows:
- **Stage 1: some form of userland entry** (e.g. browser exploit, game exploit, DSiWare exploit). Gets unprivileged code execution in a sandboxed process. For example, the camera can open a browser as part of the "Share to Facebook" feature. The browser (which has a larger attack surface, notably with the presence of `JS`) has a memory corruption bug that is exploited to achieve ***unprivileged*** code execution in an `ARM11` userland process (as the Camera app runs there, being a system app/"game"). This allows manipulating data in `ARM11` to perform the kernel privesc/exploit like `LazyPixie` described above, and in the next step.
- **Stage 2: kernel privilege escalation** (e.g. `LazyPixie`). Gets the attacker ***kernel*** write access in `ARM11` by exploiting missing address validation in the `ARM11` kernel's `PXI` buffer descriptor handling (detailed above)
- **Stage 3: `ARM9` compromise**. Uses the `ARM11`'s new kernel write access to **send malicious commands** to the `Process9` on the `ARM9` system via **`IPC`**, to ultimately bypass signature verification and install custom firmware (CFW)!

---

... and voila! there you have it - you've got your CFW in all of its glory, and are ready to install (and hopefully *actually play*) as many funky ROMs, games and homebrew and your heart desires. 

just make sure to send a small prayer to those hardworking RE's in the [3DS Brew/Modding scene](https://www.3dbrew.org/wiki/Main_Page) for all their (continued) efforts on this. 

**they walked so we could.. *sit down and play*.**

<div style="text-align: center"><img src="/posts/36/attachments/3ds-haxor.gif" style="width:600px"></div>

# Supporting Resources:
- [DEF CON 26 - smea - Jailbreaking the 3DS Through 7 Years of Hardening](https://youtu.be/WNUsKx2euFw)
- [LazyPixie Exploit](https://github.com/TuxSH/LazyPixie)
- [3DS Homebrew & Modding Wiki](https://www.3dbrew.org/wiki/Main_Pag)
- [How a Terrible Game Cracked the 3DS's Security - Early Days of 3DS Hacking](https://youtu.be/WNUsKx2euFw)