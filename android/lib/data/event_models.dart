// Plain enums and constants describing the canonical event vocabulary
// from `schema/events.schema.json`. Kept in pure Dart (no Drift imports)
// so collectors and pipelines can use these without pulling in the DB layer.

/// Top-level `source` values. Matches the enum in events.schema.json.
class EventSource {
  EventSource._();

  static const accessibility = 'accessibility';
  static const notification = 'notification';
  static const usagestats = 'usagestats';
  static const desktop = 'desktop';
  static const manual = 'manual';
  static const instrument = 'instrument';
  static const cognitiveTest = 'cognitive_test';
  static const purchase = 'purchase';
  static const browse = 'browse';
  static const health = 'health';
  static const coach = 'coach';
}

/// Accessibility event_type values.
class AccessibilityEventType {
  AccessibilityEventType._();

  static const windowStateChanged = 'window_state_changed';
  static const appFocusChanged = 'app_focus_changed';
  static const screenOn = 'screen_on';
  static const screenOff = 'screen_off';
}

/// Notification event_type values.
class NotificationEventType {
  NotificationEventType._();

  static const posted = 'notification_posted';
  static const removed = 'notification_removed';
}

/// Usagestats event_type values.
class UsageStatsEventType {
  UsageStatsEventType._();

  static const dailySummary = 'daily_summary';
}

/// Manual entry event_type values.
class ManualEventType {
  ManualEventType._();

  static const journalEntry = 'journal_entry';
  static const dailyCheckin = 'daily_checkin';
  static const observedInteraction = 'observed_interaction';
  static const notableEvent = 'notable_event';
  static const userNote = 'user_note';
  static const contextUpdate = 'context_update';
}

/// Coach event_type values.
class CoachEventType {
  CoachEventType._();

  static const briefing = 'briefing';
  static const flag = 'flag';
  static const hypothesisTest = 'hypothesis_test';
}

/// Instrument event_type values.
class InstrumentEventType {
  InstrumentEventType._();

  static const response = 'response';
}

/// Current schema version emitted by collectors.
const int kCurrentSchemaVersion = 1;
