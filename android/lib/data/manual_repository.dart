import 'dart:convert';

import 'package:drift/drift.dart';

import '../journal/journal_pipeline.dart';
import '../journal/safety_regex.dart';
import 'database.dart';
import 'event_models.dart';
import 'event_repository.dart';

/// Writes manual.* events (journal entries, daily checkins, notable events,
/// observed interactions, user notes) and supports edit/delete flows for
/// the user-editable types.
class ManualRepository {
  ManualRepository(this._db, this._events, {JournalPipeline? pipeline})
      : _pipeline = pipeline ?? JournalPipeline();

  final PanopticonDatabase _db;
  final EventRepository _events;
  final JournalPipeline _pipeline;

  // ---- Journal entries ------------------------------------------------------

  /// Save a free-text journal entry. Runs the rule-based pipeline before
  /// persisting so the stored payload already carries sections, self-
  /// hypotheses and linguistic metrics.
  Future<JournalSaveResult> saveJournalEntry({
    required String text,
    int? completionSeconds,
    String inputMethod = 'typed',
    DateTime? at,
  }) async {
    final ts = at ?? DateTime.now();
    final tzOffset = ts.timeZoneOffset.inMinutes;

    final base = <String, dynamic>{
      'text': text,
      'input_method': inputMethod,
      'completion_seconds': ?completionSeconds,
    };
    final result = _pipeline.run(text);
    final payload = result.mergeIntoPayload(base);

    final eventId = await _events.insertEvent(
      source: EventSource.manual,
      eventType: ManualEventType.journalEntry,
      timestampUtc: ts.toUtc().millisecondsSinceEpoch,
      timezoneOffset: tzOffset,
      payload: payload,
    );

    if (result.safety.isNotEmpty) {
      await _emitSafetyFlags(
        sourceEventId: eventId,
        timestamp: ts,
        safety: result.safety,
        notesPrefix: 'Journal entry safety scanner',
      );
    }

    return JournalSaveResult(eventId: eventId, pipeline: result);
  }

  /// Update an existing journal entry. Re-runs the pipeline on the new prose
  /// and replaces the stored payload. Stale safety flags are NOT removed
  /// automatically; new ones are emitted if the new text triggers them.
  Future<JournalSaveResult> updateJournalEntry({
    required int eventId,
    required String text,
    int? completionSeconds,
    String inputMethod = 'typed',
    DateTime? at,
  }) async {
    final existing = await _events.findEvent(eventId);
    if (existing == null) throw StateError('Journal event $eventId not found');

    final ts = at ?? DateTime.fromMillisecondsSinceEpoch(existing.timestampUtc);
    final base = <String, dynamic>{
      'text': text,
      'input_method': inputMethod,
      'completion_seconds': ?completionSeconds,
    };
    final result = _pipeline.run(text);
    final payload = result.mergeIntoPayload(base);

    await _events.updateEventPayload(
      id: eventId,
      payload: payload,
      timestampUtc: ts.toUtc().millisecondsSinceEpoch,
      timezoneOffset: ts.timeZoneOffset.inMinutes,
    );

    if (result.safety.isNotEmpty) {
      await _emitSafetyFlags(
        sourceEventId: eventId,
        timestamp: ts,
        safety: result.safety,
        notesPrefix: 'Journal entry safety scanner (edit)',
      );
    }
    return JournalSaveResult(eventId: eventId, pipeline: result);
  }

  // ---- Daily check-ins ------------------------------------------------------

  Future<int> saveDailyCheckin({
    required List<DailyCheckinScale> scales,
    DateTime? at,
  }) async {
    final ts = at ?? DateTime.now();
    return _events.insertEvent(
      source: EventSource.manual,
      eventType: ManualEventType.dailyCheckin,
      timestampUtc: ts.toUtc().millisecondsSinceEpoch,
      timezoneOffset: ts.timeZoneOffset.inMinutes,
      payload: _checkinPayload(scales),
    );
  }

  Future<void> updateDailyCheckin({
    required int eventId,
    required List<DailyCheckinScale> scales,
    DateTime? at,
  }) async {
    final existing = await _events.findEvent(eventId);
    if (existing == null) throw StateError('Check-in event $eventId not found');
    final ts = at ?? DateTime.fromMillisecondsSinceEpoch(existing.timestampUtc);
    await _events.updateEventPayload(
      id: eventId,
      payload: _checkinPayload(scales),
      timestampUtc: ts.toUtc().millisecondsSinceEpoch,
      timezoneOffset: ts.timeZoneOffset.inMinutes,
    );
  }

  Map<String, dynamic> _checkinPayload(List<DailyCheckinScale> scales) {
    return {
      'scales': scales
          .map((s) => {
                'scale_id': s.scaleId,
                'value': s.value,
                if (s.skipped) 'skipped': true,
              })
          .toList(),
    };
  }

  // ---- Notable events -------------------------------------------------------

