# Data Flow

> How data moves through Panopticon — from the moment a phone collector observes an event to the moment the user reads an insight derived from it. Forward-looking; Phase 4 implementation.

This document is the canonical reference for the system's runtime topology. [`ARCHITECTURE.md`](../ARCHITECTURE.md) covers the per-component design; this document covers what flows between components.

---

## Reference architecture

Panopticon is designed to run on a small set of physical machines with distinct roles. You don't need all of them — Phase 1 runs entirely on a phone — but the full architecture below is the Phase 4+ target.

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  PHONE (Android, always with you)                                │
│    ├── Foreground service + collectors                           │
│    │     (Accessibility / NotificationListener / UsageStats)     │
│    ├── Local SQLite                                              │
│    │     (60-day rolling raw events + lifetime rollups)          │
│    └── Sync agent  ──────────┐                                   │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │  (only on home WiFi)
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  HOME SERVER (always-on, low-power node — e.g. Apple Silicon     │
│                Mac mini, mini PC, or Raspberry Pi 5)             │
│                                                                  │
│    ├── DNS resolver + query logger (AdGuard Home / Pi-hole)      │
│    ├── Sync REST endpoint  ◄────── phone deltas                  │
│    │                       ◄────── desktop deltas                │
│    ├── Aggregator (nightly: rollups, retention pruning)          │
│    ├── Embedding store (semantic search over journal/insights)   │
│    └── Long-term store on dedicated SSD                          │
│         (rollups, insights, screening scores: forever)           │
│                                                                  │
└─────────┬─────────────────────────────────────────┬──────────────┘
          │ pull aggregates                         │
          ▼                                         ▼
┌──────────────────────────────┐   ┌──────────────────────────────┐
│                              │   │                              │
│  DESKTOP (on when used)      │   │  OPTIONAL: ANTHROPIC API     │
│                              │   │                              │
│  ├── Active-window collector │   │  Frontier-quality coaching   │
│  ├── Ollama (16GB+ VRAM      │   │  for high-stakes insights.   │
│  │    runs 13–32B models)    │   │  Prompt caching enabled to   │
│  └── Heavy analysis          │   │  keep cost trivial.          │
│                              │   │                              │
└──────────────────────────────┘   └──────────────────────────────┘
```

---

## Roles per node

The architecture intentionally separates **always-on infrastructure** from **episodic compute**. Different machines for different uptime profiles keeps the always-on power budget low and avoids forcing your daily-driver desktop into 24/7 service duty.

### Phone (Android)

- **Always with you, sometimes online.**
- Runs the OS-level collectors that depend on Android-specific permissions.
- Maintains a local SQLite store with the same schema as the server. The phone is fully functional offline — it just doesn't replicate.
- Holds the **last 60 days of raw events** locally, plus all-time rollups. Older raw events are pruned after they've synced and been rolled up server-side.

### Home server

- **Always on. Low power. Low maintenance.**
- The canonical store for everything that should outlive the phone's rolling window.
- Runs the DNS resolver for your home network (and logs queries for behavioral analysis).
- Receives sync deltas from phone and desktop, runs the nightly aggregator, applies retention pruning.
- **What it is NOT**: a heavy compute node. It does not run frontier-class LLMs. It may run small embedding models or 7B-class chat models if the hardware allows, but its primary job is *data custody*, not inference.
- **Reference hardware sizing**: see [Hardware sizing guidance](#hardware-sizing-guidance) below.

### Desktop (optional)

- **On when you're using it.**
- Runs the active-window collector while you're working.
- Runs Ollama for local LLM inference when GPU-class compute is needed (most coaching, embedding generation, semantic search re-indexing).
- Pulls aggregates from the home server when active. Does not store the canonical copy.

### Anthropic API (optional)

- **Frontier coaching only.** Most insights run locally via Ollama on the desktop.
- Used selectively for high-stakes outputs (deep multi-week reflections, values audits, anything where the quality gap between 32B local and Opus 4.7 actually matters).
- Prompt caching enabled — the user's context document is stable, so it caches once and dramatic cost reductions follow on subsequent calls.
- Per [`PRIVACY.md`](../PRIVACY.md), this is the one path where data leaves the device. Off by default. Each call is gated by an explicit per-insight or per-session toggle.

---

## Sync strategy

The phone is the only mobile node. The strategy here is "sync constantly when you can; never sync when you shouldn't."

### When to sync

| Trigger | Frequency | Rationale |
|---|---|---|
| Phone on home WiFi, screen unlocked | Every ~10 min | Keeps server within ~10 min of phone state during the day. |
| Phone plugged in at home, between 2–4am | Once nightly | Catch-up push of anything missed during the day. |
| User taps "Sync now" in the app | Immediate | Manual override for debugging or before traveling. |

### When NOT to sync

- **Never on cellular.** Battery cost, data cost, no privacy benefit. The phone collects fine offline; it just defers replication.
- **Never on untrusted WiFi.** The phone's sync agent only fires when the connected SSID matches a configured "home" allowlist.
- **Never if the home server hasn't been seen in N days.** If the server is unreachable for an extended period, the phone surfaces a notification rather than silently retrying forever.

### What gets synced

Phone → server, in order of priority:

1. **Events** — newest first, in batches of ~500. Server ACKs each batch; phone advances its local cursor only after ACK.
2. **Screening responses** (if any since last sync).
3. **Self-report responses** (Tier 4 from [`custom-measurements.md`](custom-measurements.md)).
4. **Context document changes** — only if the user has edited intake fields.

Server → phone, opportunistically:

1. **Aggregates** — pre-computed rollups for the dashboard, so the phone can render trajectory views even when offline.
2. **Insights** — coaching outputs the user hasn't seen yet.

### What gets NOT synced

- Raw DNS logs (server-only — they describe network behavior, not phone behavior).
- Embedding indices (server-only — too large; the phone queries the server for semantic search results when on home WiFi).
- The Anthropic API key, if configured (server-only).

### Why no geofencing

The intuitive trigger — "sync when I leave the house" — is harder than it looks: geofencing is a battery drain, and worse, syncing *as* you leave already implies you've lost server connectivity. Opportunistic on-WiFi sync covers ~99% of cases without any location services. The phone never asks for the location permission solely for sync purposes.

---

## Storage layout (home server)

The home server uses a two-disk pattern: an internal disk for the OS and applications, an external SSD for Panopticon data. This separation matters: it isolates project data from OS volume capacity pressure, makes data portable to a replacement server, and survives an OS reinstall without backup ceremony.

### Internal disk (OS volume)

- Operating system + applications.
- Server software (DNS resolver, sync endpoint, aggregator).
- **Not** Panopticon data.

### External SSD (Panopticon data home)

```
/panopticon/
├── db/
│   ├── events.db              # Phase 1: raw events, 60-day rolling
│   ├── rollups.db             # Daily/weekly aggregates, lifetime
│   ├── insights.db            # LLM outputs, lifetime
│   ├── screening.db           # Validated screen responses + scores, lifetime
│   ├── context.db             # Versioned context document, lifetime
│   └── self_report.db         # Tier 4 self-report, lifetime
├── dns_logs/
│   └── (rolling 30-day archive, daily-rotated)
├── embeddings/
│   └── (sentence-transformer indices over journal + insights)
├── backups/
│   └── (nightly snapshots, configurable retention)
└── exports/
    └── (user-initiated JSON dumps, gitignored at rest)
