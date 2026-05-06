# android/

Flutter app + native Android Kotlin layer. **Phase 1 + Phase 2 in place.**

## What's here

```
android/
├── lib/                                  # Flutter UI (Dart)
│   ├── main.dart
│   ├── data/                             # Drift schema, repositories, native bridge, providers
│   ├── instruments/                      # Instrument model + loader + scoring engine
│   ├── journal/                          # Rule-based journal pipeline + safety scanner
│   ├── permissions/                      # Permission status queries via MethodChannel
│   └── ui/                               # Screens (Today / Log / Permissions / Privacy + entry surfaces)
├── assets/instruments/                   # Bundled JSON copies of the canonical instruments/
├── tool/sync_assets.dart                 # Re-syncs instrument JSON from repo root
├── android/app/src/main/
│   ├── AndroidManifest.xml               # Foreground service + 3 collector services
│   ├── kotlin/com/velovault/panopticon/
│   │   ├── PanopticonApp.kt              # Application — registers notification channel
│   │   ├── PanopticonForegroundService.kt
│   │   ├── PanopticonChannel.kt          # Method/EventChannel handler
│   │   ├── EventBuffer.kt                # In-memory ring buffer, drained every 10s
│   │   ├── BootReceiver.kt
│   │   ├── MainActivity.kt
│   │   ├── services/
│   │   │   ├── PanopticonAccessibilityService.kt
│   │   │   └── PanopticonNotificationListener.kt
│   │   └── collectors/
│   │       └── UsageStatsCollector.kt
│   └── res/xml/accessibility_service_config.xml
├── pubspec.yaml
└── pubspec.lock
```

The project targets Android first, with iOS, Windows, macOS, and Linux platforms also generated. Per [`../ARCHITECTURE.md`](../ARCHITECTURE.md), iOS will ship as a degraded-feature client (no system collectors); desktop platforms are placeholders today and become real targets in Phase 4.

## Building

```bash
cd android
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

You'll need:

- Flutter ≥ 3.41
- Android SDK with platform 34 + build-tools 34
- A real Android device (the emulator lies about service lifecycle behavior)

The first launch shows three empty screens. Granting Accessibility, Notification Listener, and Usage Access from the **Permissions** tab starts the foreground service; events begin flowing into the **Today** tab as you use the device.

## Code generation

Drift and Riverpod both rely on `build_runner`. Re-run after editing `lib/data/database.dart` or any `@riverpod`-annotated function:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Phase 1 scope

What the passive collection layer does, per [`../docs/data-sources.md`](../docs/data-sources.md):

- **Accessibility**: `window_state_changed`, `app_focus_changed` (with dwell), `screen_on`, `screen_off`. Metadata only — no app text content.
- **Notification Listener**: `notification_posted` and `notification_removed`, with title/text/category/priority.
- **UsageStats**: hourly per-app foreground time and launch count rollups, derived from `UsageStatsManager`.
- **Local persistence**: Drift over SQLite. Schema versioned from v1 with the migration block already wired.
- **Privacy controls**: full export-to-JSON + delete-everything from the Privacy tab.

## Phase 2 scope

What the manual entry layer does, per [`../docs/screening-instruments.md`](../docs/screening-instruments.md), [`../docs/journal-pipeline.md`](../docs/journal-pipeline.md), [`../docs/custom-measurements.md`](../docs/custom-measurements.md):

- **Generic instrument runner**: loads any `instruments/*.json` and renders likert / 1–10 scale / integer / enum / text items. Handles single-section and multi-part instruments. PHQ-9, GAD-7, WHO-5, IRI, MFQ-30, daily_scales all work without per-instrument code.
- **Scoring engine**: `sum`, `sum_with_reversal`, `sum_times_4`, `mean`, `mean_of_subscales`, `individualizing_minus_binding`. Flag rules with comparison and `in [list]` conditions; severity maps for response-keyed flags (PHQ-9 q9 → watch/concern/urgent).
- **Crisis path**: any `safety_critical` item endorsement and any safety-category flag at concern/urgent severity surface a full-screen crisis resources page (988 / Samaritans / findahelpline / local emergency). Logged as `coach.flag` events.
- **Journal entry**: free-prose textbox, runs the rule-based pipeline before persisting.
- **Rule-based journal pipeline** (Phase 1 of [`../docs/journal-pipeline.md`](../docs/journal-pipeline.md)): keyword-based section segmentation (food/sleep/social/work/exercise/etc.), self-hypothesis detection ("I always X", "Whenever Y, I usually Z"), linguistic metrics (TTR, mean sentence length, ~FK grade). Entity extraction and sentiment are deferred to Phase 5 (LLM-backed).
- **Safety scanner**: regex pass on journal prose and observed-interaction notes for suicidality / self-harm phrasing — emits `coach.flag` and surfaces the crisis screen, conservatively calibrated against false positives like "I could kill for a coffee".
- **Daily check-in**: renders `daily_scales.json` via the generic runner, persisted as `manual.daily_checkin` per the schema.
- **Observed interaction**: timestamped quick-log per the `manual_observed_interaction` payload (category / valence / intensity / parties / notes).
- **Tier labeling**: every measurement screen surfaces its tier ("Validated screen" / "Project-specific self-report") per [`../docs/custom-measurements.md`](../docs/custom-measurements.md).

## Phase 3 scope

External-data ingestion + opt-in in-app text capture:

- **NDJSON import** from the [`../desktop-collector/`](../desktop-collector/) Python tool. Privacy → "Import desktop collector NDJSON" picks a file via the system file picker, parses each line, previews counts by `(source, event_type)`, and persists in a transaction. Re-imports are not yet deduplicated — that lands later.
- **`media` source** added to the schema for streaming consumption events (`media.video_view`, `media.audio_play`, `media.podcast_play`).
- **Per-app text-capture allowlist**. The accessibility service already had the permission; Phase 3 flips `canRetrieveWindowContent` on but gates actual capture by a per-package opt-in list managed in the app. Empty by default — nothing captured. Add TikTok / Instagram / YouTube / etc. via a picker that lists installed launchable apps. Capture is throttled to one snapshot per ~2s per (package, screen-signature). Password fields and EditText input fields are excluded.
- **Schema v2 migration**: adds `text_capture_allowlist` table.

What this layer does NOT do yet (deferred to later phases):

- Re-import deduplication (planned dedup key: `(source, event_type, timestamp_utc, hash(payload))`).
- Trauma-informed intro/exit screens (Phase 2.5 — when ACE-Q / PCL-5 land).
- Self-hypothesis testing against the event log (Phase 3.5 — needs the aggregator).
- Sync to a home server (Phase 4).
- AI coaching, briefings, or persona system (Phase 5).
- Cognitive tests (Phase 3.5+).
- Context intake / values / goals (Phase 2.5 / 3).

## Working with the bundled instruments

The canonical instrument JSON lives at the repo root in `../instruments/`. Flutter bundles a copy at `assets/instruments/`. After editing any canonical file:

```bash
dart run tool/sync_assets.dart
```

The local copies are committed so a fresh `flutter pub get && flutter run` works without a sync step.
