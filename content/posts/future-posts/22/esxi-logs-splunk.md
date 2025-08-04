---
title: "Getting ESXi Logs into Splunk"
date: 2025-08-03
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

This is part 3 of my "pretending-to-know-how-to-play-nicely-with-Splunk-Cloud" series - getting some more "critical infrastructure" logs in, namely, for `ESXi` servers!

# Overall Architecture:
As per the [Splunk Documentation](https://docs.splunk.com/Documentation/AddOns/released/VMWesxilogs/InstallOverview#Install_Splunk_Add-on_for_VMware_ESXi_Logs_in_a_Cloud_environment):
![](posts/future-posts/22/Pasted%20image%2020250801164815.png)
So in terms of the physical endpoints we need to configure:
```
ESXi Server syslog daemon
  |
  |
syslog-ng server (ESXi VM) + Splunk UF with Splunk Add-On for VMWare ESXi Logs
  |
  |
Splunk Cloud + Splunk Add-On for ESXi Logs + Splunk Add-on for VMware Indexes
```
- [Install and configure the Splunk Add-on for VMware ESXi Logs - Splunk Documentation](https://docs.splunk.com/Documentation/AddOns/released/VMWesxilogs/Install)

Whew! So, quite a lot. Let's get the basics started.

---
### 1. Create HEC in Splunk:

The HTTP Event Collector will receive events from a remote logging server (in our case, `syslog-ng`), and ingest them into a given `index` on your Splunk server.

Create it via `Settings > Data Inputs`, then select `Add New` next to `HTTP Event Collector`. Enter the following values:

- `Name` : `ESXi-Splunk` (or whatever you choose)
- `Sourcetype`: `Automatic` (will be specified on the `syslog-ng` message body on our `pfsense` router.)
- `Index`: A pre-created index, where you want the logs stored on your Splunk server. In my case, it's: `security_network`.
Once generated, **copy the HEC's unique `<TOKEN>`** & save for later use.

---
### 2. Install & configure syslog-ng server on ESXi VM

After spinning up a VM somewhere on the same network as your host ESXi server (I'm using `Ubuntu Server 24.04`), run the following to configure your `syslog-ng` server:

1. `sudo apt install syslog-ng`
2. Configure `syslog-ng.conf` in `/etc/syslog-ng`:
``` bash
@version: 4.3

@include "scl.conf"

source s_local {
    system();
    internal();
};

destination d_splunk_hec {
    http(
        url("https://http-inputs-<HOST>.splunkcloud.com:443/services/collector/event")
        method("POST")
        headers("Authorization: Splunk <HEC-TOKEN>")
        user-agent("syslog-ng")
        tls(peer-verify(yes))
        persist-name("splunk_hec_dest")
        body("$(format-json event=${MSG} host=${HOST} source=${PROGRAM} sourcetype=\"syslog\" time=${UNIXTIME})")
    );
};

log {
    source(s_local);
    destination(d_splunk_hec);
};
```
- To configure the URL of your HEC, read the docs [here](https://help.splunk.com/en/splunk-cloud-platform/get-started/get-data-in/9.3.2408/get-data-with-http-event-collector/set-up-and-use-http-event-collector-in-splunk-web#ariaid-title6). As I'm using the SplunkCloud platform, mine takes the format: `<protocol>://http-inputs-<host>.splunkcloud.com:<port>/<endpoint>`, with `<endpoint>` being `services/collector/event`.
  *Be sure to replace the relevant fields in the above example tailored to your specific splunk server's settings (`<HOST>`, `<HEC-TOKEN>` with the HEC token created in Step 1, etc.)*

3. Test it by running `sudo syslog-ng -Fev`, inspect for any errors thrown by your config file. ![](posts/future-posts/22/Pasted%20image%2020250730134418.png)
4. If nothing urgent crops up (as this is a bare bones install, just monitoring the local VM's logging indexes `system();` and `internal();`, just to test functionality), terminate `syslog-ng` with `Ctr+C` and then generate a test alert with:
   `logger -p local0.info "Test from syslog-ng to HEC"`
5. Restart `syslog-ng` in the foreground with `sudo syslog-ng -Fev`
6. Head into Splunk to see whether the alerts are getting sent over!
   ![](posts/future-posts/22/Pasted%20image%2020250730135417.png)

---
### 3. Configure ESXi to send *its* `syslogs` to `syslog-ng` --> Splunk

#### 3.1 - Allow `syslog` communication through the firewall
- `esxcli network firewall ruleset set -r syslog -e true`
- `esxcli network firewall refresh`

#### 3.2 - Set the remote `syslog-ng` host & protocol to send over:

I recommend `TCP` for reliable log delivery (ensures logs are recived and acknowledged by the syslog server - `UDP` doesn't guarantee/check for delivery)

- `esxcli system syslog config set --loghost='tcp://172.16.66.5:514'`
*Replace the IP with the (static) IP configured for your `syslog-ng` VM.*

Check this is all correct with `esxcli system syslog config get`. Optionally, you can also **configure log rotation, level, and persistent storage options.** Take note of where the logs are being written to before forwarded off - for me, it was `/var/log.esxi.log`.

Once done, run `esxcli system syslog reload`.

#### 3.3 - Check your logs are writing routinely to your chosen output file

For me, this involved running `tail -f /var/log/esxi.log` and inspecting that events were regularly coming in. As a test, you can also generate a custom log message with `logger "Test message from ESXi"`, and check it shows up in there.

![](posts/future-posts/22/Pasted%20image%2020250801171255.png)

Now we know the logs are being written to the file, we can hope (and check) that they're being sent over to our remote `syslog-ng` VM we specified in 3.2! 

Unfortunately, as the ESXi host is on a minimal `busybox` install, it lacks a few of the tools like `tcpdump` commonly used to easily monitor/listen to outgoing traffic... but we can check from the other *side* (out `syslog-ng` VM) to see if the connection has been made, with:
- `sudo netstat -tnp | grep :514`
![](posts/future-posts/22/Pasted%20image%2020250801172729.png)

Success! My `ESXi` host (`172.16.16.2`, on port `24770` ) is connected & sending traffic to my `syslog-ng` server (`172.16.16.5`, listening on port `514`).

> **Note:** ESXi (like any client) uses a random high-numbered, ephemeral port as the source port (`24770`) when it connects outbound to a remote TCP service like syslog on port 514.

---
### 4 - Change the `syslog-ng` source to listen for the incoming `ESXi` logs

Change your `syslog-ng.conf` file to the following, specifically the `source` section to listen for the incoming `ESXi` logs.

I've also set up a duplicate `destination` in the form of a local `d_debug_file` , `/var/log/splunk-debug.log`, to check that the logs are flowing smoothly.

``` bash
@version: 4.3
@include "scl.conf"

source s_esxi_tcp {
    network(
        ip(0.0.0.0)
        port(514)
        transport("tcp")
    );
};

destination d_debug_file {
    file("/var/log/splunk-debug.log" template("$(format-json --scope rfc5424 --key ISODATE,HOST,PROGRAM,MESSAGE)\n"));
};

destination d_splunk_hec {
    http(
        url("https://http-inputs-<HOST>.splunkcloud.com:443/services/collector/event")
        method("POST")
        headers("Authorization: Splunk <HEC-TOKEN>")
        user-agent("syslog-ng")
        tls(peer-verify(yes))
        persist-name("splunk_hec_dest")
        body("$(format-json event=${MSG} host=${HOST} source=${PROGRAM} sourcetype=\"syslog\" time=${UNIXTIME})")
    );
};

log {
    source(s_esxi_tcp);
    destination(d_debug_file);
    destination(d_splunk_hec);
};
```

**And from here, just alternate between:**
- Checking the format of the local debug logs with `sudo tail /var/log/splunk-debug.log`
- Checking whether the Splunk HEC is dummy spitting at the format they're in, using the following index/component **SPL**: `index=_internal component=HttpInputDataHandler`
  ![](posts/future-posts/22/Pasted%20image%2020250801174519.png)

Make any `JSON`-specific formatting adjustments as you go, with the help of AI (ain't nobody got time for parsing `JSON`)

***And hopefully, you should soon have it all coming through and into Splunk!***

# Finally... Enabling field extraction with the Splunk ESXi Add-On(s...) or not 💀

The inital setup diagram made out this final hurdle to look a *bit* convoluted.... **and that turned out to be *exactly* the case, at least whilst working with Splunk Cloud**. I never managed to get this working, potentially due to an (unknown) combination of the following variables:
- Parsing & extracting certain fields with `syslog-ng` on the VM before sending it to the splunk HEC (in order for it to be accepted....)
- The ambiguous state of whether you need to *also* [run a Splunk UF](https://docs.splunk.com/Documentation/AddOns/released/VMWesxilogs/Install#Configure_the_Splunk_Add-on_for_VMware_to_receive_ESXi_syslog_data) on the `syslog-ng` server, and how that interacts with the `syslog-ng` service itself...
- **Having to seemingly [install like 4-5 different add-ons](https://docs.splunk.com/Documentation/AddOns/released/VMW/Cloudinstall)** (depending on where in the documentation you look...) to get custom field extraction working, some of which are **not even natively available for install in Splunk Cloud at this time...**
- The actual **[Splunk Add-on for VMware](https://docs.splunk.com/Documentation/AddOns/released/VMW/About)** not being natively available via the Splunk Cloud "app store", having to be installed manually... which *also* failed.
  ![](Pasted%20image%2020250804142926.png)

Whether I set  the `sourcetype=vmware-esxilog`, or `sourcetype=syslog`, the **same (largely unhelpful/generic) fields seemed to be being extracted**, with no real intelligent parsing of the data in a way that it could be ingested into the VMWare for Splunk app (if that could even be installed....).
![](Pasted%20image%2020250804133729.png)

**So, custom field extraction it will be 🫠.**

Here are some links to the "relevant" (how much of it is *actually* relevant to Splunk Cloud is extremely questionable, though...) documentation for getting this to work, in hopes that a future poor soul who is tasked with setting this up can figure it out.
- [Install and configure the Splunk Add-on for VMware ESXi Logs - Splunk Documentation](https://docs.splunk.com/Documentation/AddOns/released/VMWesxilogs/Install#Configure_the_Splunk_Add-on_for_VMware_to_receive_ESXi_syslog_data)
- [Install the Splunk Add-on for VMware in a cloud environment - Splunk Documentation](https://docs.splunk.com/Documentation/AddOns/released/VMW/Cloudinstall)
- [Syslog data collection - Splunk Documentation](https://docs.splunk.com/Documentation/SVA/current/Architectures/Syslog) (collecting syslogs without the add-ons - what I *think* is currently happening in my setup)