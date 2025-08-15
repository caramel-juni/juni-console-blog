---
title: "Getting pfSense/Suricata Logs into Splunk"
date: 2025-08-04
description: ""
toc: true
math: true
draft: false
categories: 
tags:
---

Below lays out my adventures setting up syslog-ng as a pfSense package to get pfSense (&/or Suricata - the same process can be applied, see [the very helpful guide here](https://www.unsafehex.com/index.php/2023/10/11/forward-pfsense-suricata-splunk/)) logs into a Splunk (Cloud) instance!

---

# Pre-requisites:
- Change the logging format on pfSense from the **default BSD log message format** to the **syslog** **(RFC5424) format**. Enables extra info like hostname, etc. to be logged.
- Have a working pfSense router (that can install official pfSense packages, most easily done via the webUI)
- Have a working & accessible Splunk Cloud instance

---

# 1. Create HEC in Splunk:

The HTTP Event Collector will receive events from a remote logging server (in our case, `syslog-ng` installed as a pfSense package/add-on), and ingest them into a given `index` on your Splunk server.

Create it via `Settings > Data Inputs`, then select `Add New` next to `HTTP Event Collector`. Enter the following values:

- `Name` : `pfSense-Splunk` (or up to you)
- `Sourcetype`: `Automatic` (will be specified on the `syslog-ng` message body on our `pfsense` router.)
- `Index`: A pre-created index, where you want the logs stored on your Splunk server. For me, it's: `security_network`.
![](/posts/21/posts/21/Pasted%20image%2020250728165154.png)Once generated, **copy the HEC's unique `<TOKEN>`** & save for later use.

---

# 2. Configure the syslog-ng app in pfSense:
We'll need to create (at least) 3 kinds of configuration files. A:
- `source`: specifies where on the system, and how the `syslog-ng` looks for the log files
- `destination`: specifies parameters for the destination (in this case, the splunk HEC)	
- `log`: connects the `desitination` file with the `source` file

**Here are the settings I configured for each:**

# 2.1 - `source`
![](/posts/21/Pasted%20image%2020250728170423.png)

**Name:** `s_pfsense_logs`
**Type:** `Source`
**Object Parameters:**
```
{
  wildcard-file(
    base-dir("/var/log/")
    filename-pattern("*.log")
    recursive(no)
    flags(no-parse)
  );
};
```
- Will match files within `/var/log` (no nested directories, as `recursive(no)`) that end in (exactly) `.log`. This was determined by looking inside `/var/log`, and identifying the `syslog` files of interest: ![](/posts/21/Pasted%20image%2020250728171037.png)


# 2.2 - `destination`:
![](/posts/21/Pasted%20image%2020250728171427.png)

**Name:** `d_pfsense_splunk`
**Type:** `Destination`
**Object Parameters:**
```syslog-ng
{
    http(url("https://http-inputs-<HOST>.splunkcloud.com:443/services/collector/event")
        persist-name("splunk-pfsense-hec")
        method("POST")
        user_agent("syslog-ng User Agent")
        headers("Authorization: Splunk <HEC-TOKEN>")
        batch-lines(10)
        batch-bytes(500000)
        throttle(50)
        peer-verify(yes)
        body("$(format-json time=${S_UNIXTIME} host=${HOST} source=${FILE_NAME} sourcetype=\"pfsense\" index=\"security_network\" event=${MSG})\n")
  );
};
```

- To configure the URL of your HEC, read the docs [here](https://help.splunk.com/en/splunk-cloud-platform/get-started/get-data-in/9.3.2408/get-data-with-http-event-collector/set-up-and-use-http-event-collector-in-splunk-web#ariaid-title6). As I'm using the SplunkCloud platform, mine takes the format:
`<protocol>://http-inputs-<host>.splunkcloud.com:<port>/<endpoint>`. Be sure to replace the relevant fields in the above example tailored to your specific splunk server's settings (`<HOST>`, etc.)
- Replace `<HEC-TOKEN>` with your HEC token created in Step 1
- Feel free to change the fields referenced in the `body`, but **ensure to add** `event=${MSG})\n` to get the actual log event sent.

If using `syslog-ng` to scrape logs from different services (such as from both `Suricata` (see guide for that [here](https://www.unsafehex.com/index.php/2023/10/11/forward-pfsense-suricata-splunk/)) and `pfSense syslogs`, ensure that each `destination` file has the following UNIQUE values to differentiate the entries:
- `persist-name` 
- `user-agent`


# 2.3 - `log`
![](/posts/21/Pasted%20image%2020250728172144.png)
**Name:** `log_splunk_pfsense`
**Type:** `Log`
**Object Parameters:**
```
{ 
  source(s_pfsense_logs);
  destination(d_splunk_pfSense_hec); 
};
```
- Replace `source` and `destination` with your entry names (if you changed them from the values I used above)

---


# 3. - Review: Final syslog-ng settings (my use case)
After creating the above files, ensure that you have `syslog-ng` **enabled on all of the relevant `pfSense` interfaces** on the `General` tab (see below).

Then, your `syslog-ng` server should restart (can verify this on `Log Viewer` tab) & begin pushing logs to your Splunk HEC within the next 5 minutes or so!

# 3.1 - Final `General` tab settings:
![](/posts/21/Pasted%20image%2020250728173703.png)

# 3.2 - Final `Advanced` tab settings:
*For pushing (to Splunk) both `Suricata` logs and `pfSense syslogs` using the same `syslog-ng` server on my pfSense router:*

![](/posts/21/Pasted%20image%2020250728172308.png)

# 3.3 - Proof - Logs ingesting in Splunk:

![](/posts/21/Pasted%20image%2020250728175537.png)

---

# 4. - Troubleshooting Guidance:

If no logs are appearing after 5-10 minutes, and they are actively being written on the `pfSense` firewall itself, see whether there are any errors using the following query, and troubleshoot accordingly with the help of google/the docs/AI:*

**SPL:** `index=_internal component=HttpInputDataHandler`

---

# 5. - The next step... enriching firewall rule data with descriptions/types

This is all well and good, until parsing `filter.log` (where the pfSense firewall logs are) reveals that **only the Rule IDs, not actual rule descriptors, are logged** - making correlation between the two the next challenge. Seeing that `Rule 1724919554` triggered a `block` doesn't really paint a complete picture, after all...

- [Raw `filter.log` Format | pfSense Documentation](https://docs.netgate.com/pfsense/en/latest/monitoring/logs/raw-filter-format.html)
- [Viewing the Firewall Log | pfSense Documentation](https://docs.netgate.com/pfsense/en/latest/monitoring/logs/firewall.html)

As mentioned above, pfSense **correlates Rule IDs to Rule Descriptors dynamically via a GUI option**, and only displays this **within the UI itself** (not the raw `filter.log` files). AKA... ***we'll have to get a little hacky to correlate the two within raw syslog outputs.***

To get a dump of all of the current firewall rule descriptions, the following command can be run with the `pfsense cli`:
- `pfctl -vvsr`

So... we just need to routinely run this command to get the updated rule database, potentially strip it of any junk data & output it as a `.log` file to send to splunk via `syslog-ng`.

To do this, I **initially** ***(more elegant solution below)*** **created a script**, `gen_pf_rulemap.sh`, residing in the `/root` home directory (in order to make it executable with `chmod +x`). This would strip the output of `pfctl -vvsr` into a more human-readable format, to be sent to correlate Rule IDs & Descriptors to an external SIEM (like Splunk).

``` bash
#!/bin/sh

pfctl -vvsr | awk '
/^@/ {
    rule_id = "unknown"
    desc = "unknown"

    # Extract rule ID after "ridentifier "
    rid_index = index($0, "ridentifier ")
    if (rid_index > 0) {
        rule_id = substr($0, rid_index + 11)
        # Trim trailing spaces or text after the number
        split(rule_id, parts, " ")
        rule_id = parts[1]
    }

    # Extract label between label "..."
    label_index = index($0, "label \"")
    if (label_index > 0) {
        rest = substr($0, label_index + 7)
        endquote = index(rest, "\"")
        if (endquote > 0) {
            desc = substr(rest, 1, endquote - 1)
        }
    }

    print rule_id ";" desc
}
' > /conf/pfsense_rulemap/rule_map.log
```

Then, I created the `/conf/pfsense_rulemap/` directory, which *should* persist upon reboots and allow storage of these rules. 

Each time the `gen_pf_rulemap.sh` script is run, it will overwrite the existing `rule_map.log` file, which could be seen as a good or bad thing, but given we're routinely pushing this to splunk, it minimises the footprint on the device itself (given it lists **all current** firewall rules). 

Here's a sample of the output we get by running the script:

![](/posts/21/Pasted%20image%2020250729154133.png)

*Hurrah! Success!*

Now, we just need to add this script as a routine cronjob...

---

**...and it was at this point that I found the official `pfsense cron` package.**

Which made things **A LOT simpler.**

So - to do this "elegantly", install the `cron` package via `System > Package Manager > Available Packages`.

And upon installing... I realised that I can just **put the entire "command" in the cronjob UI here to be run**. So no need for the `gen_pf_rulemap.sh` script. Whoops.

The previous script just **requires a bit of modification** to ensure it runs properly as a cron command, see below:

![](/posts/21/Pasted%20image%2020250729155317.png)

**Cron Command one-liner:**
``` bash
pfctl -vvsr | awk '/^@/ { rule_id = "unknown"; desc = "unknown"; rid_index = index($0, "ridentifier "); if (rid_index > 0) { rule_id = substr($0, rid_index + 11); split(rule_id, parts, " "); rule_id = parts[1]; } label_index = index($0, "label \""); if (label_index > 0) { rest = substr($0, label_index + 7); endquote = index(rest, "\""); if (endquote > 0) { desc = substr(rest, 1, endquote - 1); } } print rule_id ";" desc; }' > /var/log/firewall_rule_map.log
```

**Proof!**
![](/posts/21/Pasted%20image%2020250729155802.png)

Given that I was already sending all files that end in `.log` within `/var/log` to Splunk via `syslog-ng`, I just modified the above cronjob so that it writes the file output there (`/var/log/firewall_rule_map.log`), and bam - within minutes, it was being routinely pushed up into splunk for correlation!

![](/posts/21/Pasted%20image%2020250729154748.png)

One tiny problem seemed to be that modifications to the file were not being picked up by syslog-ng due to it being overwritten with what often was the same, unchanged content. So, just to test this and be safe, I created a second cronjob to delete the file 5 minutes after its created (so every hour at `5,15,25,35,45,55` minutes past), to ensure that `syslog-ng` would see it as a "new" file and re-parse the data (even if not updated).

![](/posts/21/Pasted%20image%2020250729172409.png)

There's 100% a more elegant solution to this - *like modifying the original command to **append** any additional rules added instead of rewriting the entire file* - but that would require messing around further with how `pfctl -vvsr` dumps the rule list, and wasn't worth my time at this point.
![](/posts/21/Pasted%20image%2020250729173409.png)

In any case - now that there's a semi-regular updating set of rules coming into Splunk, we can **correlate the firewall rule IDs** with the **rule description (if provided) & type** within our splunk searches, to **enrich our firewall SIEM data! ~** 


<div style="display: flex; align-items: center; justify-content: center; height: 100px;"> 
<img src="https://gifcity.carrd.co/assets/images/gallery83/b4d35e62.gif?v=e3c0bc0f" style="width:100px">
<i>~~ yippee!</em> ~~</i>
<img src="https://gifcity.carrd.co/assets/images/gallery83/fce7d473.gif?v=e3c0bc0f" style="width:100px"> 
</div>

