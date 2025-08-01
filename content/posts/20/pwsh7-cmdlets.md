---
title: Powershell 7 Back2Basix Cheatsheet - Cmdlets, Aliases, &... Get'n-Help!
date: 2025-08-01
description: ""
toc: true
math: true
draft: false
categories:
  - powershell
tags:
---

The constitutes as the first of (perhaps a few) posts within which I plan to document the highlights/learnings of my foray into the mythical, wonderous world of **`Powershell (7)`**, alongside the troubles and toils that I will (inevitably) encounter on the way there.

*I'll try and keep the depiction of said inevitable toils as brief and to myself as possible; however, containing such a beast fully is, I suspect, more than a little beyond me...*

---

# What's a Cmdlet?
A lightweight script (in a `Verb-Noun` form) that performs a function. Can be installed, or come pre-installed (typically on *Windows*).

# What's an Alias?
Shorthand notations for cmdlet. *(try to limit their use within scripts, as can make reading them harder)* Useful for quickly referring to (legendarily verbose) Powershell commands, as well as setting custom shortcuts to open binaries (jump down to the **bottom of the article** to see that).

---

## Navigating the Windows CLI (Useful Keybinds)

| Keybind                      | Action                                                                                  |
| ---------------------------- | --------------------------------------------------------------------------------------- |
| `Ctrl + ->` / `Ctrl <-`      | Move one word to the right/left                                                         |
| `Home` / `End`               | Jump cursor to beginning/end of buffer (line)                                           |
| `Ctrl + Home` / `Ctrl + End` | Delete all characters from the cursor to the start (`Home`) or `End` of the line.       |
| `Esc`                        | Clears current line                                                                     |
| `Ctrl + A`                   | Selects all text (can then delete/copy)                                                 |
| `Ctrl + L`                   | Clears screen                                                                           |
| `Ctrl + Enter`               | Continue typing on next line                                                            |
| `Ctrl + Z`                   | Undo last (terminal) action                                                             |
| `Ctrl + R`                   | Reverse keywoard search through command history (`Tab` to select the previewed command) |

---

# PowerShell 7 Cheatsheet: System Admin & Ethical Hacking (aka "poking around")

Below, you can find a quick reference for essential PowerShell 7 commands, including their common aliases and their equivalents in the Linux shell, as well as some handy-dandy examples! 
- *But you can always find more by running `Update-Help` and then `Get-Help <CMDLET> -Examples` or `-Full` !*

# Most Useful Cmdlets in a pinch:

| PowerShell Cmdlet                                        | Common Alias(es) | Description                                                                   | Linux Equivalent |
| -------------------------------------------------------- | ---------------- | ----------------------------------------------------------------------------- | ---------------- |
| `Get-Help <cmdlet-name>` `-Full`, `-Online`, `-Examples` | `help`, `man`    | Displays help information about cmdlets.                                      | `man`, `tldr`    |
| `Get-Command`                                            | `gcm`            | Gets all commands installed on the computer.                                  | `compgen -c`     |
| `Update-Help` `-Module`                                  |                  | Downloads & installs all/newest Help files for `PS` modules on your computer. |                  |

# Navigation & File System

| PowerShell Cmdlet | Common Alias(es)                          | Description                                               | Linux Equivalent                       |
| ----------------- | ----------------------------------------- | --------------------------------------------------------- | -------------------------------------- |
| `Get-Location`    | `gl`, `pwd`                               | Gets the current working directory.                       | `pwd`                                  |
| `Set-Location`    | `sl`, `cd`, `chdir`                       | Changes the current working directory.                    | `cd`                                   |
| `Get-ChildItem`   | `gci`, `ls`, `dir`                        | Lists files and directories in a location.                | `ls`                                   |
| `Get-Content`     | `gc`, `cat`, `type`                       | Displays the content of a file.                           | `cat`                                  |
| `New-Item`        | `ni`                                      | Creates a new item (file or directory).                   | `touch` (file), `mkdir` (directory)    |
| `Copy-Item`       | `cpi`, `cp`, `copy`                       | Copies an item from one location to another.              | `cp`                                   |
| `Move-Item`       | `mi`, `mv`, `move`                        | Moves an item from one location to another.               | `mv`                                   |
| `Remove-Item`     | `ri`, `rm`, `del`, `erase`, `rd`, `rmdir` | Deletes an item (file or directory).                      | `rm` (file), `rmdir` (empty directory) |
| `Rename-Item`     | `rni`, `ren`                              | Renames an item.                                          | `mv`                                   |
| `Select-String`   | `sls`                                     | Searches for text in strings and files (similar to grep). | `grep`                                 |
| `Get-FileHash`    |                                           | Computes the hash of a file.                              | `md5sum`, `sha256sum`, etc.            |

