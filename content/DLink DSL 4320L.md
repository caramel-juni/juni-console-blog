---
title: ""
date: 2026-08-30
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking


**Router:** DLink DSL 4320L

- Dissassembly & modding: https://www.instructables.com/Disassemble-and-Mod-the-D-Link-DSL-5300-COBRA-AC53/
- [Router teardown](https://web.archive.org/web/20171215115808/http://www.nitroware.net/previews/390-dlink-cobra-ac5300-modem-router-and-triple-band-wifi)

Attempt to read flash chip:
``` bash

flashrom -p ft2232_spi:type=2232H,port=B,divisor=16 -r router.bin       

flashrom v1.7.0 on Darwin 25.6.0 (arm64)
flashrom is free software, get the source code at https://flashrom.org

No EEPROM/flash device found.
Note: flashrom can never write if the flash chip isnt found automatically.


flashrom -p ft2232_spi:type=2232H,port=B,divisor=16 -r router.bin       
flashrom v1.7.0 on Darwin 25.6.0 (arm64)
flashrom is free software, get the source code at https://flashrom.org

Found Generic flash chip "unknown SPI chip (RDID)" (0 kB, SPI) on ft2232_spi.
===
This flash part has status NOT WORKING for operations: PROBE READ ERASE WRITE
This flash part has status UNTESTED for operations: WP
The test status of this chip may have been updated in the latest development
version of flashrom. If you are running the latest development version,
please email a report to flashrom@flashrom.org if any of the above operations
work correctly for you with this flash chip. Please include the flashrom log
file for all operations you tested (see the man page for details), and mention
which mainboard or programmer you tested in the subject line.
You can also try to follow the instructions here:
https://www.flashrom.org/contrib_howtos/how_to_mark_chip_tested.html
Thanks for your help!
Read is not working on this chip. Aborting
```
#### Flash chip:
- [MX25L3206E](https://www.alldatasheet.com/html-pdf/575455/MCNIX/MX25L3206E/1107/7/MX25L3206E.html)


1. 3.54-3.2V (flutuates) --> `TX`
2. 0V (`GND`)
3. 3.52V (`VCC`)
4. 3.22V --> `RX`

Section of boot logs:

``` bash

SEAMA ==========================================
  magic      : 5ea3a417
  meta size  : 36 bytes
  meta data  : dev=/dev/mtdblock/7
  meta data  : type=firmware
  meta data  :
  meta data  :
  image size : 20934688 bytes
verify_seama: signature=[(null)], type=[firmware]
  checksum   : 02C6B00A0DE7BCD0DE009478D9098EC2
  digest     : 02C6B00A0DE7BCD0DE009478D9098EC2
  Selected !!!
================================================
seama check OK!!
insize = 2097152, out size =8388608
uncompressed size = 5307872
lzma decompress success !
Closing network.
emergency web server closing ...
et0: link down
Starting program at 0x00008000
console [ttyS0] enabled, bootconsole disabled
serial8250.0: ttyS1 at MMIO 0x18000400 (irq = 117) is a 16550
brd: module loaded
loop: module loaded
pflash: found no supported devices
7 cmdlinepart partitions found on MTD device bcmsflash
Creating 7 MTD partitions on "bcmsflash":
0x000000000000-0x000000040000 : "u-boot"
0x000000040000-0x000000050000 : "devconf"
0x000000050000-0x000000060000 : "devdata"
0x000000060000-0x0000001d0000 : "mydlink"
0x0000001d0000-0x0000001f0000 : "langpack"
0x0000001f0000-0x000000200000 : "nvram"
0x000000000000-0x000000200000 : "flash"
Found a Zentel NAND flash:
Total size:  128MB
Block size:  128KB
Page Size:   2048B
OOB Size:    64B
Sector size: 512B
Spare size:  16B
ECC level:   1 (1-bit)
Device ID: 0xc8 0xd1 0x80 0x95 0x42 0x7f
3 cmdlinepart partitions found on MTD device nflash
[drivers/mtd/bcm947xx/nand/bcm_nflash.c nflash_mtd_init 566] name: nflash (3)
Yao Debug:elbox_fixup_nflash_parts:988:Enter.Yao Debug:lookup_nflash_elbox_rootfs_offset:918:Enter.
nflash: squash filesystem with lzma found at offset 0x1e0060
Creating 3 MTD partitions on "nflash":
0x000000000000-0x000002000000 : "upgrade"
0x0000001e0060-0x000002000000 : "rootfs"
0x000000000000-0x000008000000 : "nflash"
PPP generic driver version 2.4.2
PPP BSD Compression module registered
PPP MPPE Compression module registered
NET: Registered protocol family 24
```


``` bash
Please press Enter to activate this console. SERVD: start service [IPTABLES]
```


``` bash

  Selected !!!
================================================
seama check OK!!
insize = 2097152, out size =8388608
uncompressed size = 5307872
lzma decompress success !
Closing network.
emergency web server closing ...
et0: link down
Starting program at 0x00008000
console [ttyS0] enabled, bootconsole disabled
serial8250.0: ttyS1 at MMIO 0x18000400 (irq = 117) is a 16550
brd: module loaded
loop: module loaded
pflash: found no supported devices
7 cmdlinepart partitions found on MTD device bcmsflash
Creating 7 MTD partitions on "bcmsflash":
0x000000000000-0x000000040000 : "u-boot"
0x000000040000-0x000000050000 : "devconf"
0x000000050000-0x000000060000 : "devdata"
0x000000060000-0x0000001d0000 : "mydlink"
0x0000001d0000-0x0000001f0000 : "langpack"
0x0000001f0000-0x000000200000 : "nvram"
0x000000000000-0x000000200000 : "flash"
Found a Zentel NAND flash:
Total size:  128MB
Block size:  128KB
Page Size:   2048B
OOB Size:    64B
Sector size: 512B
Spare size:  16B
ECC level:   1 (1-bit)
Device ID: 0xc8 0xd1 0x80 0x95 0x42 0x7f
3 cmdlinepart partitions found on MTD device nflash
[drivers/mtd/bcm947xx/nand/bcm_nflash.c nflash_mtd_init 566] name: nflash (3)
Yao Debug:elbox_fixup_nflash_parts:988:Enter.Yao Debug:lookup_nflash_elbox_rootfs_offset:918:Enter.
nflash: squash filesystem with lzma found at offset 0x1e0060
Creating 3 MTD partitions on "nflash":
0x000000000000-0x000002000000 : "upgrade"
0x0000001e0060-0x000002000000 : "rootfs"
0x000000000000-0x000008000000 : "nflash"
PPP generic driver version 2.4.2
PPP BSD Compression module registered
PPP MPPE Compression module registered
NET: Registered protocol family 24
PPTP driver version 0.7
ehci_hcd: USB 2.0 'Enhanced' Host Controller (EHCI) Driver
ehci_hcd 0000:00:0b.1: EHCI Host Controller
ehci_hcd 0000:00:0b.1: new USB bus registered, assigned bus number 1
ehci_hcd 0000:00:0b.1: irq 111, io mem 0x18021000
ehci_hcd 0000:00:0b.1: USB 0.0 started, EHCI 1.00
hub 1-0:1.0: USB hub found
hub 1-0:1.0: 2 ports detected
ohci_hcd: USB 1.1 'Open' Host Controller (OHCI) Driver
ohci_hcd 0000:00:0b.0: OHCI Host Controller
ohci_hcd 0000:00:0b.0: new USB bus registered, assigned bus number 2
ohci_hcd 0000:00:0b.0: irq 111, io mem 0x18022000
hub 2-0:1.0: USB hub found
hub 2-0:1.0: 2 ports detected
xhci_hcd 0000:00:0c.0: xHCI Host Controller
xhci_hcd 0000:00:0c.0: new USB bus registered, assigned bus number 3
xhci_hcd 0000:00:0c.0: irq 112, io mem 0x18023000
xhci_hcd 0000:00:0c.0: Failed to enable MSI-X
xhci_hcd 0000:00:0c.0: failed to allocate MSI entry
usb usb3: No SuperSpeed endpoint companion for config 1  interface 0 altsetting 0 ep 129: using minimum values
xHCI xhci_add_endpoint called for root hub
xHCI xhci_check_bandwidth called for root hub
hub 3-0:1.0: USB hub found
hub 3-0:1.0: 1 port detected
u32 classifier
Netfilter messages via NETLINK v0.30.
nf_conntrack version 0.5.0 (3973 buckets, 15892 max)
ctnetlink v0.93: registering with nfnetlink.
xt_time: kernel timezone is -0000
BCM fast NAT: INIT
ip_tables: (C) 2000-2006 Netfilter Core Team
TCP cubic registered
Initializing XFRM netlink socket
NET: Registered protocol family 10
ip6_tables: (C) 2000-2006 Netfilter Core Team
IPv6 over IPv4 tunneling driver
NET: Registered protocol family 17
L2TP core driver, V2.0
PPPoL2TP kernel driver, V2.0
802.1Q VLAN Support v1.8 Ben Greear <greearb@candelatech.com>
All bugs added by David S. Miller <davem@redhat.com>
Northstar brcmnand NAND Flash Controller driver, Version 0.1 (c) Broadcom Inc. 2012
NAND device: Manufacturer ID: 0xc8, Chip ID: 0xd1 (Esmt NAND 128MiB 3,3V 8-bit)
Spare area=64 eccbytes 8, ecc bytes located at:
 14 15 30 31 46 47 62 63
Available 55 bytes at (off,len):
(1,13) (16,14) (32,14) (48,14) (0,0) (0,0) (0,0) (0,0) 
Scanning device for bad blocks
Options: NO_AUTOINCR,NO_READRDY,
1 cmdlinepart partitions found on MTD device brcmnand
[drivers/mtd/bcm947xx/nand/brcmnand.c brcmnand_mtd_init 1077] name: brcmnand (1)
Creating 1 MTD partitions on "brcmnand":
0x000002000000-0x000008000000 : "storage"
VFS: Mounted root (squashfs filesystem) readonly on device 31:8.
devtmpfs: mounted
Freeing init memory: 220K
Failed to execute /sbin/preinit.  Attempting defaults...

init started: BusyBox v1.14.1 (2017-10-03 14:43:42 CST)

starting pid 916, tty '': '/etc/init.d/rcS'
[/etc/init.d/S10init.sh]
[/etc/init.d/S12ubs_storage.sh]
Initializing USB Mass Storage driver...
usbcore: registered new interface driver usb-storage
USB Mass Storage support registered.
jnl: driver (UFSD_HEAD ufsd_f_90362_lke922_r265504_b442, LBD=ON) loaded at bf00f000
ufsd: module license 'Commercial product' taints kernel.
Disabling lock debugging due to kernel taint
ufsd: driver (UFSD_HEAD ufsd_f_90362_lke922_r265504_b442, paragon, acl, ioctl, sd2(5), tr, rsrc, nolazy) loaded at bf01c000
NTFS (journal support) included
FAT support included
Hfs+ support included
Build_for__DLINK_DIR-890L_k2.6.36_2014-09-15_ufsd_f_90362_lke922_r265504_b442
[/etc/init.d/S15udevd.sh]
udevd (955): /proc/955/oom_adj is deprecated, please use /proc/955/oom_score_adj instead.
[/etc/init.d/S16ipv6.sh]
Set DEFAULT policy as DROP.
[/etc/init.d/S19init.sh]
[/etc/init.d/S20init.sh]
  DEFNODE[/etc/defnodes/S11devdata.xml]
  DEFNODE[/etc/defnodes/S12devdata.php]
  DEFNODE[/etc/defnodes/S12flashspeed.php]
  DEFNODE[/etc/defnodes/S13dfs.php]
  DEFNODE[/etc/defnodes/S13localrec.php]
  DEFNODE[/etc/defnodes/S14dsl.xml]
  DEFNODE[/etc/defnodes/S14setchlist.php]
  DEFNODE[/etc/defnodes/S20device.xml]
  DEFNODE[/etc/defnodes/S22timezone.php]
[/etc/scripts/setdate.sh] 01/01/2000 ...
Sat Jan  1 00:00:07 UTC 2000
  DEFNODE[/etc/defnodes/S30device.php]
  DEFNODE[/etc/defnodes/S30device.xml]
  DEFNODE[/etc/defnodes/S31diagnostic.xml]
  DEFNODE[/etc/defnodes/S31locale.php]
  DEFNODE[/etc/defnodes/S33wifi.php]
  DEFNODE[/etc/defnodes/S40device.xml]
  DEFNODE[/etc/defnodes/S40links.php]
  DEFNODE[/etc/defnodes/S90device.xml]
  DEFNODE[/etc/defnodes/S90opendns.php]
  DEFNODE[/etc/defnodes/S90sessions.php]
  DEFNODE[/etc/defnodes/S90upnpigd.php]
  DEFNODE[/etc/defnodes/S90upnpwfa.php]
  DEFNODE[/etc/defnodes/S91upnpigd2.php]
SERVD: start service [LOGD]
   [/etc/init.d/S21usbmount.sh]
[/etc/init.d/S22mydlink.sh]
[/etc/init.d/S23udevd.sh]
SERVD: stop service [DEVICE.TIME]
SERVD: service [DEVICE.TIME] is already stopped.
SERVD: start service [DEVICE.TIME]
ntp1.dlink.com: Unknown host
getaddrinfo 2: Invalid argument
[/etc/init.d/S45gpiod.sh]
[/etc/init.d/rcS] done!
Factory reset time : 5 secs
wan_link_data.wanmode : -1
00: WPS Button using GPIO #7, input mode.
01: Factory Reset Button using GPIO #17, input mode.
02: Power_Status LED Green using GPIO #0, output mode.
03: Power_Status LED Orange using GPIO #2, output mode.
04: Internet LED Orange using GPIO #3, output mode.
05: Internet LED Green using GPIO #1, output mode.
06: USB2.0 using GPIO #21, output mode.
07: USB3.0 using GPIO #18, output mode.
08: USB2.0 LED Green using GPIO #15, output mode.
09: USB3.0 LED Green using GPIO #8, output mode.
10: WIFI 2.4G LED Green using GPIO #13, output mode.
11: WIFI 5G LED Green using GPIO #14, output mode.
[/etc/init0.d/S21layout.sh]: start ...
SERVD: start service [LAYOUT]
 mount: mounting /dev/mtdblock/4 on /htdocs/web/js/localization failed: Invalid argument
 [/etc/init0.d/S40event.sh]: start ...
                                                              SERVD: event [SEALPAC.LOAD/default]
   [/etc/init0.d/S40gpioevent.sh]: start ...
                             et_module_init: passivemode set to 0x0
et_module_init: txworkq set to 0x0
et_module_init: et_txq_thresh set to 0x0
 et_module_init: et_rxlazy_timeout set to 0x3e8
et_module_init: et_rxlazy_framecnt set to 0x20
ERROR fwder_init: fwd_cpumap nvram not present, using default
 fwd0: Broadcom BCM47XX 10/100/1000 Mbps Ethernet Controller 7.14.43.23 (r)
  fwd1: Broadcom BCM47XX 10/100/1000 Mbps Ethernet Controller 7.14.43.23 (r)
SEAMA: '/dev/mtdblock/4eth0: Broadcom BCM47XX 10/100/1000 Mbps Ethernet Controller 7.14.43.23 (r)
' is not a seama file !
[/etc/init0.d/S40ttyevent.sh]: start ...
   [/etc/init0.d/S41autowan.sh]: start ...
   [/etc/init0.d/S41autowanv6.sh]: start ...
  SERVD: event [AUTODETECT.REVERT/default]
 [/etc/init0.d/S41event.sh]: start ...
    [/etc/init0.d/S41factorydefault.sh]: start ...
[: missing ]
[/etc/init0.d/S41inf.sh]: start ...
      [/etc/init0.d/S41isplst.sh]: start ...
device fwd0 entered promiscuous mode
device fwd1 entered promiscuous mode
device eth0 entered promiscuous mode
device eth0.1 entered promiscuous mode
br0: port 1(eth0.1) entering forwarding state
br0: port 1(eth0.1) entering forwarding state
      [/etc/init0.d/S41smart404.sh]: start ...
                       [/etc/init0.d/S42event.sh]: start ...
 [/etc/init0.d/S42pthrough.sh]: start ...
  [/etc/init0.d/S43checkfw.sh]: start ...
  [/etc/init0.d/S43mydlinkevent.sh]: start ...
           [/etc/init0.d/S44localrec.sh]: start ...
localrec -f 0
localrec: not found
  [/etc/init0.d/S51wlan.sh]: start ...
    [/etc/init0.d/S52wlan.sh]: start ...
  bind: Address already in use
 dhd_module_init in
dhd_queue_budget = 256
dhd_sta_threshold = 1024
no wifi platform data, skip
PCI_PROBE:  bus 3, slot 0,vendor 14E4, device AA52(good PCI location)
PCI: Enabling device 0001:03:00.0 (0140 -> 0142)
DHD: dongle ram size is set to 983040(orig 983040) at 0x180000
dhd_attach: ctf_attach() failed
dhd_attach(): thread:dhd_watchdog_thread:917 started
dhd_deferred_work_init: work queue initialized 
Dongle Host Driver, version 1.194.20 (r508387)
Compiled in drivers/net/wireless/bcmdhd on Sep 19 2016 at 16:19:10
Register interface [eth1]  MAC: 00:90:4c:11:22:33

dhdpcie_download_code_array: Download, Upload and compare succeeded (43602a1-roml/pcie-ag-splitrx-fdap-mbss-mfp-wl11k-wl11u-txbf-pktctx-amsdutx-ampduretry-chkd2hdma-proptxstatus, 2016.05.26.134739, 2016/05/26 13:47:39).
dhdpcie_bus_write_vars: Download, Upload and compare of NVRAM succeeded.
PCIe shared addr read took 56383 usec before dongle is ready
DMA RX offset from shared Area 0
bus->txmode_push is set to 0
ring_info_raw: 56 
48 a0 26 00 d8 a8 26 00 f0 aa 26 00 08 ad 26 00 
14 ad 26 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 86 00 00 00 
max H2D queues 134
dhd_bus_start: Initializing 134 flowrings
dhd_bus_cmn_writeshared:
  0000: 00 00 a6 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 c0 a6 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 7c 24 8f 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 00 a4 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 00 9f 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 40 39 8f 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: c0 52 bd 8f 
dhd_bus_cmn_writeshared:
  0000: 08 00 00 00 
mac: 6 
40 9b cd a7 6d c4 
PCI_PROBE:  bus 4, slot 0,vendor 14E4, device AA52(good PCI location)
PCI: Enabling device 0001:04:00.0 (0140 -> 0142)
DHD: dongle ram size is set to 983040(orig 983040) at 0x180000
dhd_attach: ctf_attach() failed
dhd_attach(): thread:dhd_watchdog_thread:91d started
dhd_deferred_work_init: work queue initialized 
Dongle Host Driver, version 1.194.20 (r508387)
Compiled in drivers/net/wireless/bcmdhd on Sep 19 2016 at 16:19:10
Register interface [eth1]  MAC: 00:90:4c:11:22:33

dhdpcie_download_code_array: Download, Upload and compare succeeded (43602a1-roml/pcie-ag-splitrx-fdap-mbss-mfp-wl11k-wl11u-txbf-pktctx-amsdutx-ampduretry-chkd2hdma-proptxstatus, 2016.05.26.134739, 2016/05/26 13:47:39).
dhdpcie_bus_write_vars: Download, Upload and compare of NVRAM succeeded.
PCIe shared addr read took 46383 usec before dongle is ready
DMA RX offset from shared Area 0
bus->txmode_push is set to 0
ring_info_raw: 56 
48 a0 26 00 d8 a8 26 00 f0 aa 26 00 08 ad 26 00 
14 ad 26 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 86 00 00 00 
max H2D queues 134
dhd_bus_start: Initializing 134 flowrings
dhd_bus_cmn_writeshared:
  0000: 00 80 09 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 00 0a 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 b0 a4 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 40 0a 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 80 0a 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 20 84 8f 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 60 71 a2 8e 
dhd_bus_cmn_writeshared:
  0000: 08 00 00 00 
mac: 6 
40 9b cd a7 6d c2 
PCI_PROBE:  bus 1, slot 0,vendor 14E4, device AA52(good PCI location)
PCI: Enabling device 0002:01:00.0 (0140 -> 0142)
CONSOLE: uf[0] = 0xffff, returning bad-crc
CONSOLE: 000000.042 wl0: Broadcom BCM43602 802.11 Wireless Controller 7.10.274.20 (r504502)
CONSOLE: 000000.042 TCAM: 256 used: 143 exceed:0
DHD: dongle ram size is set to 983040(orig 983040) at 0x180000
dhd_attach: ctf_attach() failed
dhd_attach(): thread:dhd_watchdog_thread:924 started
dhd_deferred_work_init: work queue initialized 
Dongle Host Driver, version 1.194.20 (r508387)
Compiled in drivers/net/wireless/bcmdhd on Sep 19 2016 at 16:19:10
Register interface [eth1]  MAC: 00:90:4c:11:22:33

CONSOLE: 000000.043 reclaim section 1: Returned 122620 bytes to the heap
CONSOLE: 
dhdpcie_download_code_array: Download, Upload and compare succeeded (43602a1-roml/pcie-ag-splitrx-fdap-mbss-mfp-wl11k-wl11u-txbf-pktctx-amsdutx-ampduretry-chkd2hdma-proptxstatus, 2016.05.26.134739, 2016/05/26 13:47:39).
dhdpcie_bus_write_vars: Download, Upload and compare of NVRAM succeeded.
CONSOLE: uf[0] = 0xffff, returning bad-crc
CONSOLE: 000000.033 wl1: Broadcom BCM43602 802.11 Wireless Controller 7.10.274.20 (r504502)
CONSOLE: 000000.033 TCAM: 256 used: 143 exceed:0
CONSOLE: 000000.034 reclaim section 1: Returned 122620 bytes to the heap
CONSOLE: 
PCIe shared addr read took 56383 usec before dongle is ready
DMA RX offset from shared Area 0
bus->txmode_push is set to 0
ring_info_raw: 56 
48 a0 26 00 d8 a8 26 00 f0 aa 26 00 08 ad 26 00 
14 ad 26 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 86 00 00 00 
max H2D queues 134
dhd_bus_start: Initializing 134 flowrings
dhd_bus_cmn_writeshared:
  0000: 00 80 1d 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 00 1e 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 bc a4 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 40 1e 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 80 1e 8e 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 00 60 84 8f 00 00 00 00 
dhd_bus_cmn_writeshared:
  0000: 20 75 a2 8e 
dhd_bus_cmn_writeshared:
  0000: 08 00 00 00 
mac: 6 
40 9b cd a7 6d c6 
CONSOLE: uf[0] = 0xffff, returning bad-crc
CONSOLE: 000000.042 wl2: Broadcom BCM43602 802.11 Wireless Controller 7.10.274.20 (r504502)
CONSOLE: 000000.043 TCAM: 256 used: 143 exceed:0
CONSOLE: 000000.043 reclaim section 1: Returned 122620 bytes to the heap
CONSOLE: 
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
OK
wl_module_init: passivemode set to 0x0
wl_module_init: txworkq set to 0x0
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
OK
SERVD: start service [BRIDGE]
   BRIDGE: The device is not in the bridge mode.
SERVD: start service [LAN]
CONSOLE: 000002.282 wl1: wlc_enable_probe_req: state down, deferring setting of host flags
[/etc/init0.d/S60shareport.sh]: start ...
   CONSOLE: 000001.942 wl2: wlc_enable_probe_req: state down, deferring setting of host flags
 
            CONSOLE: 000002.824 wl0: wlc_enable_probe_req: state down, deferring setting of host flags
        SERVD: start service [DSL]
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
OK
SERVD: start service [PHYINF.ETH-1]
  SERVD: start service [PHYINF.ETH-2]

  SERVD: start service [PHYINF.ETH-3]
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
[31mMFS_MASTER[0m:master_fwdProc:201:can not find client
[31mMFS_MASTER[0m:ipcAddToFwdQueue:30:ipc add into forward queue.
  SERVD: start service [PHYINF.ETH-12]
SERVD: service [PHYINF.ETH-12] return errdevice eth0.3 entered promiscuous mode
or pppoe pass through (br0<->eth0.3)
108.
SERVD: start service [PHYINF.ETH-4]
  SERVD: start service [PHYINF.ETH-5]
  SERVD: start service [DEVICE.PASSTHROUGH]
     SERVD: start service [PHYINF.ETH-6]
  SERVD: start service [MYDLINK.LOG]
SERVD: start service [PHYINF.ETH-7]
 
 SERVD: start service [PHYINF.ETH-8]
  SERVD: start service [PHYINF.ETH-9]
  SERVD: start service [WIFI.PHYINF]
SERVD: service [WIFI.PHYINF] return error 108.
SERVD: start service [PHYINF.ETH-10]
  SERVD: start service [PHYINF.ETH-11]

  SERVD: start service [INFSVCS.BRIDGE-1]
infsvcs_setup: (BRIDGE-1) not exist.
SERVD: service [INFSVCS.BRIDGE-1] return error 9.
SERVD: start service [IPTABLES]
CONNTRACK_MAX=65536
CONNTRACK_MIN=32768





 [/etc/init0.d/S65ddnsd.sh]: start ...
[/etc/init0.d/S65logd.sh]: start ...
 [/etc/init0.d/S65user.sh]: start ...
 
 [/etc/init0.d/S68onetouch.sh]: start ...
[/etc/init0.d/S80telnetd.sh]: start ...
[/etc/init0.d/S81sshd.sh]: start ...
[/etc/init0.d/S82tftpd.sh]: start ...
[/etc/init0.d/S88arp.sh]: start ...
[2962] Jan 01 00:00:17 Failed loading /etc/dropbear/dropbear_dss_host_key
[2962] Jan 01 00:00:17 Failed loading /etc/dropbear/dropbear_ecdsa_host_key
[3014] Jan 01 00:00:17 Running in background
[/etc/init0.d/S91proclink.sh]: start ...
Create /var/proc/alpha symbolic link...
Enable Fast Route
[/etc/init0.d/S93cpuload.sh]: start ...
[/etc/init0.d/S94bcm_iqos.sh]: start ...




SERVD: stop service [PHYINF.WIFI]
SERVD: service [PHYINF.WIFI] is already stopped.
SERVD: start service [PHYINF.WIFI]
   SERVD: start service [IP6TABLES]

[/etc/init0.d/S95watchdog.sh]: start ...
[/etc/init0.d/S98smartconnect.sh]: start ...
 [/etc/init0.d/rcS] done!

Please press Enter to activate this console. 
starting pid 3242, tty '/dev/console': '-/bin/sh'


BusyBox v1.14.1 (2017-10-03 14:43:42 CST) built-in shell (msh)
Enter 'help' for a list of built-in commands.

[/etc/scripts/onetouch/dev_WlanUpdateChannel.sh]: BAND5G-1.1 ...
[/etc/scripts/onetouch/dev_WlanUpdateChannel.sh]: BAND24G-1.1 ...

# ls
www      usr      sys      proc     mnt      include  home     dev
var      tmp      sbin     mydlink  lib      htdocs   etc      bin
```