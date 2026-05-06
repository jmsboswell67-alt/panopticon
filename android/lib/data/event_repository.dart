import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';
import 'event_models.dart';

/// Single writer for raw events plus the denormalised side-tables.
/// Collectors hand events here; the repository decides what to fan out.
class EventRepository {
  EventRepository(this._db);

  final PanopticonDatabase _db;

  Future<int> insertEvent({
    required String source,
    required String eventType,
    required int timestampUtc,
    required int timezoneOffset,
    String? packageName,
    Map<String, dynamic>? payload,
    int schemaVersion = kCurrentSchemaVersion,
  }) async {
    final encoded = payload == null ? null : jsonEncode(payload);
    final id = await _db.into(_db.events).insert(
          EventsCompanion.insert(
            timestampUtc: timestampUtc,
            timezoneOffset: timezoneOffset,
            source: source,
            eventType: eventType,
            packageName: Value(packageName),
            payloadJson: Value(encoded),
            schemaVersion: Value(schemaVersion),
          ),
        );

    if (source == EventSource.notification && payload != null) {
      await _mirrorNotification(timestampUtc, packageName, eventType, payload);
    }

    return id;
  }

  Future<void> insertManyFromNative(List<Map<String, dynamic>> rawEvents) async {
    if (rawEvents.isEmpty) return;
    await _db.batch((batch) {
      for (final raw in rawEvents) {
        final timestampUtc = (raw['timestamp_utc'] as num).toInt();
        final timezoneOffset = (raw['timezone_offset'] as num).toInt();
        final source = raw['source'] as String;
        final eventType = raw['event_type'] as String;
        final packageName = raw['package_name'] as String?;
        final schemaVersion = (raw['schema_version'] as num?)?.toInt() ?? kCurrentSchemaVersion;
        final payload = raw['payload'] as Map?;
        final encoded = payload == null ? null : jsonEncode(payload);

        batch.insert(
          _db.events,
          EventsCompanion.insert(
            timestampUtc: timestampUtc,
            timezoneOffset: timezoneOffset,
            source: source,
            eventType: eventType,
            packageName: Value(packageName),
            payloadJson: Value(encoded),
            schemaVersion: Value(schemaVersion),
          ),
        );

        if (source == EventSource.notification && payload != null) {
          batch.insert(
            _db.notifications,
            NotificationsCompanion.insert(
              timestampUtc: timestampUtc,
              packageName: packageName ?? '',
              eventType: eventType,
              title: Value(payload['title'] as String?),
              body: Value(payload['text'] as String?),
              category: Value(payload['category'] as String?),
              priority: Value((payload['priority'] as num?)?.toInt()),
              removedReason: Value(payload['removed_reason'] as String?),
            ),
          );
        }
      }
    });
  }

  Future<void> _mirrorNotification(
    int timestampUtc,
    String? packageName,
    String eventType,
    Map<String, dynamic> payload,
  ) async {
    await _db.into(_db.notifications).insert(
          NotificationsCompanion.insert(
            timestampUtc: timestampUtc,
            packageName: packageName ?? '',
            eventType: eventType,
            title: Value(payload['title'] as String?),
            body: Value(payload['text'] as String?),
            category: Value(payload['category'] as String?),
            priority: Value((payload['priority'] as num?)?.toInt()),
            removedReason: Value(payload['removed_reason'] as String?),
          ),
        );
  }

  Stream<int> watchEventCountSince(int sinceUtcMillis) {
    final query = _db.selectOnly(_db.events)
      ..addColumns([_db.events.id.count()])
      ..where(_db.events.timestampUtc.isBiggerOrEqualValue(sinceUtcMillis));
    return query.map((row) => row.read(_db.events.id.count()) ?? 0).watchSingle();
  }

  Stream<List<Event>> watchRecentEvents({int limit = 100}) {
    final query = _db.select(_db.events)
      ..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)])
      ..limit(limit);
    return query.watch();
  }

  Stream<int> watchTotalEventCount() {
    final query = _db.selectOnly(_db.events)..addColumns([_db.events.id.count()]);
    return query.map((row) => row.read(_db.events.id.count()) ?? 0).watchSingle();
  }

  Future<int> totalEventCount() async {
    final query = _db.selectOnly(_db.events)..addColumns([_db.events.id.count()]);
    final row = await query.getSingle();
    return row.read(_db.events.id.count()) ?? 0;
  }

  Future<List<Event>> allEvents({int? limit}) {
    final query = _db.select(_db.events)
      ..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  Future<int> deleteAllEvents() async {
    await _db.delete(_db.notifications).go();
    await _db.delete(_db.appSessions).go();
    await _db.delete(_db.dailyRollups).go();
    return _db.delete(_db.events).go();
  }
}
