# Panopticon

> A personal behavioral observation and self-coaching system. Local-first. Open source. Built as a research project, not a product.

**Status: Phase 3 — external data ingestion + opt-in text capture.** The Android app, schema, instruments, journal pipeline, manual entry surfaces, desktop collector, and per-app text-capture allowlist are all in place. Builds and runs on a real device.

---

## What this is

Panopticon is a self-instrumentation system. It passively collects behavioral data across phone and desktop, accepts user-provided context (background, diagnoses, goals, values), and uses an AI coaching layer to surface patterns and trajectories over time.

The user is the sole subject. Everything stays on the user's devices by default. There is no cloud account to sign up for. There are no other users.

## What this is NOT

- Not a product. Not on the Play Store. Not for sale.
- Not multi-user. Not a service. There is no backend.
- Not a scoring or ranking system. There are no leaderboards, no demographic comparisons, no predictions about your life outcomes.
- Not surveillance of other people. The system observes the user's own behavior, never third parties.

## Is this for you?

This is a personal research project, released open source so others can fork it. You should consider Panopticon if:

- You're comfortable building Android apps from source and sideloading APKs.
- You understand that "comprehensive behavioral data on yourself" is a sharp tool and want to wield it responsibly.
- You want a local-first system you can fully audit and modify.

You should **not** use Panopticon if:

- You're looking for a polished consumer wellness app — this is a research-grade tool with rough edges.
- You want a system that compares you to other people or predicts outcomes — that's an explicit non-goal here, see [ETHICS.md](ETHICS.md).
- You're hoping to install it without granting Accessibility, Notification Listener, and Usage Stats permissions — those permissions are the whole point.

## Getting started

See [SETUP.md](SETUP.md) for the full setup walkthrough.

Quick version (Phase 1, pre-collectors):

```bash
git clone https://github.com/jmsboswell67-alt/panopticon.git
cd panopticon/android
flutter pub get
flutter run
```

You'll need Flutter, the Android SDK, and a real Android device (the emulator lies about service lifecycle behavior).

## Documents

- [ARCHITECTURE.md](ARCHITECTURE.md) — system design, data flow, what runs where
- [PRIVACY.md](PRIVACY.md) — what's collected, where it lives, how to delete it
- [ETHICS.md](ETHICS.md) — the hard rails enforced in code and prompts
- [SETUP.md](SETUP.md) — step-by-step setup for forkers
- [docs/](docs/) — deeper docs on data sources, insights, self-hosting

## Phase roadmap

1. **Phase 1 (current)** — repository skeleton, foreground service, three Android collectors (Accessibility / NotificationListener / UsageStats), local SQLite, minimal UI.
2. **Phase 2** — context intake (background, goals, values).
3. **Phase 3** — daily/weekly aggregation, baseline computation, anomaly detection vs. user's own history.
4. **Phase 4** — desktop collector, Health Connect, browser/calendar import.
5. **Phase 5** — AI coaching layer, persona system, weekly review ritual.
6. **Phase 6** — power-user tier (Shizuku, self-hosted sync).
7. **Phase 7** — public release polish.

## License

MIT. See [LICENSE](LICENSE).

## A note from the author

This started as a personal experiment in radical self-knowledge. I'm releasing it open-source not because it's polished, but because the engineering and ethical decisions are interesting and I'd rather build them in the open. If you fork it and learn something about yourself, tell me — but the code is offered without any promise that it'll do the same for you.
