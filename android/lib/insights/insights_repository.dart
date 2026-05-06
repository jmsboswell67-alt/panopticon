import 'dart:convert';

import 'package:drift/drift.dart';

import '../data/database.dart';
import '../data/event_models.dart';

/// Computes the aggregated views the Insights tab renders.
///
/// Everything here is derived from the `events` table — no separate cache
/// or aggregator service yet (that's Phase 4). For Phase 3.5 we just
/// query, decode payloads in Dart, group, and return typed results.
/// Costs scale O(N) over the relevant slice of events; fine for tens of
/// thousands of rows on phone-class hardware.
class InsightsRepository {
  InsightsRepository(this._db);

  final PanopticonDatabase _db;

  // ---- App usage --------------------------------------------------------

  /// Top apps by foreground time today, sourced from `usagestats.daily_summary`.
  Future<List<AppUsageSlice>> topAppsForDate(DateTime date) async {
    final iso = _isoDate(date);
    final rows = await (_db.select(_db.events)
          ..where((t) =>
              t.source.equals(EventSource.usagestats) &
              t.eventType.equals(UsageStatsEventType.dailySummary)))
        .get();

    final perPackage = <String, _UsageAccumulator>{};
    for (final row in rows) {
      final payload = _decode(row);
      if (payload == null) continue;
      if (payload['date'] != iso) continue;
      final pkg = (payload['package_name'] as String?) ?? row.packageName;
      if (pkg == null) continue;
      final ms = (payload['foreground_ms'] as num?)?.toInt() ?? 0;
      final launches = (payload['launch_count'] as num?)?.toInt() ?? 0;
      final acc = perPackage.putIfAbsent(pkg, _UsageAccumulator.new);
      // For a given (date, package) the rollup writes incremental updates
      // throughout the day; take the MAX rather than summing so we don't
      // double-count overlapping intervals.
      if (ms > acc.foregroundMs) acc.foregroundMs = ms;
      if (launches > acc.launchCount) acc.launchCount = launches;
    }

    final out = perPackage.entries
        .map((e) => AppUsageSlice(
              packageName: e.key,
              foregroundMs: e.value.foregroundMs,
              launchCount: e.value.launchCount,
            ))
        .toList()
      ..sort((a, b) => b.foregroundMs.compareTo(a.foregroundMs));
    return out;
  }

