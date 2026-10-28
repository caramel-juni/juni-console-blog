---
title: ""
date: 2026-10-22
description: ""
toc: true
math: true
draft: true
categories: 
tags:
---

<img src="https://juniblog.goatcounter.com/count?p=/POST-TITLE/" style="display: none">
^^ add post title above for tracking



# T3S3 Wi-Fi LLM Terminal: Build Guide

Type on a pocket keyboard, send the prompt over Wi-Fi to a small relay, and watch the model's answer stream onto the T3S3's OLED as it is generated. Written for the **LilyGO T3S3 V1.2** (ESP32-S3, one USB-C, 0.96" 128x64 OLED, 2 x QWIIC).

This is the simpler sibling of the LoRa guide: no second radio, no packet protocol, and replies can be long. The LoRa module on your board isn't used, so any module variant (or none) works.

## 1. How it works

```
 [CardKB] --I2C--> [T3S3] ~~~ Wi-Fi (HTTP) ~~~> [relay.py] --> Ollama on the same Pi/laptop
                   OLED: prompt + streamed reply     |           (or a hosted API, see section 8)
                                                     +-- holds the token, history, API key
```

- The **T3S3** sends the prompt as one HTTP POST and reads the reply as it streams back, drawing it live.
- The **relay** (a ~70-line Python script) checks a shared token, keeps a little chat history, calls the model, cleans the text to plain ASCII, and streams it out. Ollama itself stays private on the Pi; only the relay is exposed.
- Swapping the model (a different Ollama model, llama.cpp, or a hosted API) only changes the relay, never the firmware
## 2. Parts

|   |   |
|---|---|
|Part|Notes|
|LilyGO T3S3 V1.2|Wi-Fi is 2.4 GHz only|
|M5Stack CardKB v1.1|I2C keyboard at address 0x5F, runs at 3.3 V|
|QWIIC-to-Dupont cable (or Grove-to-QWIIC adapter)|The CardKB has a Grove plug, the T3S3 has QWIIC sockets|
|LiPo 3.7 V (optional)|**Check the connector polarity against the board silkscreen**, as LiPo plugs are often reversed between brands|
|Raspberry Pi 4/5 (4 GB+) or a laptop|Runs Ollama and the relay. Skip the model if you use a hosted API|

## 3. Wiring the keyboard

QWIIC pin order: black = GND, red = 3.3 V, blue = SDA, yellow = SCL. Plug the CardKB into a QWIIC port, or use the 2x13 header for 3V3, GND and the two I2C pins.

The OLED sits on I2C at GPIO18 (SDA) / GPIO17 (SCL), address 0x3C. I don't know whether both QWIIC ports share that bus, so test it. Plug the CardKB into one port and run this scanner:

```cpp
#include <Arduino.h>
#include <Wire.h>

void setup() {
  Serial.begin(115200);
  delay(2000);
  Wire.begin(18, 17);                 // the OLED bus
  for (uint8_t a = 1; a < 127; a++) {
    Wire.beginTransmission(a);
    if (Wire.endTransmission() == 0) Serial.printf("found 0x%02X\n", a);
  }
  Serial.println("scan done");
}

void loop() {}
```

- **`0x3C` and `0x5F` both appear:** that port shares the OLED bus. Keep `KB_SHARED_BUS 1` in the firmware.
- **Only `0x3C` appears:** the port is on a separate bus. Look up its SDA/SCL on LilyGO's V1.2 pin diagram, set `KB_SHARED_BUS 0`, and enter those two pins as `KB_SDA` and `KB_SCL`.

## 4. Server side (Pi or laptop)

### 4.1 Install the model runtime

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:1b          # fast on a Pi; use a bigger model on a laptop
ollama run llama3.2:1b "Say hi in five words"   # sanity check
```

On a Pi 4/5 use a 0.5-1.5B model (`llama3.2:1b`, `gemma3:1b`, `qwen2.5:1.5b`). On a laptop, 3-8B models are fine. Pick a **non-reasoning** model, since "thinking" output wastes tokens and the wait.

### 4.2 The relay

```bash
mkdir -p ~/terminal-relay && cd ~/terminal-relay
python3 -m venv venv && ./venv/bin/pip install fastapi uvicorn requests
openssl rand -hex 16            # generate a token and keep it
```

`~/terminal-relay/relay.py`:

```python
"""Tiny relay between the T3S3 terminal and an LLM backend."""
import json, os, unicodedata
import requests
from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.responses import PlainTextResponse, StreamingResponse

TOKEN = os.environ.get("TERMINAL_TOKEN", "")
BACKEND = os.environ.get("BACKEND", "ollama")          # ollama | anthropic
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.2:1b")
ANTHROPIC_KEY = os.environ.get("ANTHROPIC_API_KEY", "")
ANTHROPIC_MODEL = os.environ.get("ANTHROPIC_MODEL", "claude-haiku-5-5")
MAX_TOKENS = int(os.environ.get("MAX_TOKENS", "250"))
SYSTEM = ("You are answering on a tiny 25-column OLED. Reply in plain ASCII only: "
          "no markdown, no lists, no emoji. Be brief: 80 words or fewer.")

TABLE = str.maketrans({"\u2018": "'", "\u2019": "'", "\u201c": '"', "\u201d": '"',
                       "\u2013": "-", "\u2014": "-", "\u2026": "..."})
app = FastAPI()
history = []                      # last 3 exchanges, shared by all clients


def clean(s: str) -> str:
    return unicodedata.normalize("NFKD", s.translate(TABLE)).encode("ascii", "ignore").decode()


def ollama_stream(msgs):
    body = {"model": OLLAMA_MODEL, "messages": [{"role": "system", "content": SYSTEM}] + msgs,
            "stream": True, "keep_alive": "30m",
            "options": {"num_predict": MAX_TOKENS, "temperature": 0.7}}
    with requests.post(f"{OLLAMA_URL}/api/chat", json=body, stream=True, timeout=300) as r:
        r.raise_for_status()
        for line in r.iter_lines():
            if not line:
                continue
            d = json.loads(line)
            piece = d.get("message", {}).get("content", "")
            if piece:
                yield piece
            if d.get("done"):
                break


def anthropic_once(msgs):
    r = requests.post(
        "https://api.anthropic.com/v1/messages", timeout=120,
        headers={"x-api-key": ANTHROPIC_KEY, "anthropic-version": "2023-06-01",
                 "content-type": "application/json"},
        json={"model": ANTHROPIC_MODEL, "max_tokens": MAX_TOKENS, "system": SYSTEM, "messages": msgs})
    r.raise_for_status()
    yield "".join(b.get("text", "") for b in r.json()["content"] if b.get("type") == "text")


def stream_reply(prompt):
    msgs = history + [{"role": "user", "content": prompt}]
    out = []
    try:
        src = ollama_stream(msgs) if BACKEND == "ollama" else anthropic_once(msgs)
        for piece in src:
            piece = clean(piece)
            out.append(piece)
            yield piece
    except Exception as e:
        yield f"\n[error: {str(e)[:60]}]"
        return
    history.extend([{"role": "user", "content": prompt},
                    {"role": "assistant", "content": "".join(out)}])
    del history[:-6]


@app.post("/ask")
async def ask(request: Request, x_token: str = Header(default="")):
    if TOKEN and x_token != TOKEN:
        raise HTTPException(401, "bad token")
    prompt = (await request.body()).decode("utf-8", "ignore").strip()[:500]
    if not prompt:
        raise HTTPException(400, "empty")
    print("> " + prompt)
    if prompt == "/new":
        history.clear()
        return PlainTextResponse("history cleared")
    if prompt == "/ping":
        return PlainTextResponse("pong")
    return StreamingResponse(stream_reply(prompt), media_type="text/plain")
```

Run it and test it from the Pi itself. `--http1.0` mimics what the firmware sends:

```bash
TERMINAL_TOKEN=yourtoken ./venv/bin/uvicorn relay:app --host 0.0.0.0 --port 8787
# in a second shell:
curl -N --http1.0 -H "X-Token: yourtoken" -d "Say hi in five words" http://localhost:8787/ask
```

Text should appear piece by piece. Commands the terminal understands: `/ping` (instant reply, tests the link without the model) and `/new` (clears chat history).

### 4.3 Reserve an IP and open the port

- Give the Pi a fixed address (a DHCP reservation in your router is easiest). The firmware uses the IP directly, since `.local` names often fail on the ESP32.
- If the Pi runs a firewall: `sudo ufw allow 8787/tcp`.

### 4.4 Run it at boot (systemd)

`/home/pi/terminal-relay/relay.env`:

```
TERMINAL_TOKEN=yourtoken
OLLAMA_MODEL=llama3.2:1b
```

`/etc/systemd/system/terminal-relay.service` (edit the user and paths):

```ini
[Unit]
Description=T3S3 terminal relay
After=network-online.target ollama.service

[Service]
User=pi
WorkingDirectory=/home/pi/terminal-relay
EnvironmentFile=/home/pi/terminal-relay/relay.env
ExecStart=/home/pi/terminal-relay/venv/bin/uvicorn relay:app --host 0.0.0.0 --port 8787
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload && sudo systemctl enable --now terminal-relay
journalctl -u terminal-relay -f
```

## 5. Firmware (T3S3)

In PlatformIO create a project `terminal`. `platformio.ini`:

```ini
[env:t3s3]
platform = espressif32@^6.9.0
board = esp32-s3-devkitc-1
framework = arduino
monitor_speed = 115200
build_flags =
  -DARDUINO_USB_MODE=1
  -DARDUINO_USB_CDC_ON_BOOT=1
lib_deps =
  olikraus/U8g2@^2.35.19
```

`USB_CDC_ON_BOOT` makes `Serial` appear over the native USB-C port. If an upload fails, hold **BOOT**, tap **RST**, release BOOT, then upload again.

Put your settings in `include/secrets.h` and add it to `.gitignore`:

```cpp
#pragma once
#define WIFI_SSID_1 "HomeWiFi"
#define WIFI_PASS_1 "password"
#define WIFI_SSID_2 "PhoneHotspot"      // optional second network; delete both lines if unused
#define WIFI_PASS_2 "password"
#define SERVER_HOST "192.168.1.50"      // the Pi's reserved IP (or a hostname)
#define SERVER_PORT 8787
#define USE_TLS 0                       // 1 for an HTTPS tunnel (section 7)
#define AUTH_TOKEN "yourtoken"
```

`src/main.cpp`. The screen is 25 columns x 8 rows (`u8g2_font_5x8_tr`): 7 rows of text plus a status line. Controls: **Enter** sends, **Backspace** deletes, **Esc** clears the prompt (or stops a reply in progress), **Up/Down** scroll the reply, and **Enter/Esc** on a reply starts a new prompt.

```cpp
#include <Arduino.h>
#include <Wire.h>
#include <U8g2lib.h>
#include <WiFi.h>
#include <WiFiMulti.h>
#include <vector>
#include "secrets.h"

#if USE_TLS
  #include <WiFiClientSecure.h>
  WiFiClientSecure net;
#else
  #include <WiFiClient.h>
  WiFiClient net;
#endif

#define OLED_SDA 18
#define OLED_SCL 17
#define CARDKB_ADDR 0x5F

// 1 = keyboard shares the OLED bus (GPIO18/17), 0 = separate Wire1 pins
#define KB_SHARED_BUS 1
#if KB_SHARED_BUS
  #define KB Wire
#else
  #define KB Wire1
  #define KB_SDA 15   // EXAMPLE ONLY: set to your QWIIC port's SDA/SCL pins
  #define KB_SCL 16
#endif

#define MAX_INPUT 200
#define MAX_REPLY 4000
#define COLS 25
#define ROWS 8
#define REPLY_TIMEOUT 90000   // ms of silence before giving up (covers model load time)

U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, OLED_SCL, OLED_SDA);
WiFiMulti wifiMulti;

