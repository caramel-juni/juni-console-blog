---
title: Wazuh Agent Install Scripts
date: 2025-06-24
description: "up the waaazoo?"
toc: true
math: true
draft: false
categories: 
tags:
---

Recently, I've been playing with **[Wazuh](https://wazuh.com/)**, the *"Unified Open Source* `XDR` and `SIEM`."* My thoughts on the actual *platform* are still in a state of active formulation as I deploy and test the various capabilities... but all things considered, it's a **pretty cool product** and concept in general.

In any case - after running the various install commands, I thought it might be useful to wrap them up (for both Windows and Linux) into both interactive and silent installers, both for packaging via a deployment tool like InTune, as well as just for simplicity/ease of install.

> **Note:** *A working* [Wazuh server](https://documentation.wazuh.com/current/installation-guide/wazuh-server/index.html) *(and its corresponding, locally-accessible `IP`) must be configured for the agents to connect back to.*

> **Note:** *The below scripts are tested and working as of `24/06/2025`, and bundled up from the* [Wazuh Installation guide](https://documentation.wazuh.com/current/installation-guide/index.html). *Most of them contain hard-coded elements like `msi` version numbers, or `URLS` that are subject to change over time and thus should be adjusted accordingly before running.*

# Windows:
Downloads the `.MSI` from the `Wazuh` site and executes it, passing in deployment-specific parameters like Wazuh Server IP.
#### Silent Install Command (Windows):
- Run in an *administrator Powershell session.*
- ⚠️ Make sure to **replace the `IP` with that of your `WAZUH_MANAGER`** ⚠️
``` ps1
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.12.0-1.msi -OutFile $env:tmp\wazuh-agent; msiexec.exe /i $env:tmp\wazuh-agent /q WAZUH_MANAGER='172.16.66.6'; NET START Wazuh
```

#### Interactive Install (Windows):
- Run in an *administrator Powershell session.*
- Will be prompted for the `WAZUH_MANAGER IP` during the install, with logs available upon installation failure.
``` powershell
$WazuhManager = Read-Host "Enter the Wazuh Manager IP address or hostname (e.g., 172.16.66.6)"

$installerPath = "$env:TEMP\wazuh-agent.msi"
$logPath = "$env:TEMP\wazuh-install.log"

Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.12.0-1.msi" -OutFile $installerPath

# Run silent install with verbose logging
$arguments = "/i `"$installerPath`" /qn /l*v `"$logPath`" WAZUH_MANAGER=`"$WazuhManager`""
$process = Start-Process msiexec.exe -ArgumentList $arguments -Wait -PassThru

# Check exit code
if ($process.ExitCode -ne 0) {
    Write-Host "❌ Installation failed with exit code $($process.ExitCode). Showing log:"
    Get-Content $logPath
    exit $process.ExitCode
} else {
    Write-Host "✅ Installation succeeded."
    Start-Service -Name Wazuh
}

```

---
# Linux:
Adds the `Wazuh`GPG key & repository to local package manager database, downloads the package, passes in deployment-specific parameters like Wazuh Server IP, installs and enables the service.
#### Silent Install (Linux):
- Replace `apt` with your package manager of choice, depending on distro.
- ⚠️ Make sure to **replace the `IP` with that of your `WAZUH_MANAGER`** ⚠️
- Make the script executable with `chmod +x`
- Run with something like `sudo ./wazuh-install-script-silent.sh`:
``` bash
#!/bin/bash
set -euo pipefail

WAZUH_MANAGER="172.16.66.6"

sudo -v
sudo curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH -o /tmp/wazuh.gpg
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/wazuh.gpg --import /tmp/wazuh.gpg
sudo chmod 644 /usr/share/keyrings/wazuh.gpg
rm -f /tmp/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list > /dev/null
sudo apt-get update
sudo env WAZUH_MANAGER="$WAZUH_MANAGER" apt-get install -y wazuh-agent

sudo sed -i "s|<address>MANAGER_IP</address>|<address>$WAZUH_MANAGER</address>|" /var/ossec/etc/ossec.conf

sudo /var/ossec/bin/wazuh-control start

```

#### Interactive Install (Linux):
- Prompts for **linux distro**, **package manager**, and **Wazuh server IP** during the installation to tailor to your device.
- CLI logging to indicate progress as script runs.
- Make the script executable with `chmod +x` and run with something like `sudo ./wazuh-install-script-silent.sh`.
``` bash
#!/bin/bash
set -euo pipefail

echo "🔐 Requesting sudo access upfront..."
sudo -v

echo "📦 Wazuh Agent Installer"

# Prompt for distro type
echo "Select your Linux distribution type:"
select distro in "Debian/Ubuntu" "RHEL/CentOS/Fedora"; do
    case $distro in
        "Debian/Ubuntu") distro_type="debian"; break ;;
        "RHEL/CentOS/Fedora") distro_type="rpm"; break ;;
        *) echo "Invalid selection. Please choose a valid option." ;;
    esac
done
echo "✅ Distribution selected: $distro_type"

# Prompt for package manager explicitly (optional)
echo "Select your package manager:"
if [[ "$distro_type" == "debian" ]]; then
    pkg_manager="apt-get"
    echo "Automatically using apt-get for Debian/Ubuntu"
else
    select pm in "yum" "dnf"; do
        case $pm in
            yum|dnf) pkg_manager=$pm; break ;;
            *) echo "Invalid selection. Please choose yum or dnf." ;;
        esac
    done
fi
echo "✅ Package manager selected: $pkg_manager"

# Prompt for Wazuh Manager IP/hostname
read -rp "Enter the Wazuh Manager IP address or hostname (e.g., 10.0.0.2): " WAZUH_MANAGER
echo "✅ Wazuh Manager set to: $WAZUH_MANAGER"

# Step 1: Add Wazuh GPG key
echo "🔑 Adding Wazuh GPG key..."
tmp_key="/tmp/wazuh.gpg"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH -o "$tmp_key"
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/wazuh.gpg --import "$tmp_key"
sudo chmod 644 /usr/share/keyrings/wazuh.gpg
rm -f "$tmp_key"
echo "✅ GPG key added."

# Step 2: Add Wazuh repository
echo "➕ Adding Wazuh repository..."
if [[ "$distro_type" == "debian" ]]; then
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list > /dev/null
    echo "🔄 Updating package lists..."
    sudo apt-get update
elif [[ "$distro_type" == "rpm" ]]; then
    cat <<EOF | sudo tee /etc/yum.repos.d/wazuh.repo > /dev/null
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
fi

# Step 3: Install Wazuh agent with WAZUH_MANAGER environment variable
echo "⬇️ Installing Wazuh agent with $pkg_manager..."
# Export variable inline with install command
if [[ "$distro_type" == "debian" ]]; then
    sudo env WAZUH_MANAGER="$WAZUH_MANAGER" apt-get install wazuh-agent -y
else
    sudo env WAZUH_MANAGER="$WAZUH_MANAGER" $pkg_manager install wazuh-agent -y
fi

# Fix config file to set real manager IP
sudo sed -i "s|<address>MANAGER_IP</address>|<address>$WAZUH_MANAGER</address>|" /var/ossec/etc/ossec.conf

# Step 4: Start Wazuh agent using wazuh-control script
echo "🚀 Starting Wazuh agent service..."
sudo /var/ossec/bin/wazuh-control start

echo "✅ Wazuh agent installation and start complete!"
echo "ℹ️ You can configure the agent further by editing /var/ossec/etc/ossec.conf"


```

Happy scripting! 💕🐱