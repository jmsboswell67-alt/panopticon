// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import 'database.dart';
import 'event_models.dart';
import 'event_repository.dart';

/// Streams an NDJSON file (produced by either the desktop collector or the
/// phone's "Export everything" share), validates each line against the
/// canonical event schema, dedupes against what's already in the local
/// database, and persists what's new on commit.
///
/// Dedup key: SHA-256 of `<source>|<event_type>|<timestamp_utc>|<canonical_payload>`.
/// Same event imported twice (e.g. phone export → desktop import → phone
/// re-import next week) produces no duplicates.
class ImportService {
  ImportService(this._db, this._events);

  final PanopticonDatabase _db;
  final EventRepository _events;

  /// Parse the file + dedup against existing rows; return a preview without
  /// writing anything.
  Future<ImportPreview> preview(File file) async {
    final lines = await file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();
    final entries = <_ParsedEntry>[];
    final issues = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        entries.add(_ParsedEntry.fromJson(decoded));
      } catch (e) {
        issues.add('Line ${i + 1}: $e');
      }
    }

    final existingKeys = await _existingDedupKeys();
    final novelEntries = <_ParsedEntry>[];
    var duplicateCount = 0;
    for (final e in entries) {
      if (existingKeys.contains(e.dedupKey)) {
        duplicateCount++;
        continue;
      }
      novelEntries.add(e);
    }

    final counts = <String, int>{};
    for (final e in novelEntries) {
      final key = '${e.source}.${e.eventType}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return ImportPreview(
      file: file,
      totalLines: entries.length,
      validCount: novelEntries.length,
      duplicateCount: duplicateCount,
      issues: issues,
      eventTypeCounts: counts,
      entries: novelEntries,
    );
  }

  /// Persist a previewed import. Wraps the writes in a Drift batch so a
  /// failure halfway through doesn't leave a partial import.
  Future<int> commit(ImportPreview preview) async {
    final entries = preview._entries;
    if (entries.isEmpty) return 0;

    await _db.batch((batch) {
      for (final e in entries) {
        batch.insert(
          _db.events,
          EventsCompanion.insert(
            timestampUtc: e.timestampUtc,
            timezoneOffset: e.timezoneOffset,
            source: e.source,
            eventType: e.eventType,
            packageName: Value(e.packageName),
            payloadJson: Value(e.payloadJson),
            schemaVersion: Value(e.schemaVersion),
          ),
        );
      }
    });

    // Audit: emit a desktop.browser_history_imported meta-event so future
    // queries can see "the user accepted import X on date Y."
    await _events.insertEvent(
      source: EventSource.desktop,
      eventType: 'browser_history_imported',
      timestampUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
      timezoneOffset: DateTime.now().timeZoneOffset.inMinutes,
      payload: {
        'event_count': entries.length,
        'duplicate_count': preview.duplicateCount,
        'source_file': preview.file.path,
        'event_type_counts': preview.eventTypeCounts,
      },
    );

    return entries.length;
  }

  Future<Set<String>> _existingDedupKeys() async {
    final rows = await _db.select(_db.events).get();
    return rows.map(_dedupKeyForRow).toSet();
  }

  String _dedupKeyForRow(Event e) {
    return _computeDedupKey(
      source: e.source,
      eventType: e.eventType,
      timestampUtc: e.timestampUtc,
      payloadJson: e.payloadJson,
    );
  }
}

/// Public so tests can verify dedup-key stability without going through
/// the full ImportService.
String computeDedupKey({
  required String source,
  required String eventType,
  required int timestampUtc,
  String? payloadJson,
}) =>
    _computeDedupKey(
      source: source,
      eventType: eventType,
      timestampUtc: timestampUtc,
      payloadJson: payloadJson,
    );

String _computeDedupKey({
  required String source,
  required String eventType,
  required int timestampUtc,
  String? payloadJson,
}) {
  // Canonicalise the payload so two semantically-identical payloads with
  // different key ordering hash the same.
  final canonical = payloadJson == null ? '' : _canonicalJson(payloadJson);
  final input = '$source|$eventType|$timestampUtc|$canonical';
  return sha256.convert(utf8.encode(input)).toString();
}

String _canonicalJson(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return jsonEncode(_sortKeys(decoded));
  } catch (_) {
    return raw;
  }
}

Object? _sortKeys(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final k in keys) k: _sortKeys(value[k])};
  }
  if (value is List) {
    return value.map(_sortKeys).toList();
  }
  return value;
}

class ImportPreview {
  ImportPreview({
    required this.file,
    required this.totalLines,
    required this.validCount,
    required this.duplicateCount,
    required this.issues,
    required this.eventTypeCounts,
    required List<_ParsedEntry> entries,
  }) : _entries = entries;

  final File file;
  final int totalLines;
  final int validCount;
  final int duplicateCount;
  final List<String> issues;
  final Map<String, int> eventTypeCounts;
  final List<_ParsedEntry> _entries;

  bool get hasIssues => issues.isNotEmpty;
  bool get isImportable => validCount > 0;
}

class _ParsedEntry {
  _ParsedEntry({
    required this.timestampUtc,
    required this.timezoneOffset,
    required this.source,
    required this.eventType,
    required this.payloadJson,
    required this.packageName,
    required this.schemaVersion,
  });

  factory _ParsedEntry.fromJson(Map<String, dynamic> j) {
    final ts = j['timestamp_utc'];
    if (ts is! num) throw FormatException('missing timestamp_utc');
    final tz = j['timezone_offset'];
    if (tz is! num) throw FormatException('missing timezone_offset');
    final source = j['source'];
    if (source is! String) throw FormatException('missing source');
    final eventType = j['event_type'];
    if (eventType is! String) throw FormatException('missing event_type');

    final payload = j['payload_json'];
    String? encoded;
    if (payload != null) {
      encoded = payload is String ? payload : jsonEncode(payload);
    }

    return _ParsedEntry(
      timestampUtc: ts.toInt(),
      timezoneOffset: tz.toInt(),
      source: source,
      eventType: eventType,
      payloadJson: encoded,
      packageName: j['package_name'] as String?,
      schemaVersion: (j['schema_version'] as num?)?.toInt() ?? kCurrentSchemaVersion,
    );
  }

  final int timestampUtc;
  final int timezoneOffset;
  final String source;
  final String eventType;
  final String? payloadJson;
  final String? packageName;
  final int schemaVersion;

  String get dedupKey => _computeDedupKey(
        source: source,
        eventType: eventType,
        timestampUtc: timestampUtc,
        payloadJson: payloadJson,
      );
}