enum State { EDIT, WAIT_HDR, STREAMING, SHOW };
State state = EDIT;
enum ChunkState { CS_SIZE, CS_EXT, CS_DATA, CS_CRLF, CS_DONE };
ChunkState cs = CS_SIZE;

String input, reply, hdr, notice;
std::vector<String> lines;
int scrollTop = 0;
uint32_t lastRx = 0, lastDraw = 0, lastStatus = 0, chunkLeft = 0;
bool chunked = false, finished = false, dirty = false;

// ---------- display ----------
void wrapText(const String& s, std::vector<String>& out) {
  out.clear();
  String line, word;
  for (size_t i = 0; i <= s.length(); i++) {
    char c = (i < s.length()) ? s[i] : '\n';
    if (c == ' ' || c == '\n') {
      if (line.length() + (line.length() ? 1 : 0) + word.length() <= COLS) {
        if (line.length()) line += ' ';
        line += word;
      } else {
        if (line.length()) out.push_back(line);
        line = word;
        while (line.length() > COLS) {
          out.push_back(line.substring(0, COLS));
          line = line.substring(COLS);
        }
      }
      word = "";
      if (c == '\n') { out.push_back(line); line = ""; }
    } else {
      word += c;
    }
  }
  if (line.length()) out.push_back(line);
}

