---
title: ""
date: 2026-08-22
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking



Good — this is a well-trodden, legitimate area of security research (this is basically what Cisco Talos, Forescout, ZDI, and countless independent researchers publish routinely). Here's a comprehensive framework for router/IoT firmware auditing.

## 1. Setup & Scope

- Only test hardware you own or have explicit written authorization to test.
- Build a lab: a UART/JTAG adapter (CH340/FTDI), a Bus Pirate or FT2232H for SPI flash dumping, logic analyzer, and a spare router or two you're willing to brick.
- Set up an isolated VLAN/network segment so a compromised device can't touch anything else.

## 2. Extraction (you said you have this) — quick checklist anyway

- SPI/NAND flash dump via clip (e.g., `flashrom`), UART bootloader dump, or vendor firmware update file.
- Verify the dump: `binwalk -e firmware.bin`, check entropy (`binwalk -E`) to spot compressed/encrypted regions vs. plain filesystem.
- Extract filesystem (squashfs/jffs2/ubifs/cramfs) — `unsquashfs`, `jefferson`, `ubireader`.

## 3. Static Analysis Framework

**A. Recon the filesystem**

- `/etc/passwd`, `/etc/shadow` → hardcoded or weak-hash credentials (this is one of the single most common router bugs — see the Billion 5200W-T / Zyxel P660HN cases above, which had hardcoded supervisor accounts usable to unlock authenticated command injection).
- Init scripts (`/etc/init.d`, `rcS`) → services started, ports opened, debug flags.
- `/etc/config`, `/etc/*.conf` → default WiFi keys, UPnP config, exposed management services.
- Look for leftover debug/backdoor mechanisms — TP-Link's CVE-2025-7851 came from _incompletely removed_ debug code from an earlier patch (CVE-2024-21827), gated behind a file-existence check. Diffing patched vs. unpatched firmware for "removed" functionality that's actually just gated is a proven technique.

**B. Binary/web interface analysis**

- CGI/Lua/PHP handlers behind the web UI are the highest-value targets — most router RCEs live here.
- `grep -r` across CGI/Lua scripts for `system(`, `popen(`, `exec`, `eval`, string concatenation into shell commands. TP-Link's LuCI implementation has a long history here: CVE-2023-1389 (unauthenticated command injection via the `country` POST parameter, later weaponized into Mirai), and multiple Talos-disclosed LuCI bugs in 2024 — Forescout's 2026 research followed up by systematically re-auditing the same Lua codebase and found two more (CVE-2025-7850 in the WireGuard private-key field, unsanitized before being passed to a shell command).
- CVE-2024-53375 (TP-Link Archer, authenticated RCE) came from an unsanitized `ownerId` parameter that should've been coerced with `tonumber()` — classic type-confusion-into-injection in Lua CGI handlers.
- Load binaries (`httpd`, `cgibin`, custom daemons) into Ghidra/IDA. Since most routers are MIPS/ARM, use `mipsel`/`arm` processor modules. Look for:
    - `strcpy`/`sprintf`/`memcpy` into fixed buffers → stack overflows
    - Unbounded loops over network input
    - String-formatting functions fed attacker input → format string bugs
- Search binaries and scripts for hardcoded credentials/keys with `strings`, and for known-weak crypto (static AES keys, ECB mode, homegrown "encryption").
- Look for shared/reused vendor SDKs (RealTek, Broadcom, MediaTek reference code) — bugs in these propagate across many product lines and vendors, so checking CVE history for the SDK is high-leverage.

**C. Config/backup files**

- Router config export/backup features frequently leak plaintext WiFi passwords, admin hashes, or VPN PSKs — check how they're generated and whether they require auth.

## 4. Dynamic Analysis / Emulation

