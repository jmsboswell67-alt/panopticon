# Data Sources

Every collector that feeds the event log, what it captures, and what it explicitly does not.

This document is updated as new collectors land. Phase 1 ships three Android collectors; later phases add desktop, health, browser, and calendar.

---

## Phase 1 — Android collectors

### Accessibility Service

**Source key:** `accessibility`
**Permission:** Accessibility Service (granted via Settings → Accessibility → Panopticon)
**Why required:** Without this, the system cannot tell when you switch apps or what's currently in the foreground.

**Captures:**

| Event type | Payload fields |
|---|---|
| `window_state_changed` | `package_name`, `class_name` |
| `app_focus_changed` | `previous_package`, `current_package`, `dwell_ms_in_previous` |
| `screen_on` | (none) |
| `screen_off` | (none) |

**Does NOT capture in Phase 1:**

- Text content of any app.
- What you're typing.
- What's on screen visually.
- Anything about the *content* of what you're doing — only that you switched, when, and to which app.

A future toggle (separate from this collector's permission) may enable text content capture for specific user-selected apps. This is a Phase 6+ decision and is gated behind its own explicit consent flow.

### Notification Listener

**Source key:** `notification`
**Permission:** Notification Listener (granted via Settings → Notifications → Special access)
**Why required:** Notification volume and timing is a strong behavioral signal — work hours, sleep disruption, app stickiness, social load.

**Captures:**

| Event type | Payload fields |
|---|---|
| `notification_posted` | `package_name`, `title`, `text`, `category`, `priority` |
| `notification_removed` | `package_name`, `removed_reason` |

**Does NOT capture:**

- Replies you draft but don't send.
- Content of messages YOU send (that's not a notification you receive).
- Anything from other people that they didn't surface to your notification tray.

**Note on third-party content:** notification text from messaging apps is captured. This is the user's own data (your notifications, on your device, for your behavioral analysis). It is never transmitted off-device by Phase 1 code paths. See [`PRIVACY.md`](../PRIVACY.md) hard rail "no surveillance of other people."

### Usage Stats

**Source key:** `usagestats`
**Permission:** Usage Access (granted via Settings → Apps → Special access → Usage access)
**Why required:** The OS already tracks daily foreground time per app — using this is more accurate and battery-cheaper than rolling our own from accessibility events.

**Captures:**

| Event type | Payload fields |
|---|---|
| `daily_summary` | `date`, `package_name`, `foreground_ms`, `launch_count` |

One event per app per day. Computed once daily.

---

## Phase 4 — Desktop collector *(planned, not yet present)*

Will live under `desktop-collector/`. Cross-platform Python.

**Planned sources:**

- `desktop` / `active_window_changed` — the foreground window on your computer (analogous to `app_focus_changed` on Android).
- `desktop` / `browser_history_imported` — a manual or scheduled import of your browser history with the user's explicit per-import consent.

**Does NOT capture (planned):**

- Keystrokes or text content (a metadata-only "keystrokes per minute" rollup is being considered as a separate, opt-in, off-by-default collector).
- Clipboard content.
- Microphone, camera, or screen capture of any kind.

---

## Phase 4 — Health Connect *(planned)*

Will pull from Android Health Connect: heart rate samples, sleep sessions, step counts. User selects which sources to pull from.

---

## Adding your own collector

If you fork this and add a new source:

1. Pick a `source` key (lowercase, snake_case). Add it to the enum in [`schema/events.schema.json`](../schema/events.schema.json).
2. Define your event types and payload shapes. Add them to the schema under `_event_type_enums`.
3. Implement the collector — Kotlin if it's an Android OS hook, Python if it's desktop-side.
4. Add an entry here describing what's captured and what isn't.
5. Add a permission step to the setup wizard if a new permission is required.
6. If the source touches third-party data, run it past the [`ETHICS.md`](../ETHICS.md) hard rails first.