  /// Total foreground ms per day for the last [days] days.
  Future<List<DailyTotal>> dailyScreenTime({int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final byDate = <String, int>{};
    final rows = await (_db.select(_db.events)
          ..where((t) =>
              t.source.equals(EventSource.usagestats) &
              t.eventType.equals(UsageStatsEventType.dailySummary)))
        .get();

    // Build per-(date, package) max so we can sum across packages once.
    final perDatePackage = <String, Map<String, int>>{};
    for (final row in rows) {
      final payload = _decode(row);
      if (payload == null) continue;
      final date = payload['date'] as String?;
      if (date == null) continue;
      final pkg = (payload['package_name'] as String?) ?? row.packageName;
      if (pkg == null) continue;
      final ms = (payload['foreground_ms'] as num?)?.toInt() ?? 0;
      final pkgMap = perDatePackage.putIfAbsent(date, () => {});
      if (ms > (pkgMap[pkg] ?? 0)) pkgMap[pkg] = ms;
    }
    perDatePackage.forEach((date, pkgMs) {
      byDate[date] = pkgMs.values.fold(0, (a, b) => a + b);
    });

    final out = <DailyTotal>[];
    for (var i = 0; i < days; i++) {
      final d = DateTime(since.year, since.month, since.day + i);
      final iso = _isoDate(d);
      out.add(DailyTotal(date: d, totalMs: byDate[iso] ?? 0));
    }
    return out;
  }

  // ---- Notifications ----------------------------------------------------

  Future<List<NotificationCount>> notificationsByAppForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).toUtc().millisecondsSinceEpoch;
    final end = start + const Duration(days: 1).inMilliseconds;
    final rows = await (_db.select(_db.events)
          ..where((t) =>
              t.source.equals(EventSource.notification) &
              t.eventType.equals(NotificationEventType.posted) &
              t.timestampUtc.isBetweenValues(start, end)))
        .get();
    final counts = <String, int>{};
    for (final r in rows) {
      final pkg = r.packageName ?? 'unknown';
      counts[pkg] = (counts[pkg] ?? 0) + 1;
    }
    final out = counts.entries
        .map((e) => NotificationCount(packageName: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return out;
  }

  // ---- Media: video views (YouTube etc.) --------------------------------

  Future<List<DailyTotal>> videoViewsPerDay({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final sinceMillis = DateTime(since.year, since.month, since.day).toUtc().millisecondsSinceEpoch;
    final rows = await (_db.select(_db.events)
          ..where((t) =>
              t.source.equals('media') &
              t.eventType.equals('video_view') &
              t.timestampUtc.isBiggerOrEqualValue(sinceMillis)))
        .get();
    final byDate = <String, int>{};
    for (final r in rows) {
      final d = DateTime.fromMillisecondsSinceEpoch(r.timestampUtc);
      final iso = _isoDate(d);
      byDate[iso] = (byDate[iso] ?? 0) + 1;
    }
    final out = <DailyTotal>[];
    for (var i = 0; i < days; i++) {
      final d = DateTime(since.year, since.month, since.day + i);
      final iso = _isoDate(d);
      out.add(DailyTotal(date: d, totalMs: byDate[iso] ?? 0));
    }
    return out;
  }

  Future<List<NamedCount>> topChannels({int limit = 10}) async {
    final rows = await (_db.select(_db.events)
          ..where((t) =>
              t.source.equals('media') &
              t.eventType.equals('video_view')))
        .get();
    final counts = <String, int>{};
    for (final r in rows) {
      final p = _decode(r);
      if (p == null) continue;
      final ch = (p['channel'] as String?)?.trim();
      if (ch == null || ch.isEmpty) continue;
      counts[ch] = (counts[ch] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(limit)
        .map((e) => NamedCount(name: e.key, count: e.value))
        .toList();
  }

  // ---- Browse: searches -------------------------------------------------

  Future<List<RecentSearch>> recentSearches({int limit = 25}) async {
    final query = _db.select(_db.events)
      ..where((t) =>
          t.source.equals('browse') &
          t.eventType.equals('search_query'))
      ..orderBy([(t) => OrderingTerm.desc(t.timestampUtc)])
      ..limit(limit);
    final rows = await query.get();
    return rows
        .map((r) {
          final p = _decode(r);
          return RecentSearch(
            query: (p?['query'] as String?) ?? '(unknown)',
            engine: (p?['engine'] as String?) ?? 'unknown',
            at: DateTime.fromMillisecondsSinceEpoch(r.timestampUtc),
          );
        })
        .toList();
  }

  // ---- Audio (Spotify) --------------------------------------------------

  Future<List<NamedCount>> topArtists({int limit = 10}) async {
    final rows = await (_db.select(_db.events)
          ..where((t) =>
              t.source.equals('media') &
              t.eventType.equals('audio_play')))
        .get();
    final counts = <String, int>{};
    for (final r in rows) {
      final p = _decode(r);
      if (p == null) continue;
      final artist = (p['artist'] as String?)?.trim();
      if (artist == null || artist.isEmpty) continue;
      counts[artist] = (counts[artist] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(limit)
        .map((e) => NamedCount(name: e.key, count: e.value))
        .toList();
  }

  // ---- Helpers ----------------------------------------------------------

  Map<String, dynamic>? _decode(Event row) {
    final raw = row.payloadJson;
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _UsageAccumulator {
  int foregroundMs = 0;
  int launchCount = 0;
}

class AppUsageSlice {
  AppUsageSlice({
    required this.packageName,
    required this.foregroundMs,
    required this.launchCount,
  });
  final String packageName;
  final int foregroundMs;
  final int launchCount;
}

class DailyTotal {
  DailyTotal({required this.date, required this.totalMs});
  final DateTime date;
  final int totalMs;
}

class NotificationCount {
  NotificationCount({required this.packageName, required this.count});
  final String packageName;
  final int count;
}

class NamedCount {
  NamedCount({required this.name, required this.count});
  final String name;
  final int count;
}

class RecentSearch {
  RecentSearch({required this.query, required this.engine, required this.at});
  final String query;
  final String engine;
  final DateTime at;
}
