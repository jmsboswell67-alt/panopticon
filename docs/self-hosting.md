# Self-Hosting Sync *(Phase 6 — optional)*

> Phase 6 deliverable. Phase 1 has no sync — everything is local-only.

If you want to keep your phone and desktop data unified — or simply have a backup target you control — you can run your own sync server. Panopticon does **not** ship with a hosted backend. There is no "Panopticon cloud."

The two supported sync targets are:

1. **A simple REST endpoint** you run yourself (recommended).
2. **Your own Firebase project** (the author has one set up under VeloVault for personal use; the code path supports it as one option among many).

---

## Why no hosted backend?

- A hosted multi-user backend changes the project's risk profile dramatically. Suddenly there's a centralized place that holds many people's behavioral data — exactly the thing this project is structured to *avoid*.
- A hosted single-user backend per fork is operationally infeasible.
- You wanted to fork an open-source project, not sign up for a service.

---

## Option 1: Self-hosted REST endpoint

To be specified when Phase 6 ships. The general shape:

- A small server (Go, Python, Node — whatever you want; the protocol is what matters) that accepts authenticated POSTs of event batches and serves authenticated GETs to pull state to other devices.
- Authentication: a long random token you generate, stored in `.env` on each client. No usernames, no accounts.
- Storage: SQLite on your server. Same schema as the local DB.
- Transport: HTTPS only. No HTTP fallback.

A reference server implementation will land in this repo under `server/` when Phase 6 ships.

---

## Option 2: Firebase

If you'd rather not run a server, you can use your own Firebase project. The code path will support:

- Authentication via Firebase Auth (your account; you're the only user).
- Storage in Firestore.
- Functions for any server-side aggregation.

You configure your project's credentials in `.env`. The repo never contains anyone's Firebase config.

---

## Constraints regardless of sync target

- All data still lives locally first. Sync is asynchronous and optional.
- You can disable sync at any time and keep using the app fully.
- Deleting on one device, by default, does not delete on others — you have to explicitly delete from each, or use the "delete everything everywhere" flow which the app warns you about.
- The sync protocol does not transmit your context document by default. You opt into syncing context separately, since context is the most sensitive part.

---

## What this looks like in Phase 1

Nothing. Phase 1 is local-only. No sync code paths exist yet. The first time sync ships, it ships as Phase 6 with this document filled in for real.
