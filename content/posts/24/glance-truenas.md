---
title: Setting up Glance Self-Hosted Homepage (TrueNAS Scale)
date: 2025-08-18
description: ""
toc: true
math: true
draft: false
categories:
  - glance
tags:
  - trueNAS
  - glance
  - homepage
  - self-hosted
---
Installing the super cool [glance](https://github.com/glanceapp/glance) homepage within a custom TrueNAS app (`TrueNAS SCALE Fangtooth 25.04.01`) via `YAML`.

# Steps:
1. Within the TrueNAS `GUI`, create a dataset `glance`, with child datasets (or folders via the CLI, just make sure permissions are set so `apps` user can access it) of `config` and `assets`.
2. Using the TrueNAS CLI to be safe, `cd` into the newly-created folder & run `curl` to [generate the startup folder & file structure](https://github.com/glanceapp/glance/tree/main?tab=readme-ov-file#installation). 
   (*May not be needed as was unclear whether it's generated on image pull, but did this to be safe:*)
   
   `cd /mnt/rei/configs/glance`
   
   `curl -sL https://github.com/glanceapp/docker-compose-template/archive/refs/heads/main.tar.gz | tar -xzf - --strip-components 2`
3. After confirming the files were pulled and are all owned by the `apps` user (can use `sudo chown -R apps /glance`), or do this via the `GUI`, create a new **Custom App** (via. `Apps > Discover Apps > Custom App` in the `TrueNAS GUI`). Put something like the below `YAML` file in it, replacing the file paths for `env_file` and `volumes` (path before the `:`) with the ones created in step 2:
   **`TrueNAS Custom App YAML File`:**
  ``` yaml
  services:
    glance:
      container_name: glance
      env_file: /mnt/rei/configs/glance/.env
      image: glanceapp/glance
      ports:
        - '8180:8080' # Replace 8180 with a free port in your homelab
      restart: unless-stopped
      volumes:
        - /mnt/rei/configs/glance/config:/app/config
        - /mnt/rei/configs/glance/assets:/app/assets
        - /etc/localtime:/etc/localtime:ro
        # Optionally, also mount docker socket if you want to use the docker containers widget
        - /var/run/docker.sock:/var/run/docker.sock:ro
    # Add custom DNS servers for the container below (as some widgets can time out due to rate limiting if you use custom DNS servers like AdGuard)
    dns:
        - 1.1.1.1
        - 8.8.8.8

  ```


Then... just deploy the app, and if all is well, it should just spin up! 

You can view & troubleshoot any config-related errors via the TrueNAS `CLI` - find your `glance` docker container names with something like `sudo docker ps | grep "glance"`), then view logs with:
- `less /var/log/app_lifecycle.log` **(TrueNAS custom app deployment errors)**
- `sudo docker logs -f glance` **(for `glance`-specific config errors, like inside `glance.yml` or `home.yml`)**


You'll probably run into a few of these as you tweak the `YAML` file, but it'll get easier over time!


Here are my `glance.yml` (where all the server-level configs lie) and `home.yml` (your dashboard layout/config) files, as of the time of writing:

---
# `glance.yml`:

``` yaml
server:
  assets-path: /app/assets
  proxied: true # Required if hosting behind a reverse proxy, like nginx proxy manager

theme:
  # Note: assets are cached by the browser, changes to the CSS file
  # will not be reflected until the browser cache is cleared (Ctrl+F5)
  custom-css-file: /assets/user.css
  # Add simple theming below, or define custom CSS file above
  background-color: 225 14 15
  primary-color: 265 89 79
  contrast-multiplier: 1.3

pages:
  # It's not necessary to create a new file for each page and include it, you can simply
  # put its contents here, though multiple pages are easier to manage when separated
  - $include: home.yml

auth:
  secret-key: secretkeyhere
  users:
    juni:
      password-hash: $2a$...
```

**To setup & [use authentication](https://github.com/glanceapp/glance/blob/main/docs/configuration.md#environment-variables)** (say, when hosting the dashboard publicly behind a reverse proxy), select your custom app & enter the `glance` container `shell` using the TrueNAS `GUI`.

Once inside, generate the secret key for your desired user with `./glance secret:make`. Copy the output and paste it as the value for `secret-key:` in `glance.yml` above, as well as specifying a username (`juni` above),

You can alternatively declare this key (or any other value, for that matter) as an [environment variable](https://github.com/glanceapp/glance/blob/main/docs/configuration.md#environment-variables) inside `.env` (a hidden file in `.../glance/config`) and reference these in `glance.yml` with `${ENV_NAME}`.

I also opted for a [hashed password](https://github.com/glanceapp/glance/blob/main/docs/configuration.md#using-hashed-passwords), which can be generated with your *actual* user's password inside the container shell with the command `./glance password:hash mysecretpassword`.

# `home.yml`:

``` yml
- name: Home
  # Optionally, if you only have a single page you can hide the desktop navigation for a cleaner look
  # hide-desktop-navigation: true
  columns:
    - size: small
      widgets:
        - type: server-stats
          servers:
            - type: local
              name: TrueNAS

        - type: videos
          style: vertical-list
          collapse-after: 12
          channels:
            - UCR-DXc1voovS8nhAvccRZhg # Jeff Geerling
            - UCsBjURrPoezykLs9EqgamOA # Fireship
            - UCchWU8ta6L-Dy3rGIxPINzw # Reignbot
	        #...


    - size: full
      widgets:

        - type: search
          search-engine: duckduckgo
          autofocus: true
          new-tab: true
          bangs:
            - title: YouTube
              shortcut: "!yt"
              url: https://www.youtube.com/results?search_query={QUERY}
            - title: ChatGPT
              shortcut: "!ai"
              url: https://chatgpt.com/?q={QUERY}
            - title: TrueNAS
              shortcut: "!tn"
              url: https://192.168.0.2:999
            - title: 1337x
              shortcut: "!tor"
              url: https://1337x.to/search/{QUERY}/1/
            - title: TorrentLeech
              shortcut: "!tl"
              url: https://www.torrentleech.org/torrents/browse/index/query/{QUERY}

        - type: monitor
          cache: 1m
          title: Self-Hosted Services
          sites:
            - title: Immich
              url: https://immich.juni-lab.xyz
              icon: sh:immich
            - title: NRP (local)
              url: http://192.168.0.2:20202
              icon: sh:nginx-proxy-manager
              #...

        - type: group
          define: &shared-properties
            type: rss
            limit: 10
            collapse-after: 5
            cache: 3h
          widgets:
          - title: INDIEWEB
            style: vertical-list
            feeds:
              - url: https://selfh.st/rss/
                title: selfh.st
              #...
            <<: *shared-properties
          - title: FRIENDS
            style: vertical-list
            feeds:
              - url: https://marisabel.nl/feeds/combined.php
                title: Marisabel
              #...
            <<: *shared-properties

        - type: group
          widgets:
            - type: reddit
              subreddit: archlinux
              show-thumbnails: true


    - size: small
      widgets:

        - type: group
          widgets:
            - type: hacker-news
              collapse-after: 4

        - type: lobsters
          sort-by: hot
          tags:
            - privacy
            - security
            - linux
            - reversing
            - nix
          limit: 15
          collapse-after: 6

- name: Homelab
  # Second page for just homelab stuff
  columns:

    - size: full
      widgets:
        - type: server-stats
          servers:
            - type: local
              name: TrueNAS
        - type: monitor
          cache: 1m
          title: Self-Hosted Services
          sites:
            - title: Immich
              url: https://immich.juni-lab.xyz
              icon: sh:immich
            - title: NRP (local)
              url: http://192.168.0.2:20202
              icon: sh:nginx-proxy-manager
              #...
```