- **Firmadyne / FirmAE** for full-system QEMU emulation when you can't run on real hardware, or when you want to fuzz without bricking your only device.
- On real hardware: get a root/UART shell if possible, then live-trace with `strace`, watch `/proc`, monitor spawned processes during web UI interaction (this is literally the detection technique used to catch CVE-2026-5509-style command injection — unexpected `sh`/`busybox` children spawned from HTTP handlers).
- Traffic analysis: intercept HTTP(S) traffic between app/router with Burp/mitmproxy — check for auth bypass, IDOR-style access to other users' settings, CSRF (routers are notoriously bad at CSRF protection on admin actions).
- Fuzz CGI/UPnP/SOAP endpoints with something like `boofuzz`, radamsa-mutated inputs, or AFL++ against extracted binaries running under QEMU user-mode emulation.
- Test authentication: brute-force protection (or lack of it — the GL.iNet AXT1800 case had no rate limiting on admin login, enabling brute-force that fed into a downstream command injection chain), session token entropy/predictability, default credentials.

## 5. Vulnerability Classes to Prioritize (ranked by real-world impact)

1. **Unauthenticated command injection** — highest impact, most commonly chained into botnets (Mirai variants target exactly this class).
2. **Authenticated command injection** — still critical, especially when chained with #3 or #6.
3. **Hardcoded/default credentials** — turns "authenticated" bugs into unauthenticated ones.
4. **Buffer overflows in network-facing daemons** (UPnP, SOAP, WPS handlers are classic culprits).
5. **Authentication bypass / broken session management** — e.g., predictable tokens, missing auth checks on certain API endpoints while others are protected.
6. **CSRF on state-changing admin actions** — DNS hijack, remote management enable, etc.
7. **Incomplete patches / debug backdoors** — always re-audit "fixed" CVEs; vendors frequently patch the symptom, not the root cause (TP-Link's CVE-2024-21827 → CVE-2025-7851 is a textbook example).
8. **Insecure update mechanisms** — no signature verification, HTTP instead of HTTPS for firmware pulls.

## 6. Methodology (step-by-step)

1. Recon: identify chipset, SDK vendor, firmware version, prior CVE history for this product line and its shared codebase.
2. Extract & catalog filesystem; diff against any prior firmware versions you can obtain (patch diffing reveals what vendors silently fixed — and sometimes what they didn't).
3. Static triage: grep for dangerous sinks, enumerate all web-exposed CGI/API endpoints, map each to its handling binary/script.
4. Prioritize endpoints reachable without auth, then those reachable with low-privilege auth.
5. Manual code review of prioritized endpoints in a disassembler/decompiler.
6. Emulate or flash to hardware; dynamically test each candidate with crafted input, watching for shell spawns, crashes, or unexpected file writes.
7. Confirm exploitability (PoC) with minimal, non-destructive payloads (e.g., `id`, `whoami`, writing a benign file) — don't go further than needed to prove impact.
8. Assess real-world exploitability: is it LAN-only, WAN-exposed, does it need auth, is it in a default config? This drives CVSS scoring and urgency.
9. Write it up: affected versions, root cause, PoC steps, CVSS vector, suggested fix (input sanitization function, auth check location, etc.) — see CVE-2024-53375's writeup style above for a good template.
10. Disclose per vendor policy or a standard 90-day disclosure timeline (CERT/CC, ZDI, or direct vendor security contact); request CVE assignment through MITRE, the vendor, or a CNA like ZDI if the vendor is unresponsive.

## Tools summary

`binwalk`, `unsquashfs`/`ubireader`, Ghidra/IDA (with MIPS/ARM support), Firmadyne/FirmAE, QEMU user-mode, `strace`/`ltrace`, Burp Suite/mitmproxy, `boofuzz`/AFL++, flashrom + SPI programmer, UART adapter.



Now let's go deep on each area you asked about.

## 1. Init scripts — what to look for

Init scripts (`/etc/init.d/*`, `/etc/rc.d/*`, `rcS`, `/etc/inittab`) tell you what the device actually _does_ at boot, which is often more revealing than the web UI.

- **Services bound to `0.0.0.0` vs `127.0.0.1`** — grep for `telnetd`, `dropbear`/`sshd`, `httpd`, `upnpd`. A telnetd bound to WAN with no auth is an instant finding. Check flags: `telnetd -l /bin/sh` (no login needed) is a classic backdoor pattern.
- **Command-line arguments embedded in scripts** — vendors sometimes bake debug flags, hardcoded ports, or `-d`/`-debug` switches directly into the startup line. This is exactly the pattern behind CVE-2025-7851: a prior patch left a debug path reachable via a file-existence check (e.g., checking for `/usr/sbin/image_type_debug`) rather than removing the functionality — so always check init scripts and daemons for conditional branches gated on file existence, NVRAM flags, or environment variables.
- **`iptables`/`nvram` calls at boot** — reveals default firewall posture: is the WAN interface actually blocked from the admin service, or does a rule quietly open it (common in "remote management" features that are on by default)?
- **World-writable directories created at boot** (`mkdir -p /tmp/... ; chmod 777`) — later abused for arbitrary file write → execution chains.
- **Cron jobs / watchdog scripts** — persistence mechanisms, and sometimes call out to scripts with attacker-influenced paths.
- **Environment variable exports** — API keys, cloud service tokens, or symmetric keys sometimes get exported here instead of read from a config file.

## 2. Binaries — vulnerable patterns to grep/hunt for

**Static grep pass (fast triage before opening Ghidra):**

```
grep -rE "system\(|popen\(|exec[lv]?p?\(|sprintf\(|strcpy\(|strcat\(|gets\(" .
```

Rank hits by whether the buffer/argument traces back to network input (HTTP params, NVRAM values set via web UI, UPnP/SOAP fields).

**In the disassembler, for each network-facing binary (`httpd`, `cgibin`, `upnpd`, SOAP/TR-069 daemons):**

- **Command injection sinks**: trace backward from `system()`/`popen()` calls to see if the argument is built via string concatenation with a parameter pulled straight from `getenv("QUERY_STRING")`, `cgiGetValue`, or NVRAM. This is the exact bug class behind CVE-2023-1389 (`country` field), CVE-2025-7850 (WireGuard private-key field), and CVE-2024-53375 (`ownerId` — should've been coerced with `tonumber()` in Lua but wasn't). The tell is always the same: user string reaches a shell-exec function without being validated against an allow-list or type-coerced.
- **Buffer overflows**: for `strcpy`/`sprintf`/`memcpy` calls, check the destination buffer's declared size (look at the stack frame in Ghidra's decompiler view — fixed-size local arrays are common in embedded C) vs. whether the source length is bounds-checked beforehand. HTTP header parsers, SOAP/UPnP XML parsers, and WPS/WiFi frame handlers are the highest-yield spots because they parse variable-length attacker-controlled data into fixed C buffers.
- **Format string bugs**: search for `printf(user_input)` / `syslog(user_input)` instead of `printf("%s", user_input)` — rarer now but still shows up in vendor SDK code that's been copy-pasted across product lines for a decade.
- **Integer issues**: length fields read from a packet/header used directly as a `malloc`/`memcpy` size without a sanity check — leads to heap overflow or under-allocation.
- **Auth check placement**: decompile the request-routing function (usually a big switch/dispatch table mapping CGI/RPC method names to handlers) and check whether the auth/session check happens _before_ the dispatch, or is duplicated per-handler (and thus can be missing from some). This is how "some endpoints require auth, others don't" bugs happen — very common in TR-069/UPnP handlers that reuse code paths from the authenticated web UI.

## 3. Web UI (CGI/Lua/PHP) — specifics

- Map **every** endpoint first (`grep -r "cgi_"` , list all `.lua`/`.cgi`/`.php` under the web root) before diving deep — you want full endpoint coverage, not just the login page.
- For each endpoint, ask: (1) does it check auth/session token, (2) does it sanitize parameters before use, (3) does it end up calling a shell, writing a file, or reading another user's data (IDOR).
- Lua-specific: look for missing type coercion (`tonumber()`) on parameters expected to be numeric — exactly the CVE-2024-53375 root cause — and for `os.execute()`/`io.popen()` calls.
- Check **CSRF protections** on state-changing GET/POST requests (change DNS, enable remote management, add admin user) — routers are notoriously weak here since many admin actions are simple GET requests with no token.
- Check the **firmware upload/update endpoint** specifically — does it verify a signature before flashing, or just check a magic-header/checksum? No-signature-verification is a critical finding since it lets an authenticated attacker (or a CSRF'd browser) push malicious firmware.

## 4. Hardcoded credentials — how to hunt

- `/etc/passwd` + `/etc/shadow`: look for entries beyond the obvious `admin` — vendor engineering/support accounts (`support`, `debug`, `oem`, `tech`) with an actual password hash rather than `*`/`!`. Crack with `john`/`hashcat` against rockyou — embedded MD5crypt hashes fall fast.
- `strings <binary> | grep -iE "passw|admin|secret|key"` across every binary, not just `httpd` — telnetd wrappers, VoIP daemons, and cloud-connect agents are common places vendors leave a static credential.
- Check **NVRAM defaults** (`nvram_default.txt` / compiled-in default table) for a static WiFi PSK, admin password, or API key that's identical across every unit shipped (this is what happened in the Zyxel P660HN-T / Billion 5200W-T cases above — a static "supervisor" account shipped in every unit, turning what should be an authenticated-only bug into something exploitable by anyone with the public default).
- Check for **hardcoded symmetric keys/certs** used for cloud communication or firmware signing — if the same private key is baked into every device, it can often be extracted once and reused against the whole product line.
- Diff credentials/keys **across firmware versions and across product lines** sharing an SDK — vendors often reuse the same default account or key across many models (explicitly called out in the Threatpost piece: "other brands and router models that use the tclinux variant are also affected").

## 5. Exposed services — what "secure" actually means here

For every listening service found (`netstat -tulpn` on a live/emulated device, or by grepping init scripts):

|Check|Why it matters|
|---|---|
|Bound to LAN-only vs WAN-reachable|WAN-exposed telnet/SSH/UPnP is the single biggest real-world exploitation vector (this is how Mirai-class botnets propagate)|
|Auth required at all|Some debug/diagnostic services skip auth entirely|
|Auth strength|Default creds, hardcoded creds, no rate-limiting/lockout (see GL.iNet AXT1800 — no brute-force protection on admin login, enabling automated credential attacks at high speed)|
|Protocol version / crypto|Old SSH/TLS versions, self-signed certs with no pinning, weak ciphers|
|UPnP/SOAP specifically|Historically the worst offender — check whether `WANIPConnection`/`AddPortMapping` actions are reachable from LAN-only or (misconfigured) WAN, and whether the SOAP XML parser validates input before use|
|TR-069/CWMP agent|If present, check whether it validates the ACS server identity and whether commands from the ACS are sanitized before local execution|

## 6. Putting it together: buffer overflow triage workflow

1. Identify all functions parsing variable-length network input (HTTP request line/headers, SOAP XML, UPnP SSDP, WPS frames, custom binary protocols on odd ports).
2. In Ghidra, for each, note every `char buf[N]` local and trace what writes into it.
3. Flag any write where the source length isn't checked against `N` before the copy (`strcpy`, unbounded `sprintf` with `%s`, `memcpy` with a length taken directly from the packet).
4. Confirm reachability: is this function called pre-auth, and is the buffer large enough that a realistic packet size overflows it?
5. Test dynamically: send a payload of increasing length (cyclic pattern via `pwntools`/`msf-pattern_create`) while attached with `gdbserver` (if you have a root shell) or under QEMU + `gdb` for emulated targets, and confirm you control `$pc`/`$ra`.
6. Assess exploitability realistically for the writeup: crash-only DoS vs. actual control-flow hijack — routers with NX/ASLR (increasingly common even in embedded Linux) may only yield a crash, which is still worth reporting but scored differently than RCE.



---

# Worked example

This is a great case to work through in full because the researcher documented every stage in detail. Here's the complete walkthrough of **CVE-2024-53375** (TP-Link Archer series, authenticated RCE), reconstructed as a methodology you can replicate.

## Stage 1: Obtaining & extracting firmware

TP-Link publishes firmware images publicly on their website — no dumping required for this vendor, unlike D-Link, which encrypts its firmware. This matters for your own practice: check whether your target vendor ships plaintext firmware before you invest in a hardware dump.

Extraction was the standard pipeline: `binwalk -e firmware.bin`, which pulled out a `squashfs-root` representing the full device filesystem.

## Stage 2: Recon the filesystem

The researcher went straight for the `www` folder since routers expose their admin interface there, and found a single `cgi-bin` entry point along with 221 Lua files under `/usr/lib/lua/luci` implementing the OpenWrt LuCI web framework. This matches what I described earlier — map the web root first, since that's where auth-adjacent logic lives.

## Stage 3: Emulation (partial, not full-system)

Rather than fighting full QEMU system emulation (which was crashing), the researcher chose targeted emulation of just the web-serving binary (`uhttpd`) using `qemu-arm-static`, copying the static QEMU binary into the extracted filesystem and using `chroot` to run it against the host kernel instead of emulating the firmware's own kernel.

Getting it working required solving cascading dependency errors — a very typical experience:

- `ubus` (the inter-process communication bus) failed to start, which was fixed by bind-mounting the host's `/dev` and `/proc` into the chroot, then manually launching `ubusd` inside an interactive chrooted shell.
- A follow-up `usock: not a directory` error was resolved by creating a missing `/var/run` directory inside the extracted filesystem.
- Once resolved, `uhttpd` served the actual TP-Link web login page at localhost:80.

**Lesson for your own practice:** partial emulation of just the target daemon is often faster and more reliable than full-system emulation — you only need the component you're auditing to run.

## Stage 4: Finding the sink (static analysis at scale)

Instead of manually reading 221 Lua files, the researcher first identified which functions the firmware actually uses to execute OS commands — `os.execute`, `subprocess.call`, `sys.fork_exec`, `fork_call` — then grepped for all call sites: `grep -rni "os.execute"`. This is the single highest-leverage technique in the whole methodology: **find every command-execution sink first, then work backward** to see which are reachable with attacker-controlled data, rather than reading code file by file.

This surfaced a hit in `avira.lua` — Avira antivirus integration code, ironic given that a security feature turned out to be the vulnerable component, in a file over 2000 lines long.

## Stage 5: Tracing the vulnerable data flow

The vulnerable function, `tmp_get_sites`, declared a local `ownerId` variable populated from `data.ownerId`, where `data` was itself parsed from JSON in `app_from.data`. That `ownerId` value was then passed directly into `os.execute` on the final line with no sanitization, validation, or type-checking — the developers had only left a comment (`--int`) noting it was _supposed_ to be an integer, which was never actually enforced.

This is the textbook injection pattern: **network input → JSON decode → variable assignment with an unenforced type assumption → shell exec.**

Next, the researcher traced _reachability_ — is this function actually callable? Grepping for cross-references to `tmp_get_sites` found it used in `lib/lua/luci/controller/admin/smart_network`, and because the file lived under an `admin` path, it required an authenticated session to reach. The endpoint was invoked via a request to `/admin/smart_network?form=tmp_avira` with `operation=getInsightSites`, and this outer `smart_network` handler redefined its own `tmp_get_sites` wrapper that called through to the real one in `avira.lua` — passing `app_from` straight through with no additional checking.

## Stage 6: Exploitation

To build a working PoC, the researcher reused existing public authentication-bypass/login code from another researcher (aaronsvk) rather than reinventing it, then crafted a request placing the injection payload in the `ownerid` field, with `date` set to any non-null value, `type` set to "visit" (required for the vulnerable path to trigger), and `startIndex`/`amount` populated to avoid null-parameter failures elsewhere in the handler.

The result was command execution as `root`, demonstrated by dumping `/etc/passwd` and `/etc/shadow` directly from the device.

**This is worth internalizing as a general exploitation pattern**: authenticated command injection in an embedded Lua/CGI handler almost always runs as root, because these daemons rarely drop privileges — there's no privilege-separation layer between the web server and the OS in most consumer router firmware.

## Stage 7: Mitigation assessment

The fix was simply to sanitize `ownerId` using Lua's `tonumber()` function, which would coerce or reject non-numeric injected input before it reached `os.execute`. When you write up your own findings, always propose the minimal, specific fix like this — it makes remediation trivial for the vendor and speeds up patch turnaround.

## Stage 8: Disclosure timeline (use this as your template)

The actual disclosure timeline ran: vulnerability identified Oct 3, 2024 → contacted ZDI Oct 4 → ZDI declined to acquire it Oct 10 → contacted TP-Link directly same day → TP-Link forwarded it for internal analysis Oct 12 → CVE requested from MITRE Oct 30 → TP-Link acknowledged the bug and shipped a fixed beta firmware Nov 8 → MITRE reserved CVE-2024-53375 on Nov 23.

Note the fallback path: ZDI/vendor-bounty programs won't take every bug (often because it doesn't meet their acquisition bar, not because it's invalid) — going direct to the vendor's PSIRT is a completely normal and effective fallback, and MITRE will reserve a CVE ID even without a CNA if the vendor engages.

## How to replicate this exact methodology on your own router

1. Pull firmware (vendor site, or your own SPI dump if unpublished).
2. `binwalk -e`, locate the web root and any scripting-language admin logic.
3. Enumerate this SDK's command-exec sinks first (varies by vendor — could be `system()` in C, `os.execute` in Lua, `shell_exec` in PHP).
4. `grep -rn` every sink, no manual file-by-file reading.
5. For each hit, trace the variable back to its origin — is it attacker-controlled (HTTP param, JSON body, header)? Is it validated/type-coerced before use?
6. Check reachability — is the containing file/route behind an auth path, and can you authenticate (even with a low-privilege account)?
7. Partially emulate just the relevant daemon with `qemu-<arch>-static` + `chroot` if you don't want to risk your only physical unit.
8. Build a minimal PoC — confirm with something read-only and non-destructive (`id`, `whoami`, or reading a non-sensitive file) before going further.
9. Write up root cause + minimal fix + CVSS vector.
10. Disclose: try ZDI/vendor bug bounty first, fall back to direct vendor PSIRT contact, request CVE via MITRE if the vendor is slow or unresponsive, document your timeline as you go (you'll need it for the eventual public writeup).

If you want, next time you have an actual firmware dump from the router you're practicing on, share what you find from the `grep` sweep of exec sinks and I can help you work through tracing reachability and building the PoC for your specific target.


# Articles

[Auth Bypass, Command Injection & Race Condition in GL.iNet GL-AXT1800Command injection in plugins.install_package RPC method, chained with brute-forceable admin auth to achieve full RCE](https://aleksazatezalo.medium.com/critical-command-injection-vulnerability-in-gl-inet-gl-axt1800-router-firmware-e6d67d81ee51)

[Router Vulnerabilities Disclosed in July Remain UnpatchedPedro Ribeiro's research on Zyxel P660HN-T and Billion 5200W-T: hardcoded admin accounts unlocking authenticated command injection in log/SNTP config pages](https://threatpost.com/router-vulnerabilities-disclosed-in-july-remain-unpatched/123115/)

[CVE-2026-5509: Archer Router Command Injection VulnerabilityAuthenticated command injection via shell metacharacters in a management endpoint parameter; detection guidance around unexpected shell child processes](https://www.sentinelone.com/vulnerability-database/cve-2026-5509/)

[CVE-2024-53375: TP-Link Archer Authenticated RCEFull writeup of discovery, exploitation and disclosure of an unsanitized ownerId parameter leading to command injection](https://thottysploity.github.io/posts/cve-2024-53375/)

[New TP-Link Router Vulnerabilities: A Primer on Rooting RoutersSystematic re-audit of TP-Link's LuCI Lua codebase after prior CVEs, finding new command injection and residual-debug-code root access bugs](https://www.forescout.com/blog/new-tp-link-router-vulnerabilities-a-primer-on-rooting-routers/)

[TP-Link Router Firmware Flaws Allow Root AccessDeeper breakdown of CVE-2025-7850/7851, including how an incomplete prior patch left a debug backdoor](https://www.computerbilities.com/critical-tp-link-router-vulnerabilities-cve-2025-7850-7851-root-access/)