```

Recommended external SSD: 1TB USB-C NVMe (e.g. Samsung T7 Shield, Crucial X9 Pro, SK Hynix Tube T31). At realistic data volumes (see [`retention-policy.md`](retention-policy.md)) this gives many years of headroom before approaching capacity.

---

## The DNS-over-HTTPS footgun

Modern Android (and iOS) ship with **encrypted DNS** enabled by default — Android's Private DNS sends queries directly to Cloudflare or Google over TLS, bypassing your home server's DNS resolver entirely. If you set up logging expecting to capture phone DNS queries, you'll see almost nothing.

Three resolutions, in increasing order of completeness:

### Option 1 — Disable Private DNS on the phone

Settings → Network & Internet → Private DNS → Off.

- **Pro**: simple, immediate.
- **Con**: lowers DNS privacy on networks that aren't yours. On public WiFi, your DNS queries travel in plaintext.

### Option 2 — Run your own DoH/DoT server

Configure the home server to host a DNS-over-HTTPS endpoint. Point the phone's Private DNS at your domain. Your queries get logged at home but stay encrypted on the wire elsewhere.

- **Pro**: works on any network the phone connects to. Privacy preserved.
- **Con**: requires a domain + TLS cert. AdGuard Home supports this natively; the setup is a real chunk of work.

### Option 3 — Block external DoH/DoT at the router

Block port 853 (DoT) and known DoH endpoints at the router. Forces phones to fall back to the local resolver while at home; phones on cellular still use external DNS.

- **Pro**: works for all home devices, no per-device config.
- **Con**: home-network-only. Cellular DNS is invisible. Some apps actively detect and complain about DoH being blocked.

Option 2 is the "right" answer if you want comprehensive logging. Option 1 is the quick start for getting useful data fast. Document whichever you chose in your local config and revisit annually as Android's DNS handling evolves.

---

## The third-party data rail

Home network monitoring captures DNS queries and (optionally) flow data from **every device on your network** — TVs, smart speakers, anyone else's phone connected to your WiFi, guest devices. This collides directly with the [`ETHICS.md`](../ETHICS.md) "no surveillance of other people" rail.

### If you live alone

It's all your data. No conflict.

### If you don't live alone

Three honest paths:

1. **Filter to known device MACs.** Maintain a configured allowlist of MAC addresses corresponding to your own devices. Drop logs from any other source at ingestion. Phones rotate MACs on modern Android/iOS, so this requires periodic refresh.
2. **Document explicit consent or exclusion.** Have the conversation with anyone else on the network. Record their consent (or their exclusion) in a config file alongside the project. The config file is gitignored under `personal/`.
3. **Disable network monitoring entirely.** Phone-side collectors still work; you simply don't log network traffic. The phone-only data is plenty for the project's coaching goals.

The default in the code is **paranoid**: if no device allowlist is configured, the DNS logger drops every record on ingestion. You have to explicitly opt-in by configuring your devices.

---

## Failure modes (what happens when something is offline)

Designed-for failure cases. None of these should produce data loss or service degradation visible to the user.

| Failure | Behavior |
|---|---|
| Phone offline (airplane mode, dead battery) | Local collection continues. Sync resumes when next on home WiFi. No data loss. |
| Home server offline (rebooting, power loss) | Phone sync fails silently and retries on next interval. Phone surfaces a notification only after the server has been unreachable for >24h. |
| External SSD on server fails | Aggregator and sync endpoint fail loudly. Internal-disk-only metadata records the failure. Phone backs off sync. User must replace SSD and restore from backup. |
| Desktop offline (typical — it's not always on) | No effect on data collection. Active-window events from desktop are simply absent during off periods. |
| Anthropic API unreachable / rate-limited | Coaching layer falls back to local Ollama (if configured) or surfaces "API unavailable" without losing the user's request — the request is queued and re-tried. |
| Embedding index corrupted | Semantic search returns "unavailable." Other features unaffected. Index is rebuilt on next aggregator run. |

---

## What runs locally vs. via API

The decision rule, restated:

- **Aggregation, embeddings, retrieval, screening scoring**: always local. None of these need an LLM, much less a frontier one.
- **Routine coaching (weekly review, trajectory views, anomaly summaries)**: local Ollama on the desktop is the default.
- **High-stakes coaching (values audits, multi-month reflections, anything where the quality gap matters)**: Anthropic API by user choice, gated per insight.

This keeps the privacy-first ethos intact: most insights never leave your network. The API is opt-in per insight, not a blanket toggle.

---

## Hardware sizing guidance

For forkers wanting to replicate this setup:

### Always-on home server

- **Minimum viable**: Raspberry Pi 5 (8GB) + 1TB external NVMe SSD via USB-C. ~5–8W idle. Handles all services except local LLM hosting.
- **Recommended**: Apple Silicon Mac mini (8GB+ unified memory) or x86 mini PC with 16GB RAM (e.g. Intel N100-based Beelink/Minisforum), 1TB external NVMe SSD. ~6–15W idle. With 16GB+ unified memory, can host small/medium local models in addition to services.
- **Avoid**: using your daily-driver desktop. Different uptime profile, different power budget.

### LLM compute node

- **Minimum viable**: any GPU with 8GB+ VRAM for 7B-class models.
- **Recommended**: 16GB+ VRAM for 13B-32B models, which is the sweet spot for routine coaching quality.
- **Notable Apple Silicon advantage**: unified memory means a Mac with 32GB+ RAM can run 70B-class models at usable speed via Metal-accelerated Ollama, without requiring a discrete GPU. If your always-on server is a high-RAM Apple Silicon machine, the LLM compute node may not need to exist as a separate machine.

The architecture works at all of these scales. The decision is just how much always-on capability vs. how much "spin up the desktop when needed."

---

## Related

- [`ARCHITECTURE.md`](../ARCHITECTURE.md) — per-component design
- [`PRIVACY.md`](../PRIVACY.md) — what's collected, where it lives, deletion guarantees
- [`retention-policy.md`](retention-policy.md) — tiered retention by data type
- [`self-hosting.md`](self-hosting.md) — sync server options
- [`data-sources.md`](data-sources.md) — every collector and what it captures