#### Examples (File Creation):
`New-Item`:
- New File with content: `New-Item -ItemType "File" -Path . -Name "testfile1.txt" -Value "This is a text string."`
- New Directory: `New-Item -ItemType "Directory" -Path "C:\ps-test\scripts"`
- New (multiple) Files: `New-Item -ItemType "File" -Path "C:\ps-test\test.txt", "C:\ps-test\Logs\test.log"`

*... for others, just run `Get-Help <CMDLET> -Examples` !*

---
# System Information & Management:

| PowerShell Cmdlet                   | Common Alias(es)      | Description                                                                         | Linux Equivalent                |
| ----------------------------------- | --------------------- | ----------------------------------------------------------------------------------- | ------------------------------- |
| `Get-Process`                       | `gps`, `ps`           | Gets the processes running on the local computer.                                   | `ps`                            |
| `Stop-Process`                      | `spps`, `kill`        | Stops one or more running processes.                                                | `kill`                          |
| `Get-Service`                       | `gsv`                 | Gets the services on a local or remote computer.                                    | `systemctl`, `service`          |
| `Start-Service`                     | `sasv`                | Starts one or more stopped services.                                                | `sudo systemctl start`          |
| `Stop-Service`                      | `spsv`                | Stops one or more running services.                                                 | `sudo systemctl stop`           |
| `Get-History`                       | `ghy`, `h`, `history` | Gets a list of commands entered in the current session.                             | `history`                       |
| `Get-WmiObject` / `Get-CimInstance` | `gwmi`, `gcim`        | Gets instances of WMI/CIM classes (for system info).                                | Various (e.g., `lscpu`, `lshw`) |
| `Get` / `Set-ExecutionPolicy`       |                       | Sets the PowerShell script execution policy (who can execute/run scripts, whether ) | `chmod +x` (on a script)        |
| `Invoke-RestMethod`                 | `irm`                 | Sends an HTTP(S) request to a RESTful web service, & parses response                | `curl`, `wget`, `http`          |
| `Invoke-Expression`                 | `iex`                 | Executes a string as a PowerShell expression or command.                            | `eval`, `bash -c`, `source`     |

---
# Networking & "poking around" (lol)

| PowerShell Cmdlet                         | Common Alias(es)      | Description                                              | Linux Equivalent          |
| ----------------------------------------- | --------------------- | -------------------------------------------------------- | ------------------------- |
| `Test-Connection`                         | `ping`, `tnc`         | Sends ICMP echo request packets to network hosts.        | `ping`                    |
| `Test-NetConnection`                      |                       | Displays diagnostic information for a connection.        | `nc`, `nmap`, `ss`        |
| `Resolve-DnsName`                         |                       | Performs a DNS query.                                    | `dig`, `nslookup`, `host` |
| `Get-NetTCPConnection`                    |                       | Gets current TCP connections.                            | `netstat -at`, `ss -t`    |
| `Invoke-WebRequest`                       | `iwr`, `curl`, `wget` | Gets content from a web page on the Internet.            | `curl`, `wget`            |
| `Invoke-RestMethod`                       | `irm`                 | Sends an HTTP or HTTPS request to a RESTful web service. | `curl`                    |
| `New-Object System.Net.Sockets.TCPClient` |                       | Creates a TCP client to connect to a port.               | `nc`                      |
| `Invoke-Command`                          | `icm`                 | Runs commands on local and remote computers.             | `ssh`                     |
| `Invoke-Expression`                       | `iex`                 | Executes a string as a command (use with caution).       | `eval`                    |
| `[System.Convert]::ToBase64String`        |                       | Encodes data into a Base64 string.                       | `base64`                  |


---
# Alias Use Cases: 
### Opening Files with custom binaries in `Pwsh`:
Use `Set-Alias` to set an alias (like `npp`) to reference an executable/installed app, like:
- `New-Alias npp "C:\Program Files\Notepad++\notepad++.exe"`
*Can alternatively set the path to the binary in your `PATH` (`Windows + S`, "Environment Variables"), but will have to match the name of the binary exactly to run.*

This allows various apps to open/perform actions on files from the CLI:
- `code`/`npp` `"C:\Users\juni\text.txt"` --> **opens a file in the given application (if in `PATH`/set as alias)**

| `code` / `npp` `"C:\Users\juni\text.txt"` | opens a file in the given application (if in `PATH`/set as alias) |
| ----------------------------------------- | ----------------------------------------------------------------- |
