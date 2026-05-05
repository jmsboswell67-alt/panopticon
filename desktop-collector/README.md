# desktop-collector/

Cross-platform Python collector for desktop. **Phase 4 deliverable — not yet present.**

## Planned scope

- Captures the same kinds of behavioral signals as the Android collectors, but for the user's computer.
- Headless. Runs as a background process or scheduled task.
- The UI is the Flutter app (also targeting desktop in Phase 4) — this collector is a data source, not a frontend.

## Planned sources

- **active_window** — foreground window title and process, sampled or event-driven depending on OS.
- **browser_history** — periodic import from Chrome/Firefox/Safari with explicit per-import consent.
- **calendar** — ICS or CalDAV import.
- **(maybe)** **keystrokes_meta** — per-minute keypress counts only, no content. Off by default.

## Planned shape

```
desktop-collector/
├── panopticon_desktop/
│   ├── __init__.py
│   ├── main.py                   # Entry point
│   ├── collectors/
│   │   ├── active_window.py
│   │   ├── browser_history.py
│   │   └── ...
│   └── sync/
│       └── ...                   # Push to mobile DB or shared local DB
├── pyproject.toml
└── README.md
```

## ActivityWatch alternative

[ActivityWatch](https://activitywatch.net/) is a mature open-source desktop tracker. Phase 4 will support importing from ActivityWatch as an alternative to running this collector — for users who already have ActivityWatch set up, this avoids running two trackers.

To be filled in when Phase 4 begins.