void render() {
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_5x8_tr);
  for (int r = 0; r < ROWS - 1; r++) {
    int idx = scrollTop + r;
    if (idx >= (int)lines.size()) break;
    u8g2.drawStr(0, r * 8 + 7, lines[idx].c_str());
  }
  u8g2.drawStr(0, 63, notice.c_str());
  u8g2.sendBuffer();
}

void showNotice(const char* msg) { notice = msg; render(); }

void refreshEdit() {
  wrapText(input + "_", lines);
  scrollTop = max(0, (int)lines.size() - (ROWS - 1));
  char b[32];
  if (WiFi.status() == WL_CONNECTED)
    snprintf(b, sizeof(b), "%u/%d wifi %d", (unsigned)input.length(), MAX_INPUT, WiFi.RSSI());
  else
    snprintf(b, sizeof(b), "%u/%d NO WIFI", (unsigned)input.length(), MAX_INPUT);
  notice = b;
  render();
}

// ---------- network ----------
int hexv(uint8_t c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return 0;
}

void addChar(uint8_t c) {
  if (!reply.length() && (c == '\n' || c == ' ')) return;     // skip leading blanks
  if ((c == '\n' || (c >= 32 && c < 127)) && reply.length() < MAX_REPLY) reply += (char)c;
  dirty = true;
}

