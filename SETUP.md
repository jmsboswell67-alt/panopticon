# Setup

This guide walks you through cloning Panopticon and getting it running on your own device.

**Status:** Phase 1 — repository skeleton. The Android app project under `android/` is being scaffolded. If you're reading this before the Flutter scaffolding lands, the "build the app" steps below are forward-looking.

---

## Prerequisites

- **Git** + **GitHub CLI** (optional, for cloning).
- **Flutter SDK** (stable channel). Install: <https://docs.flutter.dev/get-started/install>
- **Android SDK + Android Studio**. Install via Android Studio's SDK manager.
- **A real Android device** running Android 10+. The emulator lies about service lifecycle behavior — you need a real device for anything beyond UI work.
- **Java 17** (Android Gradle Plugin requirement at the time of writing).
- *(Phase 4+)* **Python 3.11+** for the desktop collector.

## Clone

```bash
git clone https://github.com/jmsboswell67-alt/panopticon.git
cd panopticon
```

## Build the Android app

*(Forward-looking — these instructions become live once Phase 1 Flutter scaffolding lands.)*

```bash
cd android
flutter pub get
flutter run
```

If you have multiple devices connected, `flutter devices` lists them and `flutter run -d <device-id>` targets one.

## Grant permissions on first launch

The setup wizard walks you through these one at a time. Each requires a deep link into Android Settings — Android does not allow apps to grant these to themselves.

1. **Accessibility Service** — observes app focus and screen state.
2. **Notification Listener** — captures notifications you receive.
3. **Usage Stats** — provides daily app usage rollups.
4. **Battery Optimization Whitelist** — without this, Android will kill the foreground service on schedule.
5. **(Optional) Boot on startup** — restarts the service after a reboot.

For each, the wizard explains *why* in plain language before opening Settings. You can revisit the Permissions screen anytime to see status.

## OEM quirks

- **Pixel / stock Android** — the reference target. Should "just work" once permissions are granted.
- **Samsung One UI** — has additional aggressive battery optimization. You may need to disable "Put unused apps to sleep" for Panopticon. *(To be documented in detail when tested.)*
- **Xiaomi MIUI / OPPO ColorOS / Huawei EMUI** — known to be hostile to background services. Forkers on these devices are encouraged to test and contribute findings.

## Set up your personal data

Per [PRIVACY.md](PRIVACY.md), your filled-in personal context lives only on your device. The repo only contains the empty schema in [`schema/context.schema.json`](schema/context.schema.json).

If you want to keep a local-only working copy of your context document for development purposes, put it under `personal/` — that directory is gitignored:

```bash
mkdir -p personal
cp schema/context.schema.json personal/context.json
# Now edit personal/context.json with your real answers.
```

`personal/` will never be tracked by git. Verify with `git status` before any commit.

## (Phase 5+) Configure an LLM backend

When the coaching layer ships in Phase 5, copy `.env.example` to `.env` and fill in **one** of:

```bash
# Option A: Anthropic Claude
ANTHROPIC_API_KEY=sk-ant-...

# Option B: OpenAI
OPENAI_API_KEY=sk-...

# Option C: Local Ollama (no key needed)
OLLAMA_BASE_URL=http://localhost:11434
```

`.env` is gitignored. Never commit it.

## Build APKs

CI builds debug APKs on every push to `main`. Find them under the GitHub Actions run artifacts.

For a release build locally:

```bash
cd android
flutter build apk --release
```

The output APK is at `android/build/app/outputs/flutter-apk/app-release.apk`. Sideload it via `adb install` or by transferring to your phone.

## Troubleshooting

- **Service gets killed within minutes** — battery optimization isn't whitelisted. Revisit the Permissions screen.
- **Accessibility events stop firing after a while** — Android sometimes silently revokes accessibility permission across reboots on aggressive OEMs. Re-grant.
- **`flutter doctor` complains** — fix that first; this project doesn't work around upstream Flutter setup issues.

## Where to go next

- [ARCHITECTURE.md](ARCHITECTURE.md) — understand what's running and where.
- [PRIVACY.md](PRIVACY.md) — what gets collected.
- [ETHICS.md](ETHICS.md) — the hard rails.
- [docs/data-sources.md](docs/data-sources.md) — every collector and what it captures.
