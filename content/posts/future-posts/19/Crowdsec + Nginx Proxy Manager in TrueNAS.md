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

docker-compose file:

``` yaml
services:
  crowdsec:
    environment:
      - COLLECTIONS=crowdsecurity/nginx
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

uses:
- [Crowdsec docker agent](https://docs.crowdsec.net/u/getting_started/installation/docker)
- [Crowdsec docker bouncer wrapper](https://github.com/shgew/cs-firewall-bouncer-docker)

with custom config:

`/mnt/rei/configs/crowdsec-config/acquis.yaml`

```
filenames:
  - /var/log/nginx/*.log

labels:
  type: nginx-proxy-manager
```

Check that `type: nginx-proxy-manager` if you want to parse `nginx-proxy-manager` style logs!! is different from `type: nginx` !! (thank you [source](https://discourse.crowdsec.net/t/setting-up-crowdsec-with-nginx-proxy-manager/1096/5))


to see whether it's parsing the logs correctly, go into main `crowdsec` container and run:

`crowdsec cscli lists`
`crowdsec cscli metrics`

If it's not parsing (e.g. lots of `Lines unparsed`), ensure it can parse nginx reverse proxy logs by installing the `nginx-proxy-manager` log parser inside the container. Now, I did this via the trueNAS CLI, docker-ing into the crowdsec container with:

`sudo docker ps | grep crowdsec` --> finds the container name, in my case, `ix-crowdsec-crowdsec-1`
```
juni-nas@truenas /mnt/rei/configs/crowdsec-config
 % sudo docker ps | grep crowdsec                                                                              
37322ccb9a35   crowdsecurity/crowdsec                                           "/bin/bash /docker_s…"   20 minutes ago   Up About a minute      0.0.0.0:9090->8080/tcp, [::]:9090->8080/tcp                                                                                               ix-crowdsec-crowdsec-1
d0ba33eec425   ghcr.io/shgew/cs-firewall-bouncer-docker:latest                  "/entrypoint.sh"         20 minutes ago   Up 20 minutes                                                            
```

`sudo docker exec -it ix-crowdsec-crowdsec-1 cscli collections install crowdsecurity/nginx-proxy-manager`

ensure it's enabled, if not, run:

`sudo docker exec -it ix-crowdsec-crowdsec-1 cscli collections enable crowdsecurity/nginx-proxy-manager`

then `sudo docker restart ix-crowdsec-crowdsec-1` to apply changes.

then, go back into the `crowdsec` container and run:

`cscli collections list`

ensure you have a line like:

` crowdsecurity/nginx-proxy-manager  ✔️  enabled  0.1      /etc/crowdsec/collections/nginx-proxy-manager.yaml`

now after running `cscli metrics`, should see all lines being parsed correctly! 
```
│ Lines parsed │
│ 24           │ proxy-host-16_access.log
│ 6            │ proxy-host-17_access.log
│ 6            │ proxy-host-18_access.log
```
![](Screenshot%202025-07-16%20at%2011.54.58%20pm.png)
Importantly, check that all of the `child-crowdsecurity/nginx-proxy-manager-logs` are being parsed correctly:
![](Screenshot%202025-07-16%20at%2011.56.15%20pm.png)
(`nginx` still won't be, as we're not using that log format but the parser is still installed - can always uninstall it using a similar method to above for cleanup)

**Logging enrichment is working:**
```
│ crowdsecurity/dateparse-enrich        │ 36   │ 36     │ -        │
│ crowdsecurity/geoip-enrich            │ 36   │ 36     │ -        │
│ crowdsecurity/http-crawl-non_statics  │ Instantiated: 6 │ Poured: 6 │ Expired: 6 │
```
- Enriched (date + geoip)
- Passed into at least one HTTP scenario (crawl detection)
- Triggers were instantiated and expired normally, which is healthy.

**Bouncer is working:** CrowdSec decisions are being streamed to the bouncer - meaning **offending IPs are being blocked**.
```
│ firewall-bouncer │ /v1/decisions/stream │ GET │ 6 │
```


## Progress Checklist:
- [x] nft list ruleset shows crowdsec tables and chains
- [x] docker logs show decisions being applied
- [x] trying to set up bouncer to parse nginx log files correctly - look [here](https://www.simplehomelab.com/crowdsec-docker-compose-1-fw-bouncer/)
	- [x] https://discourse.crowdsec.net/t/setting-up-crowdsec-with-nginx-proxy-manager/1096/5
- [ ] Block decisions in CrowdSec UI / logs result in IPs being added
- [ ] Confirm IPs are actually blocked (use nft get set ... or try from a test VM)
- [ ] tuning scenarios, alerting (like Gotify or email), reviewing banned IPs
- [ ] dashboard linking to