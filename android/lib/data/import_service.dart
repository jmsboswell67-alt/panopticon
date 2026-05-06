// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import 'database.dart';
import 'event_models.dart';
import 'event_repository.dart';

/// Streams an NDJSON file produced by the desktop collector, validates each
/// line against the canonical event schema, and (on commit) persists the
/// events into the local DB.
///
/// Phase 3 keeps this dead-simple: load the file, parse, present a preview,
/// commit on user confirmation. No incremental dedup yet — the user is
/// expected to import each export once. (Re-importing an identical file
/// would currently produce duplicate events.)
class ImportService {
  ImportService(this._db, this._events);

  final PanopticonDatabase _db;
  final EventRepository _events;

  /// Parse the file and return a preview without writing anything.
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
    final counts = <String, int>{};
    for (final e in entries) {
      final key = '${e.source}.${e.eventType}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return ImportPreview(
      file: file,
      validCount: entries.length,
      issues: issues,
      eventTypeCounts: counts,
      entries: entries,
    );
  }

  /// Persist a previewed import. Wraps the writes in a transaction so a
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

    // Emit a `desktop.browser_history_imported` meta-event for audit. Per
    // the schema, this is the canonical signal that the user accepted an
    // import on this date.
    await _events.insertEvent(
      source: EventSource.desktop,
      eventType: 'browser_history_imported',
      timestampUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
      timezoneOffset: DateTime.now().timeZoneOffset.inMinutes,
      payload: {
        'event_count': entries.length,
        'source_file': preview.file.path,
        'event_type_counts': preview.eventTypeCounts,
      },
    );

    return entries.length;
  }
}

class ImportPreview {
  ImportPreview({
    required this.file,
    required this.validCount,
    required this.issues,
    required this.eventTypeCounts,
    required List<_ParsedEntry> entries,
  }) : _entries = entries;

  final File file;
  final int validCount;
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
}