// Handles plain bodies and chunked bodies (tunnels/proxies may chunk even for HTTP/1.0)
void bodyByte(uint8_t c) {
  if (!chunked) { addChar(c); return; }
  switch (cs) {
    case CS_SIZE:
      if (c == '\n') cs = chunkLeft ? CS_DATA : CS_DONE;
      else if (c == ';') cs = CS_EXT;
      else if (c != '\r') chunkLeft = chunkLeft * 16 + hexv(c);
      break;
    case CS_EXT:
      if (c == '\n') cs = chunkLeft ? CS_DATA : CS_DONE;
      break;
    case CS_DATA:
      addChar(c);
      if (--chunkLeft == 0) cs = CS_CRLF;
      break;
    case CS_CRLF:
      if (c == '\n') { cs = CS_SIZE; chunkLeft = 0; }
      break;
    case CS_DONE:
      break;
  }
  if (cs == CS_DONE) finished = true;
}

void finish() {
  net.stop();
  if (!reply.length()) reply = "(no reply)";
  wrapText(reply, lines);
  scrollTop = 0;
  state = SHOW;
  showNotice("up/dn scroll, esc=new");
}

void fail(const char* msg) {
  net.stop();
  state = EDIT;
  refreshEdit();
  showNotice(msg);
}

void startQuery() {
  if (WiFi.status() != WL_CONNECTED) { showNotice("no wifi"); return; }
  showNotice("connecting...");
#if USE_TLS
  net.setInsecure();      // skips certificate checks; see section 7 for pinning a CA
  bool ok = net.connect(SERVER_HOST, SERVER_PORT);
#else
  bool ok = net.connect(SERVER_HOST, SERVER_PORT, 5000);
#endif
  if (!ok) { showNotice("server unreachable"); return; }

  net.printf("POST /ask HTTP/1.0\r\nHost: %s\r\nX-Token: %s\r\n"
             "Content-Type: text/plain\r\nContent-Length: %u\r\nConnection: close\r\n\r\n",
             SERVER_HOST, AUTH_TOKEN, (unsigned)input.length());
  net.print(input);

  reply = ""; hdr = "";
  chunked = false; finished = false; dirty = false;
  cs = CS_SIZE; chunkLeft = 0;
  wrapText(input, lines);
  scrollTop = max(0, (int)lines.size() - (ROWS - 1));
  state = WAIT_HDR;
  lastRx = millis();
  showNotice("thinking... Esc=cancel");
}

