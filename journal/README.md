# journal/

The author's personal case study, kept here so that it can eventually become public.

**For the moment, every file in this directory other than this `README.md` is gitignored.** See [`.gitignore`](../.gitignore):

```
journal/*
!journal/README.md
```

## Why this directory exists

Panopticon is, partly, an experiment on its author. As entries accumulate over many months, they may eventually be published as a long-form case study — the kind of "I instrumented myself for a year and here's what I found" piece that makes the abstract concrete.

That hasn't happened yet, and it doesn't have to happen. If publication never feels right, the entries stay private forever. The structure is set up so it's *possible* to publish later, not that publication is the goal.

## Forkers

If you fork this project and don't want a journal, you can ignore this directory. The journal is not part of the runtime — nothing in the app reads from `journal/`.

If you fork and want your own journal, the same gitignore rule keeps your entries out of your fork's public repo until you decide otherwise.

## Format *(forward-looking)*

Journal entries will likely live as dated markdown files (e.g. `2026-05-01.md`). No format is enforced yet. Entries may include:

- Reflections on patterns the system surfaced.
- Decisions made in response to insights.
- Disagreements with the system's interpretations.
- Notes on which personas worked when.

## What this directory is NOT

- Not a substitute for therapy.
- Not a public-facing diary right now. Treat anything you write here as private until you explicitly choose to publish.
- Not synced. Local-only. If you want a backup, manage that separately.
