import 'dart:convert';

import 'package:drift/drift.dart';

import '../instruments/instrument.dart';
import '../instruments/instrument_scoring.dart';
import 'database.dart';
import 'event_models.dart';
import 'event_repository.dart';

/// Writes instrument.response events and answers cadence/history queries.
class InstrumentRepository {
  InstrumentRepository(this._db, this._events);

  final PanopticonDatabase _db;
  final EventRepository _events;

  /// Persist a completed administration. Runs scoring, evaluates flag rules,
  /// and emits any coach.flag events that fired.
  Future<InstrumentSaveResult> saveAdministration({
    required Instrument instrument,
    required Map<String, Object?> responses,
    Map<String, int>? perItemRtMs,
    String trigger = 'user_initiated',
    DateTime? at,
  }) async {
    final ts = at ?? DateTime.now();
    final scorer = InstrumentScorer(instrument);
    final subscaleScores = scorer.computeSubscales(responses);
    final firedFlags = scorer.evaluateFlags(responses, subscaleScores);

    final itemResponses = responses.entries
        .where((e) => e.value != null)
        .map((e) => {
              'item_id': e.key,
              'value': e.value,
              if (perItemRtMs != null && perItemRtMs[e.key] != null)
                'rt_ms': perItemRtMs[e.key],
            })
        .toList();

    final eventId = await _events.insertEvent(
      source: EventSource.instrument,
      eventType: 'response',
      timestampUtc: ts.toUtc().millisecondsSinceEpoch,
      timezoneOffset: ts.timeZoneOffset.inMinutes,
      payload: {
        'instrument_id': instrument.id,
        'instrument_version': instrument.version,
        'item_responses': itemResponses,
        'computed_subscales': subscaleScores,
        'administration_context': {
          'trigger': trigger,
          'time_of_day_local': ts.toIso8601String(),
        },
      },
    );

    for (final f in firedFlags) {
      await _events.insertEvent(
        source: EventSource.coach,
        eventType: 'flag',
        timestampUtc: ts.toUtc().millisecondsSinceEpoch,
        timezoneOffset: ts.timeZoneOffset.inMinutes,
        payload: {
          'category': f.rule.flagCategory,
          'severity': f.severity,
          'source_event_ids': [eventId],
          'notes': f.rule.description ?? f.rule.id,
        },
      );
    }

    return InstrumentSaveResult(
      eventId: eventId,
      subscaleScores: subscaleScores,
      firedFlags: firedFlags,
    );
  }

  Future<DateTime?> lastAdministeredAt(String instrumentId) async {
    final query = _db.select(_db.events)
      ..where((t) =>
          t.source.equals(EventSource.instrument) &
          t.eventType.equals('response'))
      ..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)])
      ..limit(50);
    final rows = await query.get();
    for (final r in rows) {
      final p = r.payloadJson;
      if (p == null) continue;
      try {
        final decoded = jsonDecode(p) as Map<String, dynamic>;
        if (decoded['instrument_id'] == instrumentId) {
          return DateTime.fromMillisecondsSinceEpoch(r.timestampUtc);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<List<InstrumentAdministration>> administrationsFor(String instrumentId) async {
    final rows = await _allInstrumentResponseRows();
    return _filterAdministrations(rows, instrumentId);
  }

  /// Live-updating administrations for an instrument. Useful for the
  /// instrument detail screen to refresh after delete/save without
  /// invalidating providers manually.
  Stream<List<InstrumentAdministration>> watchAdministrationsFor(String instrumentId) {
    final query = _db.select(_db.events)
      ..where((t) =>
          t.source.equals(EventSource.instrument) &
          t.eventType.equals(InstrumentEventType.response))
      ..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)]);
    return query.watch().map((rows) => _filterAdministrations(rows, instrumentId));
  }

  Future<List<Event>> _allInstrumentResponseRows() {
    final q = _db.select(_db.events)
      ..where((t) =>
          t.source.equals(EventSource.instrument) &
          t.eventType.equals(InstrumentEventType.response))
      ..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)]);
    return q.get();
  }

  List<InstrumentAdministration> _filterAdministrations(
    List<Event> rows,
    String instrumentId,
  ) {
    final out = <InstrumentAdministration>[];
    for (final r in rows) {
      final p = r.payloadJson;
      if (p == null) continue;
      try {
        final decoded = jsonDecode(p) as Map<String, dynamic>;
        if (decoded['instrument_id'] != instrumentId) continue;
        final subs = (decoded['computed_subscales'] as Map?)?.cast<String, num>() ?? const {};
        final items = (decoded['item_responses'] as List?) ?? const [];
        out.add(InstrumentAdministration(
          eventId: r.id,
          at: DateTime.fromMillisecondsSinceEpoch(r.timestampUtc),
          subscaleScores: {for (final e in subs.entries) e.key: e.value.toDouble()},
          itemResponses: items.map((e) {
            final m = (e as Map).cast<String, dynamic>();
            return ItemResponseRecord(
              itemId: m['item_id'] as String,
              value: m['value'],
            );
          }).toList(),
        ));
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  /// Delete a single administration and any coach.flag events that
  /// referenced it.
  Future<int> deleteAdministration(int eventId) =>
      _events.deleteEventCascade(eventId);
}

class InstrumentSaveResult {
  InstrumentSaveResult({
    required this.eventId,
    required this.subscaleScores,
    required this.firedFlags,
  });
  final int eventId;
  final Map<String, double> subscaleScores;
  final List<FiredFlag> firedFlags;
}

class InstrumentAdministration {
  InstrumentAdministration({
    required this.eventId,
    required this.at,
    required this.subscaleScores,
    this.itemResponses = const [],
  });
  final int eventId;
  final DateTime at;
  final Map<String, double> subscaleScores;
  final List<ItemResponseRecord> itemResponses;
}

class ItemResponseRecord {
  ItemResponseRecord({required this.itemId, required this.value});
  final String itemId;
  final Object? value;
}
