# android/

Flutter mobile app + native Android Kotlin layer. **To be scaffolded.**

This directory is a placeholder. The actual Flutter project will be created via `flutter create` from a machine with the Android SDK and Android Studio installed (which the laptop session that initialized this repo did not have).

## What goes here

```
android/
├── lib/                          # Flutter UI (Dart)
│   ├── main.dart
│   ├── ui/                       # Screens, widgets
│   ├── data/                     # DB (Drift), repositories
│   ├── coaching/                 # AI coaching layer (Phase 5)
│   └── context/                  # User context schema, intake flow (Phase 2)
├── android/                      # Native Kotlin
│   └── app/src/main/kotlin/com/velovault/panopticon/
│       ├── PanopticonApp.kt
│       ├── PanopticonForegroundService.kt
│       ├── services/             # Accessibility, NotificationListener
│       └── collectors/           # UsageStats, screen state, app focus
├── pubspec.yaml
└── pubspec.lock
```

## To scaffold (next session, on a desktop with Android SDK)

```bash
cd panopticon
flutter create --org com.velovault --project-name panopticon --platforms android,windows,macos,linux android
# (Yes, the directory is named `android`. Inside it lives a multi-platform Flutter project; we'll target Android first and desktop later.)
```

Then add dependencies in `android/pubspec.yaml`:

- `drift` + `drift_dev` for SQLite.
- `flutter_riverpod` for state management.
- `path_provider`, `permission_handler` for permission/file management.

## Why this isn't done yet

The repository was bootstrapped from a laptop without an Android development environment. Flutter scaffolding generates ~150 files, most of which are platform-specific and easier to verify on the machine that will actually build APKs. Doing it from a different machine would either:

1. Generate the project with platform-specific paths that match the wrong machine, or
2. Skip platform generation, leaving the project broken.

So we deliberately deferred this step. Pick it up on the desktop machine with Android Studio installed.
