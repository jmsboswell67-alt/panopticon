# android/

Flutter app + native Android Kotlin layer. **Phase 1 in place.**

## What's here

```
android/
├── lib/                                  # Flutter UI (Dart)
│   ├── main.dart
│   ├── data/                             # Drift schema, repository, native bridge, providers
│   ├── permissions/                      # Permission status queries via MethodChannel
│   └── ui/                               # Screens (Today, Permissions, Privacy)
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

What this layer does today, per [`../docs/data-sources.md`](../docs/data-sources.md):

- **Accessibility**: `window_state_changed`, `app_focus_changed` (with dwell), `screen_on`, `screen_off`. Metadata only — no app text content.
- **Notification Listener**: `notification_posted` and `notification_removed`, with title/text/category/priority.
- **UsageStats**: hourly per-app foreground time and launch count rollups, derived from `UsageStatsManager`.
- **Local persistence**: Drift over SQLite. Schema versioned from v1 with the migration block already wired.
- **Privacy controls**: full export-to-JSON + delete-everything from the Privacy tab.

What this layer does NOT do yet (deferred to later phases):

- Sync to a home server (Phase 4).
- Read text content of any app (Phase 6+, separate explicit toggle).
- AI coaching, briefings, or persona system (Phase 5).
- Manual journal / instrument administration / cognitive tests (Phase 2–3).
