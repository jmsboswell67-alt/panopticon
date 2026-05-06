import 'package:drift/drift.dart';

import '../journal/journal_pipeline.dart';
import '../journal/safety_regex.dart';
import 'database.dart';
import 'event_models.dart';
import 'event_repository.dart';

/// Writes manual.* events (journal entries, daily checkins, observed
/// interactions, user notes) and surfaces journal-pipeline outputs.
class ManualRepository {
  ManualRepository(this._db, this._events, {JournalPipeline? pipeline})
      : _pipeline = pipeline ?? JournalPipeline();

  final PanopticonDatabase _db;
  final EventRepository _events;
  final JournalPipeline _pipeline;

  /// Save a free-text journal entry. Runs the rule-based pipeline before
  /// persisting so the stored payload already carries sections, self-
  /// hypotheses and linguistic metrics. Returns the inserted event id and
  /// any safety hits that fired.
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
      eventType: 'journal_entry',
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

    return JournalSaveResult(
      eventId: eventId,
      pipeline: result,
    );
  }

  Future<int> saveDailyCheckin({
    required List<DailyCheckinScale> scales,
    DateTime? at,
  }) async {
    final ts = at ?? DateTime.now();
    return _events.insertEvent(
      source: EventSource.manual,
      eventType: 'daily_checkin',
      timestampUtc: ts.toUtc().millisecondsSinceEpoch,
      timezoneOffset: ts.timeZoneOffset.inMinutes,
      payload: {
        'scales': scales
            .map((s) => {
                  'scale_id': s.scaleId,
                  'value': s.value,
                  if (s.skipped) 'skipped': true,
                })
            .toList(),
      },
    );
  }

  Future<int> saveObservedInteraction({
    required String category,
    required String valence,
    int? intensity,
    List<String> parties = const [],
    String? notes,
    DateTime? at,
  }) async {
    final ts = at ?? DateTime.now();
    final eventId = await _events.insertEvent(
      source: EventSource.manual,
      eventType: 'observed_interaction',
      timestampUtc: ts.toUtc().millisecondsSinceEpoch,
      timezoneOffset: ts.timeZoneOffset.inMinutes,
      payload: {
        'category': category,
        'valence': valence,
        'intensity': ?intensity,
        if (parties.isNotEmpty) 'parties': parties,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    if (notes != null && notes.isNotEmpty) {
      final scan = SafetyScanner().scan(notes);
      if (scan.isNotEmpty) {
        await _emitSafetyFlags(
          sourceEventId: eventId,
          timestamp: ts,
          safety: scan,
          notesPrefix: 'Observed interaction notes safety scanner',
        );
      }
    }
    return eventId;
  }

  Future<void> _emitSafetyFlags({
    required int sourceEventId,
    required DateTime timestamp,
    required SafetyScanResult safety,
    required String notesPrefix,
  }) async {
    for (final category in safety.categories) {
      await _events.insertEvent(
        source: EventSource.coach,
        eventType: 'flag',
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

  /// Most recent journal entry, or null. Used by the Log screen to show
  /// a "last entry" hint.
  Future<Event?> latestJournalEntry() async {
    final query = _db.select(_db.events)
      ..where((t) =>
          t.source.equals(EventSource.manual) &
          t.eventType.equals('journal_entry'))
      ..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)])
      ..limit(1);
    final rows = await query.get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<Event?> latestCheckin() async {
    final query = _db.select(_db.events)
      ..where((t) =>
          t.source.equals(EventSource.manual) &
          t.eventType.equals('daily_checkin'))
      ..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)])
      ..limit(1);
    final rows = await query.get();
    return rows.isEmpty ? null : rows.first;
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
