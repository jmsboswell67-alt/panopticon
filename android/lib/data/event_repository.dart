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

  Future<Event?> findEvent(int id) async {
    final q = _db.select(_db.events)..where((t) => t.id.equals(id))..limit(1);
    final rows = await q.get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Update only the payload + timestamp on an existing event row. Used by
  /// edit flows for manual.* entries; preserves source/event_type/id.
  Future<void> updateEventPayload({
    required int id,
    Map<String, dynamic>? payload,
    int? timestampUtc,
    int? timezoneOffset,
  }) async {
    final encoded = payload == null ? null : jsonEncode(payload);
    await (_db.update(_db.events)..where((t) => t.id.equals(id))).write(
      EventsCompanion(
        payloadJson: Value(encoded),
        timestampUtc:
            timestampUtc == null ? const Value.absent() : Value(timestampUtc),
        timezoneOffset:
            timezoneOffset == null ? const Value.absent() : Value(timezoneOffset),
      ),
    );
  }

  /// Delete a single event and any coach.flag events that reference it via
  /// payload.source_event_ids. Returns the total rows deleted.
  Future<int> deleteEventCascade(int id) async {
    final flags = await (_db.select(_db.events)
          ..where((t) =>
              t.source.equals(EventSource.coach) &
              t.eventType.equals(CoachEventType.flag)))
        .get();
    var removed = 0;
    for (final f in flags) {
      final p = f.payloadJson;
      if (p == null) continue;
      try {
        final decoded = jsonDecode(p) as Map<String, dynamic>;
        final ids = decoded['source_event_ids'];
        if (ids is List && ids.contains(id)) {
          removed += await (_db.delete(_db.events)..where((t) => t.id.equals(f.id))).go();
        }
      } catch (_) {
        continue;
      }
    }
    removed += await (_db.delete(_db.events)..where((t) => t.id.equals(id))).go();
    return removed;
  }
}
