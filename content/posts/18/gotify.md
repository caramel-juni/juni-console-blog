---
title: Setting up Gotify to monitor TrueNAS Apps & Alerts
date: 2025-07-15
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
3. Connect to the Gotify instance's URL & login, changing admin password and creating an "App" (so you can copy + paste and use its Token to send notifications to it) ![](/posts/18/gotifyappcreate.png)
4. Make Gotify server publicly accessible behind `nginx` reverse proxy by creating an entry in `nginx proxy manager` ![](/posts/18/nginxentry.png)
5. Install [Gotify's Android app](https://github.com/gotify/android)
6. Connect the app to your publicly accessible Gotify URL: https://gotify.juni-lab.xyz
7. Using the app's token from step 3, test a notification with the command (from anywhere):
```bash
curl "https://gotify.url/message?token=APPTOKEN" -F "title=cool title" -F "message=cooler message" -F "priority=5
```
...and then, voila. notifications galore.

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
   ![](/posts/18/truenasalertsettings.png)
3. Save, then send a test alert, and voila!
   ![](/posts/18/gotifydone.png)
   

# Jellyfin webhook integration settings:

1. Create a new app in Gotify for Jellyfin: 
![](/posts/18/jellyfinapp.png)
2. Install the [Jellyfin Webhook plugin](https://github.com/crobibero/jellyfin-plugin-webhook) on your Jellyfin server via the WebUI, and restart it to apply changes.
3. Go into the plugin settings, and press `Add Gotify Destination`.
4. Select **which alerts you want sent**, and fill in the relevant fields:
  - The Server `URL`: `https://your-jellyfin-server.com`
  - Gotify's BASE webhook `URL`: `https://your-gotify-url.com` (no trailing `/`'s)
  - Choose whether to select `Send App Properties` (**not recommended**, does not play nice with Gotify by default, and will **override handlebars template below**)
  - Select `Trim leading and trailing whitespace from message body before sending` to make messages cleaner.
  - Use the [Handlebars](https://handlebarsjs.com/guide/) Template engine to customise alert notifications. See also some samply Gotify-specific templates [here](https://github.com/jellyfin/jellyfin-plugin-webhook/tree/master/Jellyfin.Plugin.Webhook/Templates). For example, my configuration for the relevant alerts in my setup is below:
  ``` json
  {
  "title": "{{#if_equals NotificationType 'AuthenticationSuccess'}}✅ Login Success: {{NotificationUsername}}{{else if_equals NotificationType 'AuthenticationFailure'}}🚫 Login Failed: {{NotificationUsername}}{{else if_equals NotificationType 'UserCreated'}}👤 User Created: {{NotificationUsername}}{{else if_equals NotificationType 'UserUpdated'}}✏️ User Updated: {{NotificationUsername}}{{else if_equals NotificationType 'UserLockedOut'}}🔒 User Locked Out: {{NotificationUsername}}{{else if_equals NotificationType 'UserPasswordChanged'}}🔑 Password Changed: {{NotificationUsername}}{{else if_equals NotificationType 'TaskCompleted'}}✅ Task Completed: {{Name}}{{else}}🔔 {{NotificationType}}{{/if_equals}}",
  "message": "**User:** {{NotificationUsername}}\n**Type:** {{NotificationType}}\n**Client:** {{Client}}\n**Device:** {{DeviceName}}\n**IP:** {{RemoteEndPoint}}\n**Server:** {{ServerName}}",
  "priority": {{#if_equals NotificationType "AuthenticationFailure"}}5{{else}}3{{/if_equals}},
  "extras": {
    "client::display": {
      "contentType": "text/markdown"
    }
  }
  ```
  - Your Gotify `Jellyfin App Token` (==IMPORTANT==)
  - `Priority Type` for messages. 


**Then, just click `Save`, and you're done!** Check the jellyfin `logs` to troubleshoot any malformed URLs/templates, and if in doubt, send a `curl` request to see whether its the gotify app or jellyfin that's the issue:
   **Sample `curl` request:**

```bash
  curl -X POST "http://gotify.url/message?token=TOKENHERE" \
  -H "Content-Type: application/json" \
  -d '{"title":"Jellyfin","message":"Test alert!","priority":4}'
```
