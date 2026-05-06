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

/// Current schema version emitted by collectors.
const int kCurrentSchemaVersion = 1;
