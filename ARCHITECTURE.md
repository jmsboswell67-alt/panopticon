# Architecture

This document describes Panopticon's system design at the level a forker needs to navigate the codebase. It is updated as the project advances through phases.

## Top-level shape

Panopticon is a **monorepo** containing:

1. A **Flutter mobile app** (`android/`) targeting Android (full feature scope) and iOS (degraded-feature client — see [iOS positioning](#ios-positioning) below). Kotlin native layer for the Android-side OS collectors.
2. A **Python desktop collector** (`desktop-collector/`) that runs on the user's computer. *(Phase 4 — not present yet.)*
3. A **canonical schema** (`schema/`) defining the JSON shape of every event, context document, and insight.
4. **Coaching prompts** (`prompts/`) — system prompts, persona definitions, and trauma-informed framing for the AI layer. *(Phase 5.)*

There is no central server. There is no shared database between users. Every install is an island.

```
                        ┌────────────────────────────┐
                        │         Phone              │
                        │                            │
                        │  Flutter UI ── Drift/SQLite│
                        │      │             ▲       │
                        │      ▼             │       │
                        │  Native Android    │       │
                        │  Foreground Svc    │       │
                        │   ├── Accessibility│       │
                        │   ├── Notification │       │
                        │   └── UsageStats   │       │
                        └────────────┬───────────────┘
                                     │
                              (optional, off by default)
                                     │
                        ┌────────────▼───────────────┐
                        │   Self-hosted sync target  │  ← user's own server
                        │   (REST / Firebase)        │     OR shared local DB
                        └────────────▲───────────────┘
                                     │
                        ┌────────────┴───────────────┐
                        │         Desktop            │
                        │                            │
                        │  Python collector          │
                        │   ├── active window        │
                        │   ├── browser history      │
                        │   └── calendar import      │
                        └────────────────────────────┘
```

## Data flow (Phase 1)

1. Native Android collectors emit events as they observe OS state changes.
2. A foreground service buffers events in memory.
3. The buffer flushes to the local SQLite database every N seconds or M events (whichever first), via a Kotlin → Dart channel.
4. The Flutter UI reads from SQLite via Drift to render the Today / Permissions / Privacy screens.

No data leaves the device. There is no network call from Phase 1 code paths.

## Key components (Phase 1)

### `PanopticonForegroundService` (Kotlin)

A long-running foreground service with a persistent notification. Responsible for:

- Hosting the three collector services.
- Buffering events and flushing to SQLite.
- Surviving reboots via a `BOOT_COMPLETED` receiver.
- Surviving battery optimization via the user's whitelist grant during setup.

The notification text is honest: "Panopticon is observing your behavior. Tap to view." No tricks, no fake "weather widget" framing.

### Collectors (Kotlin)

- **`AccessibilityCollector`** — observes window state changes, app focus, screen on/off. Phase 1 captures **only metadata** (package name, event type, timestamp). Text content of other apps is **not** captured in Phase 1; that's gated behind a separate explicit toggle in a later phase.
- **`NotificationCollector`** — `NotificationListenerService` capturing `notification_posted` and `notification_removed` events. Captures package, timestamp, title, text — for the user's own behavioral analysis only. Does **not** capture replies the user has not sent.
- **`UsageStatsCollector`** — daily rollups per app via `UsageStatsManager`.

### Local database (Drift / SQLite)

Schema is versioned from v1. Migrations are wired up from the start so future schema changes don't require painful one-time conversions.

Tables (Phase 1):

- `events` — universal event log; every collector writes here.
- `app_sessions` — derived sessions of foreground app usage.
- `notifications` — notification events.
- `daily_rollups` — pre-computed daily aggregates per app.

See [`schema/events.schema.json`](schema/events.schema.json) for the canonical event payload shape.

### Flutter UI

Three screens in Phase 1:

- **Today** — what the system has observed today.
- **Permissions** — status of every permission with deep links.
- **Privacy** — list of all collected data, "export everything as JSON" and "delete everything" buttons.

**State management: Riverpod.** Locked in. Reasoning: compile-safe provider lookup catches missing-provider errors at build time rather than at runtime; reads don't require `BuildContext` (easier to unit-test); mature dev tooling in Flutter Inspector; robust code generation via `riverpod_generator`. Bloc is a reasonable alternative; the differences are small enough that picking one and committing matters more than which.

## Architecture decisions (Phase 1)

### Why a foreground service?

Android requires a foreground service for long-running background work. Without it, the OS will kill our collectors within minutes. The persistent notification is the price of admission.

### Why batch DB writes?

App focus changes can fire dozens of times a minute on heavy multitasking. Hammering SQLite per event burns battery and gains nothing. We buffer in memory and flush every ~10 seconds or every 50 events.

### Why versioned schema from day one?

Even at v1, the migration path is wired up. The cost is low; the cost of bolting it on later is high.

### Why no analytics?

Panopticon does not phone home. Ever. Crash reporting, telemetry, "anonymous usage stats" — none of these. If you want crash reports as a developer, ship a separate debug build with explicit opt-in.

### Why Flutter for desktop UI later?

Originally the brief specified a Python *collector* for desktop and a Flutter *UI* for mobile. We're planning to extend the Flutter UI to desktop targets (Windows / macOS / Linux) so a single codebase serves both. The Python collector remains the headless data source on desktop.

### iOS positioning

iOS does not allow the equivalent of Panopticon's Android system collectors. Accessibility access is heavily restricted, there is no NotificationListener equivalent, and `UsageStatsManager` has no analogue. So iOS is positioned as a **degraded-feature client**, sharing the Flutter codebase with Android but with a smaller feature scope:

- **Phase 1 on iOS**: a "view your data" client. No passive collection. Reads aggregates from the home server via sync.
- **Phase 2+ on iOS**: manual journaling, screening intake, HealthKit-equivalent of Health Connect ingestion, viewing insights.
- **Never on iOS**: the Android-style system collectors, because the platform doesn't allow them.

The Flutter project is created with both `android` and `ios` platforms from day one — forkers on iPhones can clone, build, and run a useful subset without further work on our part. iOS is not "second-class"; it's "different feature scope, shared codebase."

## Extending the system

Adding a new data source requires:

1. Define event types in [`schema/events.schema.json`](schema/events.schema.json).
2. Implement a collector that emits those events.
3. Add a permission entry to the setup wizard.
4. Document the source in [`docs/data-sources.md`](docs/data-sources.md).

See [`docs/data-sources.md`](docs/data-sources.md) for the existing collectors as a template.
