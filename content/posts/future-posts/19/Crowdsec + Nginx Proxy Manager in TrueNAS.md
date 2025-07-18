---
title: ""
date: 2025-07-17
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

To set up crowdsec in future, likely need to deploy all inside one docker instance (nginx/traefik + crowdsec) - [see advice here](https://forums.truenas.com/t/hosting-domain-via-truenas-best-practices-nginx-traefik-or-caddy/43524/15).
- https://www.youtube.com/watch?v=qnviPAMwAuw
- https://www.simplehomelab.com/crowdsec-docker-compose-1-fw-bouncer/

API KEY for crowdsec bouncer: `IRskLoiuRP715MtqxSVM01REeT111rKDI7LpszZstOQ`

![](https://docs.crowdsec.net/img/simplified_SE_overview.svg)

My final `docker-compose` file, which installs both the:

- [Crowdsec Security Engine (docker)](https://docs.crowdsec.net/u/getting_started/installation/docker) (makes the decisions)
- [Crowdsec docker bouncer wrapper](https://github.com/shgew/cs-firewall-bouncer-docker) (enforces)

``` yaml
services:
  crowdsec:
    environment:
      - COLLECTIONS=crowdsecurity/nginx-proxy-manager crowdsecurity/nginx
      - PUID=568
      - GUID=568
    image: crowdsecurity/crowdsec
    ports:
      - '9090:8080'
    restart: always
    volumes:
      - /mnt/rei/configs/crowdsec-config/acquis.yaml:/etc/crowdsec/acquis.yaml
      - /mnt/tank/configs/nginxproxy/logs:/var/log/nginx
      - /mnt/rei/configs/crowdsec:/var/lib/crowdsec/data
  crowdsec-firewall-bouncer:
    cap_add:
      - NET_ADMIN
      - NET_RAW
    container_name: crowdsec-firewall-bouncer
    environment:
      - API_URL=http://127.0.0.1:9090
      - API_KEY=IRskLoiuRP715MtqxSVM01REeT111rKDI7LpszZstOQ
    image: ghcr.io/shgew/cs-firewall-bouncer-docker:latest
    network_mode: host
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    volumes:
      - >-
        /mnt/rei/configs/crowdsec/crowdsec-firewall-bouncer.yaml:/config/crowdsec-firewall-bouncer.yaml:ro
      - /etc/localtime:/etc/localtime:ro

```
(The `>-` is  `YAML`’s **folded block style** indicator, which means it treats the line as a single continuous string, folding newlines into spaces.)
(Separate any `collections` (parsers) you want enabled & installed by default in the environment variable `COLLECTIONS=XXXX`, separating each with a space.)

uses:


with custom config:

`/mnt/rei/configs/crowdsec-config/acquis.yaml`

```
filenames:
  - /var/log/nginx/*.log

labels:
  type: nginx-proxy-manager
```

Check that `type: nginx-proxy-manager` if you want to parse `nginx-proxy-manager` style logs!! is different from `type: nginx` !! (thank you, [source](https://discourse.crowdsec.net/t/setting-up-crowdsec-with-nginx-proxy-manager/1096/5))


to see whether it's parsing the logs correctly, go into main `crowdsec` container and run:

`cscli metrics`

If it's not parsing (e.g. you see lots of `Lines unparsed`), ensure it can parse the type of logs (for me, nginx reverse proxy logs) by ensuring the corresponding parser is installed. `nginx-proxy-manager` log parser inside the container.

To test, you can also do this via the trueNAS CLI, docker-ing into the crowdsec container with:

`sudo docker ps | grep crowdsec` --> finds the container name, in my case, `ix-crowdsec-crowdsec-1`
```
juni-nas@truenas /mnt/rei/configs/crowdsec-config
 % sudo docker ps | grep crowdsec                                                                              
37322ccb9a35   crowdsecurity/crowdsec                                           "/bin/bash /docker_s…"   20 minutes ago   Up About a minute      0.0.0.0:9090->8080/tcp, [::]:9090->8080/tcp                                                                                               ix-crowdsec-crowdsec-1                                                     
```

installing the collection (& parser) with:
`sudo docker exec -it ix-crowdsec-crowdsec-1 cscli collections install crowdsecurity/nginx-proxy-manager`

ensure it's enabled, if not, run:
`sudo docker exec -it ix-crowdsec-crowdsec-1 cscli collections enable crowdsecurity/nginx-proxy-manager`

then `sudo docker restart ix-crowdsec-crowdsec-1` to apply changes.

then, go back into the `crowdsec` container and run:

`cscli collections list`

ensure you have a line like:

` crowdsecurity/nginx-proxy-manager  ✔️  enabled  0.1      /etc/crowdsec/collections/nginx-proxy-manager.yaml`

**HOWEVER - this will not persist upon *complete* container reboots** - like "restarting" the custom app in the TrueNAS GUI. To permanently enable these collections on boot, add them to the `docker-compose.yaml`'s environment variable as mentioned before:
- `COLLECTIONS=crowdsec/collection-one crowdsec/collection-two`


now after running `cscli metrics` within the main crowdsec container, you should see all the lines being both read ***and parsed*** correctly! 
![](Screenshot%202025-07-16%20at%2011.54.58%20pm.png)
Importantly, check that all of your desired collection's logs (`child-crowdsecurity/nginx-proxy-manager-logs`) are being parsed correctly:
![](Screenshot%202025-07-16%20at%2011.56.15%20pm.png)
(`nginx` still won't be, as we're not using that log format but the parser is still installed - can always uninstall it using a similar method to above for cleanup)

## How Crowdsec Parses Logs (and why there are so many`nginx-logs` hits):

Even though we set `type: nginx-proxy-manager` in the `acquis.yaml` configuration file, there are still hits in `http-logs` and `nginx-logs`. 

This is because CrowdSec uses a **modular parser chain**, which works along the lines of: 
1. Your defined `type` parser (`nginx-proxy-manager` for me) **normalizes your access logs** into structured `http_event`s, based on that tooling's log format.
2. *Then*, these structured events are **passed to child parsers** like `http-logs` and `nginx-logs` (plus any others installed/specified at runtime).
3. This layered approach allows CrowdSec to apply **generic `HTTP` and `Nginx` detection scenarios** (e.g., bruteforce, scans) on top of normalized `NPM` logs.

### Parser flow diagram:
```
Raw NPM Logs (via acquis.yaml, type: nginx_proxy_manager)
        │
        ▼
Parser: crowdsecurity/nginx-proxy-manager-logs
        │ emits http_event
        ▼
Parser: crowdsecurity/http-logs
        │
        ▼
Parser: crowdsecurity/nginx-logs
        │
        ▼
Scenarios: http-bf, http-probing, path traversal, etc.
```

## Other logging things to check:
### Logging enrichment is working:

![](Screenshot%202025-07-17%20at%2011.50.11%20pm.png)
- Enriched data with date + geoip
- Passed into at least one HTTP scenario (crawl detection)
### **Crowdsec Bouncer is working:** 
If you can see any successful CrowdSec decisions are being streamed to the bouncer - it means that any **offending IPs are being blocked**, or decisions taken against them:
![](Screenshot%202025-07-17%20at%2011.51.32%20pm.png)

## Connecting to the Crowdsec Console (UI)

To view all this in a pretty UI, you have (pretty much) three options:
1. Use the [Crowdsec Cloud Console UI](https://docs.crowdsec.net/u/getting_started/post_installation/console) (*my chosen method*)
2. Spin up a (metabase) dashboard within the container with `cscli dashboard start` (*but can consume a significant chunk of resources and is far less pretty*)
3. Connect the agent to an external Grafana dashboard (such as one here)

I went with option (1.), which was so incredibly seamless it's not really worth writing up. Sign up for an account, then go to **[Security Engines > Installation](https://app.crowdsec.net/security-engines/setup?distribution=linux)** and (if you've followed up to this point), just follow **Step 3**: run `cscli console enroll -e context <crowdsec-generated-token>` within your `crowdsec` agent container to connect it, and accept the connection via the Crowdsec console WebUI.

Then, after a full container restart and about a 5-10min wait, all of your logs + detection agent/bouncer decisions should populate the console!
![](80602.png)

![](Screenshot%202025-07-18%20at%2012.05.33%20am.png)

Now go forth: subscribe to some [blocklists](https://app.crowdsec.net/blocklists) (will take up to 2hrs to apply), and have a play around!

## Alerting via Gotify:
- [ ] tuning scenarios, alerting (like Gotify or email), reviewing banned IPs


## Confirming whether IPs are getting blocked (via manual testing)
- [ ] [health checks](https://docs.crowdsec.net/u/getting_started/health_check)
- [ ] Confirm IPs are actually blocked (use nft get set ... or try from a test VM)


## Progress Checklist:
- [x] nft list ruleset shows crowdsec tables and chains
- [x] docker logs show decisions being applied
- [x] trying to set up bouncer to parse nginx log files correctly - look [here](https://www.simplehomelab.com/crowdsec-docker-compose-1-fw-bouncer/)
	- [x] https://discourse.crowdsec.net/t/setting-up-crowdsec-with-nginx-proxy-manager/1096/5
- [x] Block decisions in CrowdSec UI / logs result in IPs being added
- [x] dashboard linking to