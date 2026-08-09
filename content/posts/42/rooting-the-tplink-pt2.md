---
title: part 2 - les vulnes
date: 2026-08-03
description: ""
toc: true
math: true
draft: true
categories:
tags:
---
<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking

- [ ] analyse fs properly, try and find router password 
- [ ] try exploit: https://www.zerodayinitiative.com/blog/2019/12/2/mindshare-hardware-reversing-with-the-tp-link-tl-wr841n-router-part-2
- [ ] install ghidra & RE to find `%s` password - https://lachy.io/articles/properly-installing-ghidra-on-an-m1-mac
- [ ] try and find own vulns (?)
- [ ] [Discovering a Hardcoded Root Password - Hacking the VStarcam CB73 Security Camera](https://www.youtube.com/watch?v=lbSalKp_ldA&) (UART to bootloader to firmware extraction to RE in ghidra to hardcoded root creds)
- [ ] https://jcjc-dev.com/2016/04/29/reversing-huawei-router-2-scouting-firmware/




# chat trying to be helpful:

Given what you've already recovered, you're at the point where you can turn this into a **proper embedded-device vulnerability assessment workflow** rather than just unpacking firmware.

You have:

```text
SPI flash dump
   │
   ├── mtd0  U-Boot 1.1.3
   ├── mtd1  Linux kernel
   ├── mtd2  SquashFS root filesystem
   ├── mtd3  config
   ├── mtd4  romfile
   ├── mtd5  rom
   └── mtd6  radio
```

I'd approach the analysis in **10 phases**.

---

# 1. Preserve your evidence first

Before changing anything, make a clean working directory:

```bash
mkdir -p ~/router-audit/{original,carved,rootfs,analysis,notes,tools}
```

Keep your original dump untouched:

```bash
cp modem.bin ~/router-audit/original/
```

Generate hashes:

```bash
shasum -a 256 modem.bin
```

Record the result in:

```text
~/router-audit/notes/hashes.txt
```

Do the same for every extracted partition.

This sounds excessive, but it becomes extremely useful when you eventually discover:

> "Was this actually in the firmware, or did I modify it during analysis?"

---

# 2. Build a firmware map

You've already essentially done this.

Create a table in your notes:

|Partition|Offset|Size|Purpose|
|---|--:|--:|---|
|mtd0|`0x000000`|`0x020000`|U-Boot|
|mtd1|`0x020000`|`0x140000`|Kernel|
|mtd2|`0x160000`|`0x660000`|SquashFS|
|mtd3|`0x7C0000`|`0x010000`|config|
|mtd4|`0x7D0000`|`0x010000`|romfile|
|mtd5|`0x7E0000`|`0x010000`|rom|
|mtd6|`0x7F0000`|`0x010000`|radio|

This becomes your reference map for everything else.

---

# 3. Analyse U-Boot

You've already established:

```text
U-Boot 1.1.3
Ralink UBoot
2017-06-22
bootdelay=1
bootcmd=tftp
baudrate=115200
```

Now investigate its environment and recovery functionality.

Run:

```bash
strings -a mtd0-boot.bin > analysis/uboot-strings.txt
```

Then:

```bash
grep -Ei \
'bootcmd|bootargs|bootdelay|tftp|tftpboot|serverip|ipaddr|netmask|gateway|bootfile|mtdparts|bootm|erase|protect|write|load' \
analysis/uboot-strings.txt
```

You're looking for:

- recovery mechanisms
    
- TFTP firmware loading
    
- serial firmware loading
    
- flash erase/write commands
    
- default network configuration
    
- boot arguments
    
- hidden diagnostic functionality
    
- authentication bypasses
    

### Security questions

Ask:

1. Can an unauthenticated person reach the bootloader?
    
2. Is there a password?
    
3. Is the bootloader console exposed on UART?
    
4. Can firmware be loaded without signature verification?
    
5. Can arbitrary flash regions be erased?
    
6. Is secure boot absent?
    
7. Does recovery accept arbitrary images?
    

Don't immediately try to exploit these.

**First document the trust boundary.**

---

# 4. Analyse the kernel

You've got an LZMA stream beginning around:

```text
0x20200
```

Try:

```bash
binwalk -a mtd1-kernel.bin
```

Then:

```bash
file mtd1-kernel.bin
```

and:

```bash
strings -a mtd1-kernel.bin | head -100
```

Search for:

```bash
strings -a mtd1-kernel.bin | grep -Ei \
'Linux version|Ralink|MIPS|ARM|kernel|gcc|busybox'
```

You want to establish:

```text
Architecture
Kernel version
Compiler/toolchain
Build date
Vendor patches
Enabled functionality
```

For vulnerability research, **kernel version is especially important**.

Don't immediately conclude:

> "Linux 2.x = vulnerable."

Embedded vendors frequently backport security patches without changing the version string.

Instead, later compare the vendor source/patches against upstream vulnerabilities.

---

# 5. Treat the SquashFS as your main target

You've now got:

```text
squashfs-root/
```

This is where I'd spend most of the research time.

Start with:

```bash
cd squashfs-root
find . -type f > ../analysis/all-files.txt
find . -type l > ../analysis/symlinks.txt
```

Then get a quick overview:

```bash
find . -type f | sort
```

Look at the major directories:

```bash
ls -la
ls -la bin sbin usr etc www var
```

You're trying to reconstruct:

```text
Boot
 ↓
init
 ↓
startup scripts
 ↓
network services
 ↓
HTTP server
 ↓
CGI / backend binaries
 ↓
privileged operations
```

---

# 6. Find every network-facing service

This is one of the highest-value parts.

Search:

```bash
find . -type f \( -name '*http*' -o -name '*telnet*' -o -name '*dropbear*' -o -name '*ftp*' -o -name '*upnp*' -o -name '*dns*' \)
```

Then search configuration:

```bash
grep -RniE \
'httpd|boa|lighttpd|uhttpd|thttpd|telnetd|dropbear|sshd|ftp|upnp|miniupnp|dnsmasq' \
etc 2>/dev/null
```

And startup scripts:

```bash
grep -RniE \
'httpd|boa|lighttpd|uhttpd|telnetd|dropbear|upnp|dnsmasq' \
etc/init.d etc/rc* 2>/dev/null
```

This gives you a preliminary **attack-surface inventory**.

Make a table:

|Service|Binary|Port|Privilege|Interface|Authentication|
|---|---|--:|---|---|---|
|HTTP|`...`|80|root?|LAN|?|
|HTTPS|`...`|443|root?|LAN|?|
|UPnP|`...`|1900|?|LAN|?|
|Telnet|`...`|23|root?|LAN|?|

Don't guess the values—derive them from the firmware and runtime behaviour.

---

# 7. Find the HTTP attack surface

This is where things get particularly interesting.

You've already found the web server.

Now locate:

```bash
find . -type f | grep -Ei 'cgi|html|htm|asp|php|js|web'
```

Look for:

```text
www/
web/
htdocs/
home/httpd/
cgi-bin/
```

Then:

```bash
find . -type f -perm -111
```

You're particularly interested in **executable CGI handlers**.

For each candidate:

```bash
file ./path/to/binary
```

Then:

```bash
strings -a ./path/to/binary | less
```

Search for dangerous primitives:

```bash
strings -a ./path/to/binary | grep -Ei \
'system|popen|exec|execl|execv|fork|sprintf|strcpy|strcat|gets|scanf'
```

This isn't proof of a vulnerability.

For example:

```c
system("reboot");
```

isn't necessarily exploitable.

But:

```c
system(user_supplied_parameter);
```

is potentially extremely significant.

The next step is tracing **where the input comes from**.

---

# 8. Hunt for hard-coded secrets

This should be systematic.

Search:

```bash
grep -RniE \
'password|passwd|secret|token|apikey|api_key|private_key|BEGIN RSA|BEGIN EC|BEGIN PRIVATE' \
. 2>/dev/null
```

Also:

```bash
find . -type f \( -name '*.pem' -o -name '*.key' -o -name '*passwd*' -o -name '*shadow*' \)
```

You already discovered:

```text
etc/passwd.bak
```

with:

```text
admin:$1$$iC.dUsGpxNNJGeOm1dFio/:0:0:root:/:/bin/sh
```

That is particularly worth investigating.

Don't just crack it.

Determine:

- Is it actually used?
    
- Is the password still accepted?
    
- Is the account enabled?
    
- Is the hash present in the live filesystem?
    
- Is the same credential used elsewhere?
    
- Is authentication handled by this file or by a proprietary mechanism?
    

For a responsible disclosure, **"hard-coded credential exists in firmware"** is much stronger when you can demonstrate its security impact.

---

# 9. Search for command injection systematically

Search the extracted filesystem for shell execution primitives:

```bash
grep -RniE \
'system\(|popen\(|execve\(|execl\(|/bin/sh|/bin/ash|eval ' \
. 2>/dev/null
```

Also:

```bash
grep -RniE \
'`[^`]+`|\$\([^)]*\)' \
etc www 2>/dev/null
```

Then investigate each result.

The key question isn't:

> "Does the firmware call `system()`?"

It's:

> **Can attacker-controlled data reach that call without safe validation?**

A useful data-flow model is:

```text
HTTP request
     ↓
parameter
     ↓
parser
     ↓
validation?
     ↓
environment/config/file
     ↓
shell command
     ↓
root process
```

That's the kind of chain that produces a meaningful vulnerability report.

---

# 10. Look for unsafe file operations

Search source strings and binaries for:

```text
strcpy
strcat
sprintf
vsprintf
gets
scanf
memcpy
memmove
open
fopen
unlink
rename
chmod
chown
```

Particularly interesting combinations are:

```text
HTTP input → filename → fopen()
HTTP input → path → unlink()
HTTP input → filename → system()
HTTP input → config → privileged daemon
```

Then investigate:

- path traversal
    
- arbitrary file read
    
- arbitrary file write
    
- symlink attacks
    
- TOCTOU conditions
    
- unsafe temporary files
    

---

# 11. Analyse permissions and privilege boundaries

Run:

```bash
find . -type f -perm -4000 -ls
```

and:

```bash
find . -type f -perm -2000 -ls
```

Then:

```bash
find . -type f -perm -111 -exec ls -l {} \; > ../analysis/executables.txt
```

You're looking for:

```text
root-owned executable
        ↓
network reachable
        ↓
attacker-controlled input
        ↓
dangerous operation
```

That's a high-value combination.

---

# 12. Examine startup scripts

This is extremely important on embedded Linux.

Look at:

```bash
find etc -type f | sort
```

Then:

```bash
find etc -type f -path '*init*' -print
```

Read:

```bash
cat etc/inittab
```

and relevant startup scripts.

You're looking for:

```text
/etc/init.d/
/etc/rc.d/
/etc/rcS.d/
/etc/profile
/etc/inittab
```

Determine exactly what starts at boot.

Build a chain:

```text
U-Boot
  ↓
kernel
  ↓
/sbin/init
  ↓
startup scripts
  ↓
network
  ↓
httpd
  ↓
CGIs
```

That gives you a map of the actual device.

---

# 13. Analyse the configuration partitions

Don't overlook these.

You extracted:

```text
mtd3-config.bin
mtd4-romfile.bin
mtd5-rom.bin
mtd6-radio.bin
```

Run:

```bash
file mtd*.bin
binwalk -a mtd*.bin
strings -a mtd*.bin
```

These may contain:

- device-specific configuration
    
- calibration data
    
- MAC addresses
    
- Wi-Fi credentials
    
- certificates
    
- serial numbers
    
- provisioning information
    
- persistent admin settings
    

Be careful about **not publishing these raw dumps** in a disclosure report—they may contain device-specific secrets.

---

# 14. Create a vulnerability checklist

I'd maintain:

```text
analysis/
├── uboot-strings.txt
├── kernel-info.txt
├── all-files.txt
├── executables.txt
├── services.txt
├── credentials.txt
├── web-surface.txt
├── startup.txt
└── findings.md
```

For every potential issue, record:

```text
Finding:
Affected component:
Firmware version:
Location:
Input:
Sink:
Privilege:
Preconditions:
Impact:
Evidence:
Reproduction:
Mitigation:
```

This prevents the research from becoming a giant pile of grep output.

---

# 15. Then move to dynamic analysis

Once static analysis has identified interesting targets, **don't start fuzzing the physical router blindly**.

You now have two complementary environments:

### Static

```text
SPI dump
  ↓
SquashFS
  ↓
binaries/config
  ↓
reverse engineering
```

### Dynamic

```text
real router
  ↓
UART
  ↓
network services
  ↓
HTTP requests
  ↓
observed behaviour
```

Use the real router to validate hypotheses you developed statically.

For example:

```text
Static:
"CGI handler appears to execute a privileged command."

          ↓

Dynamic:
"Does that endpoint actually exist?"

          ↓

Controlled test:
"Does benign input change behaviour?"

          ↓

Reverse engineering:
"Is input validated?"

          ↓

Finding:
"Unauthenticated command injection"
```

That's a much stronger research methodology than simply throwing exploits at the device.

---

# 16. Eventually reverse engineer the interesting binaries

For anything substantial, I'd use **Ghidra**.

Start with:

```bash
file squashfs-root/www/cgi-bin/*
```

Determine the architecture.

Then import the appropriate executable into Ghidra.

The workflow becomes:

```text
strings
   ↓
identify interesting function
   ↓
Ghidra
   ↓
find callers
   ↓
trace input
   ↓
identify validation
   ↓
identify dangerous sink
   ↓
test hypothesis on isolated device
```

For example:

```text
cgiMain()
   │
   ├── get_parameter("foo")
   │
   ├── validate_foo()
   │
   └── doSomething(foo)
                 │
                 └── system(...)
```

That's where you start moving from **firmware analysis** into genuine vulnerability research.

---

## Your first practical session

Given where you are **right now**, I wouldn't jump into Ghidra yet.

Do this first:

```bash
cd ~/Desktop/tp-link/squashfs-root
```

Then:

```bash
find . -type f | sort > ../analysis/files.txt
```

```bash
find . -type f -perm -111 -exec ls -l {} \; > ../analysis/executables.txt
```

```bash
grep -RniE \
'httpd|boa|lighttpd|uhttpd|thttpd|cgi|telnetd|dropbear|upnp|dnsmasq' \
etc usr bin sbin www 2>/dev/null \
> ../analysis/services.txt
```

Then:

```bash
grep -RniE \
'password|passwd|secret|token|api[_-]?key|private[_-]?key' \
etc usr bin sbin www 2>/dev/null \
> ../analysis/secrets.txt
```

Then:

```bash
grep -RniE \
'system\(|popen\(|execve\(|execl\(|/bin/sh|/bin/ash' \
etc usr bin sbin www 2>/dev/null \
> ../analysis/command-execution.txt
```

And:

```bash
find . -type f -perm -4000 -ls \
> ../analysis/suid.txt
```

### Then look at the results

```bash
less ../analysis/services.txt
```

```bash
less ../analysis/secrets.txt
```

```bash
less ../analysis/command-execution.txt
```

---

## The overall methodology

Keep this mental model throughout the project:

```text
                    ┌──────────────┐
                    │  SPI FLASH   │
                    └──────┬───────┘
                           │
             ┌─────────────┼──────────────┐
             ↓             ↓              ↓
           U-Boot        Kernel         RootFS
             │             │              │
             ↓             ↓              ↓
         boot/recovery   Linux       applications
                                           │
                              ┌────────────┼────────────┐
                              ↓            ↓            ↓
                            HTTP         UPnP        network
                              │
                              ↓
                           CGI/API
                              │
                              ↓
                       input validation
                              │
                              ↓
                        privileged sink
                              │
                              ↓
                         vulnerability
```

**That's the path I'd follow.**

And because you're doing this on hardware you own, you can go considerably deeper: once we identify the architecture and web stack, we can set up a **repeatable lab workflow** around this exact router—static analysis → Ghidra → emulation where possible → controlled dynamic testing → finding validation → CVE/CWE mapping → responsible disclosure.