---
title: Setting up Powershell 7 + Custom Profile from Scratch
date: 2025-07-31
description: ""
toc: true
math: true
draft: false
categories: 
tags:
---

# *Finished Setup - a Sneak Peak:*
![](/posts/19/Pasted%20image%2020250731224132.png)

Appealing? Disgusting? Well, you can **completely change it, and customise to your heart's content** - so let's **dive into the basics, from scratch**!

---

One of these days, I'll **tame the ferociously verbose beast and learn how to properly use Powershell**, the long-feared and disgusted language by many a *nix user... but, unfortunately, a necessary evil to at least become familiar with. 

Today was not *exactly* "**that day**", but perhaps... the early morning leading *up* to "**the day**". Or something like that. I fell asleep before I learnt too many useful commands.

**Here's the process that I embarked on to setup & customise my Powershell 7 environment** in an attempt to make learning it *that* much more appealing.

**Yes, I know that this is a form of procrastination. But now it looks nicer to... Not Learn 💕🎓😎.**

---

# 1 - Installing Powershell 7:
- [Install guide](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5#msi) - `.msi` quick and easy.
- Set it as your **default profile in the Windows Terminal App**
  ![](/posts/19/Pasted%20image%2020250801001147.png)
  ![](/posts/19/Pasted%20image%2020250801001057.png)

---
# 2 - Installing `oh-my-posh` - a multi-shell prompt theme engine

Install `oh-my-posh` for windows --> [here](https://ohmyposh.dev/docs/installation/windows).
- **winget:** (recommended for its large package database & signature-verified installs) 
  `winget install JanDeDobbeleer.OhMyPosh --source winget --scope user --force`

Check it's in your `$PATH` *(& accessible via `oh-my-posh` in the `CLI` - may need a terminal refresh after install for it to be)* with:

``` powershell
[Environment]::GetEnvironmentVariable("PATH", "User") -split ';'
```

If not, run the following, &/or add it to your custom profile file (created further below!) if it doesn't persist:

``` powershell
$env:Path += ";$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\bin"
```

I also installed two commonly-used modules for **terminal icons**, & **auto-completion**. **These need to be enabled per-terminal-session**, done via your custom profile file (created further below!)

``` powershell
`Install-Module -Name Terminal-Icons,PSReadLine -Scope CurrentUser`
```

---
# 3 - Installing NerdFonts:

To support inline symbols, and all that cool stuff, installing a *[NerdFont](https://www.nerdfonts.com/font-downloads)* or two is a **must**. Can be done via downloading from their website, a package manager like Scoop or WinGet, or even just:

``` powershell
oh-my-posh font install
```
... to use the CLI to select & choose fonts to install!

Then, just open your Windows Terminal `Settings`, select your desired profile & set the font!

---

# 4 - Creating a Custom Profile:

Open & create your profile file with:
``` powershell
notepad $profile
```
Download a custom theme schema from [here](https://ohmyposh.dev/docs/themes) (download recommended, so you can customize it yourself), and save it somewhere you can readily access.

Inside your profile file, put something like the following - ensure to include, at the bare minimum, the first line pointing to your previously-downloaded custom theme schema!

``` powershell
# Sets (custom-downloaded) theme!
oh-my-posh init pwsh --config "C:\Users\USER\OneDrive\Documents\CODING\Powershell7\Config\wholespace.omp.json" | Invoke-Expression
# Auto-imports two important modules installed previously into every new session: 
Import-Module -Name Terminal-Icons
Import-Module -Name Terminal-Icons

```

**I personally also enable (within the Windows Terminal `Settings` for my Profile):**
- `Retro Terminal Effects`
- `Full Colour Emojis`
- ... `and a custom, blurred background image`
... for some extra fun!

# 5 - Customise the selected text highlighting colour:

As I found the default "white" highlighting to be a bit abrasive, I went to [this website](https://windowsterminalthemes.dev/) to get copy-paste-able `JSON` schemas for custom terminal themes, to then add to my Windows Terminal `settings.json` config file, accessible via the GUI: `Settings > Open JSON File`.

Just pop it under `schemes`, ensure it has a `"name"`, and then refer to the scheme's `"name"` in whatever profile you're using! In my case, its `Builtin Dark`:

![](/posts/19/Pasted%20image%2020250731235532.png)
![](/posts/19/Pasted%20image%2020250731235659.png)

And there you go! Hope this helps get people set up, rocking and rearing to go with a pretty, retro-looking custom Powershell 7 terminal...

![](/posts/19/Pasted%20image%2020250731224132.png)

***Time to throw some errors in style 😎.***

---

# 6 - Additional guides/help:
- [Customising Windows Terminal (with Scoop, but can be done via WinGet)](https://medium.com/@anitjha31/elevate-your-windows-powershell-my-personal-customization-guide-b2dbbe9d766c)
- [Windows Terminal Themes - in `JSON`](https://windowsterminalthemes.dev/)
- [NerdFonts](https://www.nerdfonts.com/font-downloads)