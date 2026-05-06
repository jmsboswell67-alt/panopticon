import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Universal event log. Every collector writes here.
///
/// `payload_json` is a JSON string whose shape depends on (source, event_type).
/// Canonical shapes are documented in `schema/events.schema.json`.
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timestampUtc => integer().named('timestamp_utc')();
  IntColumn get timezoneOffset => integer().named('timezone_offset')();
  TextColumn get source => text()();
  TextColumn get eventType => text().named('event_type')();
  TextColumn get packageName => text().named('package_name').nullable()();
  TextColumn get payloadJson => text().named('payload_json').nullable()();
  IntColumn get schemaVersion => integer().named('schema_version').withDefault(const Constant(1))();
}

/// Derived foreground app sessions. Computed from accessibility events.
class AppSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text().named('package_name')();
  IntColumn get startUtc => integer().named('start_utc')();
  IntColumn get endUtc => integer().named('end_utc').nullable()();
  IntColumn get durationMs => integer().named('duration_ms').nullable()();
}

/// Notification events, denormalised for fast querying.
/// Mirrors a subset of `events` rows where source='notification'.
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timestampUtc => integer().named('timestamp_utc')();
  TextColumn get packageName => text().named('package_name')();
  TextColumn get eventType => text().named('event_type')();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().named('text').nullable()();
  TextColumn get category => text().nullable()();
  IntColumn get priority => integer().nullable()();
  TextColumn get removedReason => text().named('removed_reason').nullable()();
}

/// Pre-computed daily aggregates per app, from UsageStatsManager.
class DailyRollups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get packageName => text().named('package_name')();
  IntColumn get foregroundMs => integer().named('foreground_ms').withDefault(const Constant(0))();
  IntColumn get launchCount => integer().named('launch_count').withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date, packageName},
      ];
}

/// Per-app allowlist for in-app text capture by the accessibility service.
/// Empty by default — nothing captured until the user explicitly opts an
/// app in. Mirrored to Android SharedPreferences via the native bridge so
/// the foreground accessibility service can read it without round-tripping
/// to Dart on every event.
class TextCaptureAllowlist extends Table {
  TextColumn get packageName => text().named('package_name')();
  TextColumn get displayName => text().named('display_name').nullable()();
  IntColumn get addedAtUtc => integer().named('added_at_utc')();

  @override
  Set<Column> get primaryKey => {packageName};
}

@DriftDatabase(tables: [Events, AppSessions, Notifications, DailyRollups, TextCaptureAllowlist])
class PanopticonDatabase extends _$PanopticonDatabase {
  PanopticonDatabase() : super(_open());

  PanopticonDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(textCaptureAllowlist);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _open() {
    return driftDatabase(name: 'panopticon');
  }
}
