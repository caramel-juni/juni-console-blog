---
title: Setting up Gotify to monitor TrueNAS Apps & Alerts
date: 2025-07-14
description: ""
toc: true
math: true
draft: false
categories: 
tags:
---

*Running within proxmox LXC (so can be notified even if TrueNAS fails):*

1. On your Proxmox `LXC`, install `docker-compose` and create a new directory with a `docker-compose.yml`:
```yml
services:
  gotify:
    image: gotify/server
    ports:
      - 8081:80
    environment:
      GOTIFY_DEFAULTUSER_PASS: 'theGOAT3fy'
    volumes:
      - './gotify_data:/app/data'
    # to run gotify as a dedicated user, change to UID:GID:
    user: "1000:1000"
```

2. To run gotify as a dedicated user:
   `id myuser`
   `sudo chown -R UID:GID ./gotify_data`

3. Connect to the Gotify instance's URL & login, changing admin password and creating an "App" (so you can copy + paste and use its Token to send notifications to it) ![](Screenshot%202025-07-15%20at%2012.52.26%20am.png)

4. Make Gotify server publicly accessible behind `nginx` reverse proxy by creating an entry in `nginx proxy manager` ![](Screenshot%202025-07-15%20at%2012.39.22%20am.png)
5. Install [Gotify's Android app](https://github.com/gotify/android)
6. Connect the app to your publicly accessible Gotify URL: https://gotify.juni-lab.xyz
7. Using the app's token from step 3, test a notification with the command (from anywhere):
```bash
curl "https://gotify.juni-lab.xyz/message?token=APPTOKEN" -F "title=cool title" -F "message=cooler message" -F "priority=5
```
and then, voila. notifications galore.

# To setup TrueNAS notifications to be sent to Gotify:
(upon reaching a certain notification level - like `WARNING` or similar):

1. create custom app for monitoring in TrueNAS (via `YAML`):
``` toml
services:
 gotify-truenas:
   environment:
     - GOTIFY_URL=http://URL:port
     - GOTIFY_TOKEN=[TrueNAS-Token-In-Gotify]
   image: ghcr.io/ztube/truenas-gotify-adapter:main
   network_mode: host
   restart: unless-stopped
```

2. set up alert settings to use this webhook, & set desired alert level severity:
   **Webhook URL:** `http://localhost:31662`
   **Type:** `Slack`
   ![](Screenshot%202025-07-15%20at%2012.43.37%20am.png)
3. Save, then send a test alert, and voila!
   ![](Screenshot%202025-07-15%20at%2012.56.20%20am.png)
   