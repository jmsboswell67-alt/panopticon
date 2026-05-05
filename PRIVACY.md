# Privacy

This is a privacy-first project. The whole architectural choice of "local-first, no cloud by default" exists to make privacy a property of the *design*, not a promise in a privacy policy.

This document describes exactly what is collected, where it lives, and how to delete it.

## TL;DR

- Everything is stored locally on your device.
- Nothing leaves the device unless you explicitly turn on sync or an LLM integration.
- You can export every byte to a JSON file.
- You can delete every byte with one button.
- This repository is public, but it contains **only the schema and code**. The actual collected data lives only on your device.

## What is collected (Phase 1)

When you grant the corresponding Android permission:

| Source | What's captured | What's NOT captured |
|---|---|---|
| **Accessibility** | App focus changes, foreground package name, screen on/off events | Text content of any app, your typing, what you read |
| **Notification Listener** | Package, timestamp, title, text of notifications you receive | Your replies, content of messages you send |
| **Usage Stats** | Daily rollup of foreground time per app | Per-second activity within an app |

Each Phase adds more sources. Each new source is gated behind its own permission and documented in [`docs/data-sources.md`](docs/data-sources.md).

## What is NOT collected (ever)

These are explicit non-goals enforced architecturally:

- **Content of conversations from other parties.** Messages other people send you are not captured beyond what the notification preview already shows. Replies you draft but don't send are not captured.
- **Contacts of other people.** Their names, numbers, addresses — not collected.
- **Location data of other people.** Your own location may be collected in a later phase if you opt in, but never anyone else's.
- **Anything that would constitute surveillance of non-consenting third parties.**

## Where data lives

- **Local SQLite database** on your device, in the app's private storage.
- Optionally, an **export file** you generate from the Privacy screen — this lives wherever you save it.
- Optionally, a **sync target** (a server you run yourself) if you turn that on.

The repo on GitHub does **not** contain any of your data. The repo contains:

- Code.
- The empty *schema* of what data could be collected (see [`schema/`](schema/)).
- Documentation.

It does not contain:

- Your filled-in context document.
- Your event log.
- Your insights.
- Anything from your `personal/` directory (gitignored).
- Your journal entries (gitignored except for the `journal/README.md`).

## How to delete data

### Per-event

Not yet — Phase 1 is "delete everything" only. Per-event deletion comes in Phase 3.

### Everything

Privacy screen → "Delete everything." This drops the local database. Hard delete, not soft.

If you've enabled sync, also delete data on your sync target. The app will warn you and offer to do this automatically if it has the credentials.

### The app itself

Uninstall removes the app's private storage. Anything you exported still lives where you put it.

## What about LLMs?

When the AI coaching layer ships in Phase 5, every LLM call is opt-in per provider. You choose whether to use:

- **Claude / Anthropic API** — sends your data to Anthropic's servers.
- **OpenAI API** — sends your data to OpenAI's servers.
- **Local Ollama** — stays on your machine.

The default is **none of the above**. You must enter an API key (or configure Ollama) and explicitly enable the integration before any prompt assembly happens.

Even then, the system sends a *summary* of recent behavior, not the raw event log, and it sends only the relevant fields from your context document, not the whole thing.

## What about the public repo?

If you're a forker: the `personal/` directory is gitignored. The `journal/` directory is gitignored except for its README. The `.env` file is gitignored. Schema files (the empty shapes) are committed; filled-in versions are not.

If you accidentally commit personal data, you'll need to rewrite git history. There's no shortcut. The gitignore is your first line of defense — read it.

## Auditing

You can audit what the app collects by:

1. Reading [`schema/events.schema.json`](schema/events.schema.json) for the canonical event payload shape.
2. Reading the collector source in `android/android/app/src/main/kotlin/com/velovault/panopticon/collectors/`.
3. Running the app, then exporting your data and inspecting the JSON.

If the schema, the code, and the export disagree, that's a bug. File an issue.