void pumpStream() {
  while (net.available() && !finished) {
    int c = net.read();
    if (c < 0) break;
    lastRx = millis();
    if (state == WAIT_HDR) {
      hdr += (char)c;
      if (hdr.endsWith("\r\n\r\n")) {
        int code = hdr.substring(9, 12).toInt();
        if (code == 401) { fail("bad token"); return; }
        if (code != 200) {
          char b[28];
          snprintf(b, sizeof(b), "server error %d", code);
          fail(b);
          return;
        }
        String h = hdr;
        h.toLowerCase();
        chunked = h.indexOf("transfer-encoding: chunked") >= 0;
        state = STREAMING;
      } else if (hdr.length() > 1500) {
        fail("bad response");
        return;
      }
    } else {
      bodyByte((uint8_t)c);
    }
  }

  if (finished || (!net.connected() && !net.available())) {
    if (state == WAIT_HDR) fail("server closed"); else finish();
    return;
  }
  if (millis() - lastRx > REPLY_TIMEOUT) { fail("timeout"); return; }

  if (state == STREAMING && dirty && millis() - lastDraw > 150) {
    dirty = false;
    lastDraw = millis();
    wrapText(reply, lines);
    scrollTop = max(0, (int)lines.size() - (ROWS - 1));
    char b[32];
    snprintf(b, sizeof(b), "%u chars  Esc=stop", (unsigned)reply.length());
    showNotice(b);
  }
}

// ---------- keyboard ----------
int readKey() {
  KB.requestFrom(CARDKB_ADDR, 1);
  if (KB.available()) return KB.read();     // 0 = no key
  return 0;
}

void handleKey(int k) {
  if (state == EDIT) {
    if (k == 0x0D) { if (input.length()) startQuery(); }
    else if (k == 0x08 || k == 0x7F) { if (input.length()) input.remove(input.length() - 1); refreshEdit(); }
    else if (k == 0x1B) { input = ""; refreshEdit(); }
    else if (k >= 32 && k < 127 && input.length() < MAX_INPUT) { input += (char)k; refreshEdit(); }
  } else if (state == SHOW) {
    int maxTop = max(0, (int)lines.size() - (ROWS - 1));
    if (k == 0xB6 && scrollTop < maxTop) { scrollTop++; render(); }      // down
    else if (k == 0xB5 && scrollTop > 0) { scrollTop--; render(); }      // up
    else if (k == 0x0D || k == 0x1B) { input = ""; state = EDIT; refreshEdit(); }
  } else if (k == 0x1B) {                    // WAIT_HDR or STREAMING
    if (state == STREAMING) finish(); else fail("cancelled");
  }
}

// ---------- main ----------
void setup() {
  Serial.begin(115200);
  u8g2.begin();                              // also starts Wire on GPIO18/17
#if !KB_SHARED_BUS
  Wire1.begin(KB_SDA, KB_SCL);
#endif
  u8g2.setFont(u8g2_font_5x8_tr);
  u8g2.clearBuffer();
  u8g2.drawStr(0, 10, "connecting wifi...");
  u8g2.sendBuffer();

  WiFi.mode(WIFI_STA);
  wifiMulti.addAP(WIFI_SSID_1, WIFI_PASS_1);
#ifdef WIFI_SSID_2
  wifiMulti.addAP(WIFI_SSID_2, WIFI_PASS_2);
#endif
  uint32_t t0 = millis();
  while (wifiMulti.run(8000) != WL_CONNECTED && millis() - t0 < 30000) {}
  refreshEdit();
}

void loop() {
  if (state == WAIT_HDR || state == STREAMING) pumpStream();

  static uint32_t lastPoll = 0, lastWifiTry = 0;
  if (millis() - lastPoll > 30) {
    lastPoll = millis();
    int k = readKey();
    if (k) handleKey(k);
  }

  if (state == EDIT) {
    if (WiFi.status() != WL_CONNECTED && millis() - lastWifiTry > 10000) {
      lastWifiTry = millis();
      wifiMulti.run(2000);
    }
    if (millis() - lastStatus > 3000) { lastStatus = millis(); refreshEdit(); }
  }
  delay(1);
}
```

The request is sent as HTTP/1.0 on purpose: the server then just streams the body and closes the connection, so the firmware needs no real HTTP library and the keyboard stays responsive while text arrives.

## 6. Bring-up order

1. Start the relay and confirm the `curl` test from section 4.2 streams text.
2. Flash the firmware. The OLED should show `connecting wifi...`, then `_` with a status line like `0/200 wifi -55`.
3. Type to confirm the keyboard. If keys do nothing, redo the I2C scan from section 3.
4. Type `/ping` and press Enter. Expect `pong` almost instantly. That proves Wi-Fi, address, token and relay, with no model involved.
5. Ask a short question. The first answer after a restart can take 10-30 s while the model loads, and text then streams in. The relay's console shows each prompt.
6. Try Esc during a reply to stop it early, and `/new` to reset the chat history.

## 7. Using it away from home

The ESP32 can't run Tailscale or other VPN clients, so it can't join a private tailnet. Options that do work:

|   |   |
|---|---|
|Option|How|
|**Phone hotspot + public HTTPS tunnel**|Put a tunnel in front of the relay (Cloudflare Tunnel: `cloudflared tunnel --url http://localhost:8787`, or Tailscale Funnel). In `secrets.h` set `SERVER_HOST` to the tunnel hostname, `SERVER_PORT 443` and `USE_TLS 1`. The hotspot must be 2.4 GHz (on iPhone, turn on "Maximise Compatibility")|
|**Relay on a cheap cloud VM**|Run `relay.py` behind Caddy or nginx with HTTPS and use the hosted-API backend (section 8). Nothing at home has to be on|
|**Home only**|Plain HTTP on your LAN. Simplest, and the token never crosses the internet|