  Future<int> saveNotableEvent({
    required String title,
    String? description,
    String? category,
    required DateTime occurredAt,
  }) async {
    final logged = DateTime.now().toUtc().millisecondsSinceEpoch;
    return _events.insertEvent(
      source: EventSource.manual,
      eventType: ManualEventType.notableEvent,
      timestampUtc: occurredAt.toUtc().millisecondsSinceEpoch,
      timezoneOffset: occurredAt.timeZoneOffset.inMinutes,
      payload: {
        'title': title,
        'description': ?description,
        'category': ?category,
        'logged_at_utc': logged,
      },
    );
  }

  Future<void> updateNotableEvent({
    required int eventId,
    required String title,
    String? description,
    String? category,
    required DateTime occurredAt,
  }) async {
    final existing = await _events.findEvent(eventId);
    if (existing == null) throw StateError('Notable event $eventId not found');
    final originalLogged = _readLoggedAt(existing) ?? existing.timestampUtc;
    await _events.updateEventPayload(
      id: eventId,
      payload: {
        'title': title,
        'description': ?description,
        'category': ?category,
        'logged_at_utc': originalLogged,
        'edited_at_utc': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      timestampUtc: occurredAt.toUtc().millisecondsSinceEpoch,
      timezoneOffset: occurredAt.timeZoneOffset.inMinutes,
    );
  }

  int? _readLoggedAt(Event event) {
    final p = event.payloadJson;
    if (p == null) return null;
    try {
      final decoded = jsonDecode(p) as Map<String, dynamic>;
      return (decoded['logged_at_utc'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  // ---- Read helpers ---------------------------------------------------------

  Future<Event?> findEvent(int id) => _events.findEvent(id);

  Stream<List<Event>> watchManualEntries({int limit = 200}) {
    final q = _db.select(_db.events)
      ..where((t) =>
          t.source.equals(EventSource.manual) &
          t.eventType.isIn([
            ManualEventType.journalEntry,
            ManualEventType.dailyCheckin,
            ManualEventType.notableEvent,
          ]))
      ..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)])
      ..limit(limit);
    return q.watch();
  }

  Future<Event?> latestJournalEntry() => _latestOf(ManualEventType.journalEntry);
  Future<Event?> latestCheckin() => _latestOf(ManualEventType.dailyCheckin);
  Future<Event?> latestNotableEvent() => _latestOf(ManualEventType.notableEvent);

  Future<Event?> _latestOf(String eventType) async {
    final query = _db.select(_db.events)
      ..where((t) =>
          t.source.equals(EventSource.manual) &
          t.eventType.equals(eventType))
      ..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)])
      ..limit(1);
    final rows = await query.get();
    return rows.isEmpty ? null : rows.first;
  }

  // ---- Delete (cascades any coach.flag pointing at this event) -------------

  Future<int> deleteManualEvent(int id) => _events.deleteEventCascade(id);

  // ---- Safety flag emission -------------------------------------------------

  Future<void> _emitSafetyFlags({
    required int sourceEventId,
    required DateTime timestamp,
    required SafetyScanResult safety,
    required String notesPrefix,
  }) async {
    for (final category in safety.categories) {
      await _events.insertEvent(
        source: EventSource.coach,
        eventType: CoachEventType.flag,
        timestampUtc: timestamp.toUtc().millisecondsSinceEpoch,
        timezoneOffset: timestamp.timeZoneOffset.inMinutes,
        payload: {
          'category': category,
          'severity': 'concern',
          'source_event_ids': [sourceEventId],
          'notes': '$notesPrefix matched ${safety.matches.length} phrase(s).',
        },
      );
    }
  }
}

class DailyCheckinScale {
  DailyCheckinScale({required this.scaleId, required this.value, this.skipped = false});
  final String scaleId;
  final Object? value;
  final bool skipped;
}

class JournalSaveResult {
  JournalSaveResult({required this.eventId, required this.pipeline});
  final int eventId;
  final JournalPipelineResult pipeline;
}

/// Helpers for decoding the payloads of the editable manual entries — used
/// by edit screens to pre-populate fields without each one re-implementing
/// the JSON unpack.
class ManualPayloads {
  ManualPayloads._();

  static Map<String, dynamic>? decode(Event event) {
    final p = event.payloadJson;
    if (p == null) return null;
    try {
      return jsonDecode(p) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static String journalText(Event event) {
    final p = decode(event);
    return (p?['text'] as String?) ?? '';
  }

  static List<DailyCheckinScale> checkinScales(Event event) {
    final p = decode(event);
    final raw = (p?['scales'] as List?) ?? const [];
    return raw.map((r) {
      final m = (r as Map).cast<String, dynamic>();
      return DailyCheckinScale(
        scaleId: m['scale_id'] as String,
        value: m['value'],
        skipped: (m['skipped'] as bool?) ?? false,
      );
    }).toList();
  }

  static NotableEventFields notableFields(Event event) {
    final p = decode(event);
    return NotableEventFields(
      title: (p?['title'] as String?) ?? '',
      description: p?['description'] as String?,
      category: p?['category'] as String?,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(event.timestampUtc),
    );
  }
}

class NotableEventFields {
  NotableEventFields({
    required this.title,
    required this.description,
    required this.category,
    required this.occurredAt,
  });
  final String title;
  final String? description;
  final String? category;
  final DateTime occurredAt;
}
