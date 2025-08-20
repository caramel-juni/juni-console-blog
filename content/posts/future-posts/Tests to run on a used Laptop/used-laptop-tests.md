---
title: Tests to run on a used laptop
date: 2025-08-19
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

1. [x] Inspect for visual scuffs, dents & scratches (top & bottom) 
2. [x] Remove chassis & check for any damage/corrosion/bent pins/disconnected components etc.
3. [x] `BIOS checks` - see below. **BEFORE** connecting to internet.
4. [ ] Boot into OS, & ensure that every USB/USB-C/peripheral port works as intended (lights to indicate charging, connecting & registering devices when plugged in etc.)
5. [x] Run `powerconfg /batteryreport` to determine battery wear.
6. [x] Flash `MemTest86+` onto a `USB` flash drive & boot from it to run a series of memory tests - allow at least an hour.
7. [ ] CPU, GPU & Disk tests. Use `HWinfo` to monitor temperature & download [OCCT](https://www.ocbase.com/) for all-in-one tests.
	1. [ ] Run `SMART` tests & r/w speeds with **[CrystalDiskMark](https://crystalmark.info/en/software/crystaldiskmark/)** ([guide](https://www.howtogeek.com/134735/check-ssd-or-hdd-health-with-smart/))
	2. [ ] **GPU/CPU:** either [OCCT](https://www.ocbase.com/) for all-in-one tests, or:
		1. [ ] **Performance:** **[Cinebench R23](https://apps.microsoft.com/detail/9pgzkjc81q7j?hl=en-us&gl=US)** (Microsoft store)
		2. [ ] ~~**Sustained Performance:** **3D mark Timespy** (Steam)~~ (overkill)
		3. [ ] **CPU Thermals:** [Prime95](https://www.mersenne.org/download/) (may be overkill)
8. [ ] **Wipe device, partitions & set up for multi-booting Windows & Linux:** 
       - Only use [`dban`](https://dban.org/) if using HDDs, as modern SSDs benefit little from it & instead use wear levelling + secure erase/TRIM to delete data (TRIM is not perfect, though). [Securely erase SSD data using strategies in the tutorial here - BIOS-level secure erase, or diskpart should be good enough.](https://www.tomshardware.com/how-to/secure-erase-ssd-or-hard-drive).
	       - Try via [UEFI BIOS](https://www.youtube.com/watch?v=VsP-A2ZM8t0)
	       - For Lenovo T480s: [ThinkPad Drive Erase Utility](https://support.lenovo.com/us/en/downloads/ds019026-thinkpad-drive-erase-utility-for-resetting-the-cryptographic-key-and-erasing-the-solid-state-drive-thinkpad)
       - **Reinstall via a fresh & [official Windows ISO](https://www.microsoft.com/en-us/software-download/windows11)** (flashed with rufus to disable telemetry) --> [follow video here to pre-debloat ISO](https://www.youtube.com/watch?v=0PA1wgdMeeI)
       - **Wipe all previous partitions** in the install & **re-partition carefully** according to plan (large enough `EFI` boot partition to boot multiple OS's).

# Plan for doing so (AI... eh):

1. How to create installation media
2. How to wipe all old partitions safely
3. How to set up partitions so you have room for Linux later
4. How Windows licensing works so you don’t lose activation
### Fresh Windows Install (with Dual Boot in Mind)

### 1. **Prepare Installation Media**

- On another computer, download the **Windows 11 (or 10) ISO** directly from Microsoft:  
    👉 [Windows Download Page](https://www.microsoft.com/software-download/)
- Use **Rufus** (Windows) or `dd`/Balena Etcher (Linux/Mac) to burn the ISO to a USB stick (8GB+).
- Plug USB into your laptop.

---
### 2. **Boot Into Installer**

- Enter BIOS/UEFI (usually **F2, Del, Esc, F12** at startup).
- Ensure:
    - **Boot Mode:** UEFI (not Legacy, unless hardware is ancient).
    - **Secure Boot:** Enabled (you can turn it off later if Linux needs it).
- Boot from the USB stick.

---
## 3. **Delete All Previous Partitions**

Once in Windows Setup:
1. Select **Custom: Install Windows only (advanced)**.
2. On the partition screen, delete **all existing partitions** (Recovery, System, OEM, etc.).
    - Warning: This wipes everything.
    - If it’s an SSD, Windows setup will send TRIM commands.
3. You’ll now have **one big unallocated space**.
    

---

## 4. **Partitioning Strategy (Windows + Linux)**
Here’s a recommended layout for **dual-boot** on a single drive (SSD/HDD):
- **EFI System Partition (ESP):**
    - Size: **512 MB** (FAT32)
    - This is the UEFI bootloader space shared by Windows & Linux.
    - Installer usually makes this automatically, but make it yourself if you want control.
- **Windows Boot + OS Partition (C:)**
    - Size: Give Windows what you want (e.g. **200GB–300GB**).
    - Format: NTFS.
- **Unallocated Space (for Linux)**
    - Leave the rest of the disk unallocated.
    - Later, Linux installer will let you split this into:
        - `/` root (ext4, 30–60GB)
        - `swap` (same as RAM, unless you have huge RAM, then ~4GB)
        - `/home` (rest of space for your Linux files).

---
## 5. **Install Windows**
- Select the Windows partition you created (NTFS) → install.
- Setup will auto-create/reuse EFI partition + recovery partition if needed.
- Wait until install completes & you’re in Windows.
---
## 6. **Activation**
- If the laptop already had a valid Windows license (OEM or retail), activation is automatic once you connect to the internet.
- Windows uses a **digital license tied to your hardware** (stored in Microsoft activation servers).
- No need to back up the product key unless you want to be safe:
---
## 7. **Prepare for Linux Install**
- Boot into your Linux distro USB (e.g. Ubuntu, Fedora, Arch).
- In Linux installer
    - Choose **Install alongside Windows** or manual partitioning.
    - Use the unallocated space you left for Linux.
    - Ensure it installs GRUB or rEFInd to the **EFI partition** (not overwriting the Windows partition).
After reboot, GRUB will let you pick **Windows or Linux**.




# BIOS Checks:
#### Must-haves:
- Ensure **`NO BIOS/UEFI password locks`**.
- Check if **Secure Boot/TPM ownership** is locked by an enterprise.
- **`Boot Order Lock`** --> `Disabled`, & verify that the **`boot order`** can be changed.
- Confirm **`Intel/AMD Management Engine/Computrace`** is **NOT (permanently) enabled**.
	- *This will phone home to the manufacturer when connected to a network - [obviously undesirable](https://www.reddit.com/r/thinkpad/comments/78d4i8/what_is_computrace/).* If you can set it to **Permanently Disabled**, do it immediately, & if you can only toggle between _Enabled_ and _Disabled_ → set to **Disabled** and leave it.
- **`TPM` & check whether it's `TPM 2.0` --> `Enabled`, if desired for Windows 11 &/or drive encryption support..**
	- **Clear TPM** to remove previous owner’s keys.
	- Leave **`Physical Presence for Clear`** enabled → ensures only someone at the machine can reset it.
- `Boot Mode` (`Diagnostic` vs `Quick`):
	- **While testing** → **`Diagnostic`** (runs `POST` checks every boot, can help catch hidden hardware issues).
	- **After validation/prolonged use** → switch to **`Quick`** for faster startups.
- `CSM` (`Compatability Support Module)` **--> can leave `Enabled` in case wanting to play with booting older/esoteric OSs, otherwise can `Disable`.**
	- **What is it?** A component of the UEFI firmware that provides legacy BIOS compatibility by emulating a BIOS environment, allowing support for legacy OSs & ROMs that do not support UEFI to still be used. Also supports the legacy `System Management Mode` (`SMM`) functionality, called `CompatibilitySmm`, as an addition to features provided by the UEFI SMM. This is optional, and highly chipset and platform specific. An example of such a legacy SMM functionality is providing USB legacy support for keyboard and mouse, by emulating their classic PS/2 counterparts. ([source](https://forums.tomshardware.com/threads/csm-enable-or-disable.3415336/))
- `Thunderbolt Security` → **`User Auth`** (must approve new Thunderbolt 3 devices in OS via a popup) or `Secure Connect` (popup + writes a cryptographic key to both that device and the system's firmware to perform challenge-response verification upon connection).
	- **NEVER** set to`No Security`, as it means **anything** can connect & immediately start using system resources (especially dangerous as `Thunderbolt 3` supports `PCIe` & thus **direct memory access**). [This article explains it well](https://www.dell.com/community/en/conversations/latitude/demystifying-thunderbolt-3-security-levels/647f8742f4ccf8a8de66b949).
	- However, rare to see popups in-OS as these **do not apply when connecting a generic USB device that is *capable* of Thunderbolt**.
### Also check (for later tinkering)
- Ensure **`Virtualisation Tech` is `Enabled`**
- All `I/O` is `Enabled`
- `Internal Device Tamper Protection` - `Disabled`, if you plan to crack laptop open.
- `Intel Hyper-Threading` --> `Enabled` 

### Some other BIOS-specific helpful info:
- [Should I enable Intel SGX Control?](https://www.reddit.com/r/intel/comments/gutnvr/should_i_turn_intel_software_guard_extensions_sgx/) --> No harm in doing so, but is [far from unbreakable]().
	- **What is it:** SGX creates isolated environments inside memory called enclaves, using encryption and hardware-level isolation to attempt to prevent tampering with data and code, even when BIOS, OS or hypervisors are comprimised. Apps that work with encryption keys, passwords, DRM technology, and other secret data often use SGX to run in a fortified container known as a trusted execution environment. However... `Load Value Injection` (`LVI`) can inject attacker's code into running programs, to steal sensitive data (keys & secrets) out of other regions of a vulnerable CPU. ([src](https://arstechnica.com/information-technology/2020/03/hackers-can-steal-secret-data-stored-in-intels-sgx-secure-enclave/))
- `CPU` **Microcode Updates** (try and mitigate LVI attacks, etc.) --> [how to perform](https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/best-practices/microcode-update-guidance.html).

### Guides:
- [How to test a used laptop - T480s](https://www.youtube.com/watch?v=bazUzYd2u5M)
- [Buying a Used Laptop: An Experts Guide on What to Check, Where to Buy, and What Models are Best](https://www.youtube.com/watch?v=NsTobnTfsYw)

## OS-level tests:
### Programs to run:

- Coredamage
- hwinfo sensors
- `powercfg /batteryreport`, then calculate the battery capacity with `Full Charge Capacity/Design Capacity`. 
  For me, `48,370/57,020 = 84.8%`, which isn't bad!


## After testing...
- Wipe with something like `dban`, & then do a **fresh install of your preferred OS**.
	- However, if using windows, take down a copy of the activation key/code *just in case* - should be embedded within firmware on modern laptops but better safe than sorry.
	- **Ensure you [know the difference between the Windows Product Key & the BackupProductKey](https://www.clrn.org/what-is-backup-product-key-default-in-registry/)**.
	  They can each be found via the below methods:
		- **Original Windows Product Key:**
			- `wmic path softwarelicensingservice get OA3xOriginalProductKey` (`wmic` disabled by default in Windows 11 and must be [manually enabled](https://techcommunity.microsoft.com/blog/windows-itpro-blog/how-to-install-wmic-feature-on-demand-on-windows-11/4189530))
			- `powershell "(Get-WmiObject -query ‘select * from SoftwareLicensingService’).OA3xOriginalProductKey"` (works on Windows 11 natively)
		 *My **ThinkPad t480s:** ==`HKXC8-NJ46G-98FGP-WFXQ3-DV66P*`==
		- **[Backup/Generic/Default Product Key](https://www.tenforums.com/tutorials/95922-generic-product-keys-install-windows-10-editions.html):** Allows users to install or upgrade to a specific Windows 10 [**edition**](https://www.tenforums.com/tutorials/22749-see-windows-10-edition-you-have-installed.html), but **will not activate** it.
		  **Can be found in registry:** `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform`.
			- *My **ThinkPad t480s:** ==`VK7JG-NPHTM-C97JM-9MPGT-3V66T`==* (found [here](https://www.tenforums.com/tutorials/95922-generic-product-keys-install-windows-10-editions.html))




### Reddit Checklists:

1. No visible cracks or loose parts - especially around hinges and drive connections (SATA, NVMe)
2. No signs of water contacts and corrosions around ports (USB, etc.)
3. Proper functionality of all the ports (USB, Ethernet, power, etc.)
4. In BIOS / UEFI: no computerace, admin passwords, etc.
5. Battery health check either through Lenovo Vantage or through “powercfg/batteryreport”
    

Nothing beats real life test. Try to use the laptop as much as you can in different environments.