A tunnel makes the relay reachable from the internet, so the token becomes your only protection. Use a long random one (`openssl rand -hex 16` or longer). `setInsecure()` in the firmware encrypts the connection but doesn't verify the server, so for real use pin the CA with `net.setCACert(rootCaPem)` (the root certificate of your tunnel's HTTPS certificate chain) instead.

## 8. Hosted API backend (optional)

To skip running a model, switch the relay's backend with environment variables:

```
BACKEND=anthropic
ANTHROPIC_API_KEY=your-key
ANTHROPIC_MODEL=claude-haiku-5-5
MAX_TOKENS=250
TERMINAL_TOKEN=yourtoken
```

The API key stays on the relay and never touches the board. This backend returns the whole reply at once instead of streaming it. Short replies cost little but not nothing, so keep `MAX_TOKENS` modest and check the API's current pricing.

## 9. Tuning

- **Reply length:** change the word limit in `SYSTEM` and `MAX_TOKENS`. The 7-row screen reads best at under about 100 words, but longer replies scroll fine with Up/Down.
- **Speed:** a 1B model on a Pi 5 streams at a readable pace. Larger models on a laptop answer better but the first token takes longer.
- **Battery:** the ESP32 uses Wi-Fi modem sleep by default. For a handheld, add a screen-off timeout (`u8g2.setPowerSave(1)` after N seconds idle, wake on keypress). Expect hours rather than days on a small LiPo.
- **Two networks:** the firmware tries `WIFI_SSID_1` then `WIFI_SSID_2`, so one build covers home Wi-Fi and a phone hotspot.
- **Better typing:** the CardKB Fn layer gives symbols. A BBQ10-style I2C keyboard could replace `readKey()`.

## 10. Troubleshooting

|   |   |
|---|---|
|Symptom|Likely cause / fix|
|`NO WIFI`|2.4 GHz only (no 5 GHz-only SSIDs), wrong password, WPA3-only or captive-portal network|
|`server unreachable`|Wrong IP/port, relay not running, started without `--host 0.0.0.0`, or a firewall blocking 8787|
|`bad token`|`AUTH_TOKEN` in `secrets.h` differs from `TERMINAL_TOKEN` on the relay|
|`server error 4xx/5xx`|Check the relay's console. A 500 usually means Ollama isn't running or the model isn't pulled|
|`server closed`|Relay crashed or restarted mid-request. See `journalctl -u terminal-relay`|
|`timeout`|Model took over 90 s (a big model loading on a slow Pi). Raise `REPLY_TIMEOUT` or use a smaller model|
|Blank OLED|Pins 18/17 wrong or the OLED isn't at 0x3C. Run the I2C scanner|
|Typing does nothing|CardKB on a different bus or at a different address. Use the scanner and `KB_SHARED_BUS 0`|
|Garbled or doubled text|Make sure the relay has the cleaning step and your firmware is the version above|
|Board resets on upload loop|Hold BOOT, tap RST, release BOOT, then upload|

## 11. Security and limits

- On a plain-HTTP LAN setup, the prompt, reply and token travel unencrypted on your Wi-Fi. That's fine at home, but use HTTPS (section 7) for anything else.
- The relay keeps one shared chat history and has no rate limiting. Don't expose it publicly without a strong token, and consider capping requests per minute.
- Output is ASCII only, replies are capped at 4,000 characters, and the prompt at 200.
- Want an off-grid fallback later? The LoRa guide's firmware can be combined with this one: keep the UI code, and swap the transport depending on whether Wi-Fi is connected.