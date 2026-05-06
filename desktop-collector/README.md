# desktop-collector/

Local-first desktop collector for Panopticon. **v0.1 — platform data-export importers shipped.**

## What it does today

Reads platform-issued data exports (Google Takeout for YouTube, Spotify "Account data" or "Extended streaming history") and writes Panopticon-compatible NDJSON files. You request the export from the platform, unzip it, run this collector against the folder, then transfer the NDJSON to your phone and import it via the in-app Import screen.

## Why this shape

Modern Android sandboxes browser and platform data hard. The realistic path to behavioral history from these services is the official GDPR/CCPA data export — you're legally entitled to it and it's *deeper* than what the app's UI ever shows. This collector is the bridge between those exports and the canonical event log on your phone.

There is no daemon, no background service, no auto-sync. You run it explicitly when you've downloaded a fresh export.

## Install

Stdlib-only — no `pip install` requirements beyond Python 3.10+.

```bash
cd desktop-collector
python -m pip install -e .
```

That installs a `panopticon-collector` script.

For dev:

```bash
python -m pip install -e ".[dev]"
pytest
```

## Quick start

### YouTube (Google Takeout)

1. Visit [takeout.google.com](https://takeout.google.com)
2. Deselect everything, then select only **YouTube and YouTube Music**
3. Export → download the `.zip` → unzip
4. Point the collector at the unzipped folder:

```bash
panopticon-collector import ~/Downloads/Takeout \
  --output ~/panopticon-exports/youtube.ndjson
```

You'll get one `media.video_view` event per video watched and one `browse.search_query` per YouTube search.

### Spotify

1. Visit [spotify.com/account/privacy](https://www.spotify.com/account/privacy)
2. Request **Account data** (5-day turnaround, last year of listening) and/or **Extended streaming history** (30-day turnaround, full history with `ms_played`, shuffle, skip data)
3. When the email arrives, download and unzip
4. Run:

```bash
panopticon-collector import ~/Downloads/MyData \
  --output ~/panopticon-exports/spotify.ndjson
```

You'll get one `media.audio_play` event per stream.

## Importers

```bash
panopticon-collector list-importers
```

| Id | Source |
|---|---|
| `youtube_takeout` | YouTube + YouTube Music history from Google Takeout |
| `spotify_export` | Spotify Account Data and Extended Streaming History |

## Output format

NDJSON — one JSON object per line, each conforming to [`schema/events.schema.json`](../schema/events.schema.json):

```json
{"timestamp_utc": 1715116800000, "timezone_offset": -300, "source": "media", "event_type": "video_view", "package_name": null, "payload_json": {"title": "...", "platform": "youtube", "video_id": "...", "channel": "...", "url": "...", "source_doc": "google_takeout/youtube/watch-history"}, "schema_version": 1}
```

The phone-side Import screen streams the file (one event per line), validates against the schema, previews counts by `(source, event_type)`, and persists on confirmation.

## Roadmap

The v1 importers are **YouTube** and **Spotify** because their formats are well-documented and stable. Coming next:

- **TikTok** — `Account → Settings → Account → Download your data`
- **Instagram / Meta** — `accountscenter.facebook.com → Download Your Information`
- **Reddit** — `reddit.com/settings/data-request`
- **Browser history** — read Chrome / Firefox / Edge SQLite history files directly

Open an importer's `.py` file under `panopticon_collector/importers/` to see the parsing approach if you want to add your own.

## Why no third-party deps

A behavioral-data tool that pulls in 20 PyPI packages is hard to audit and breaks every time a transitive dep changes. v1 sticks to stdlib (json, csv, re, pathlib). That stays true as long as it's reasonable.
