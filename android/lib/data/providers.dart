import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../insights/insights_repository.dart';
import '../instruments/instrument.dart';
import '../instruments/instrument_loader.dart';
import 'database.dart';
import 'event_repository.dart';
import 'import_service.dart';
import 'instrument_repository.dart';
import 'manual_repository.dart';
import 'native_bridge.dart';
import 'text_capture_repository.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
PanopticonDatabase panopticonDatabase(Ref ref) {
  final db = PanopticonDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  return EventRepository(ref.watch(panopticonDatabaseProvider));
}

@Riverpod(keepAlive: true)
NativeBridge nativeBridge(Ref ref) {
  final bridge = NativeBridge(ref.watch(eventRepositoryProvider));
  bridge.start();
  ref.onDispose(bridge.stop);
  return bridge;
}

@Riverpod(keepAlive: true)
InstrumentLoader instrumentLoader(Ref ref) => InstrumentLoader();

@Riverpod(keepAlive: true)
ManualRepository manualRepository(Ref ref) {
  return ManualRepository(
    ref.watch(panopticonDatabaseProvider),
    ref.watch(eventRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
InstrumentRepository instrumentRepository(Ref ref) {
  return InstrumentRepository(
    ref.watch(panopticonDatabaseProvider),
    ref.watch(eventRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
ImportService importService(Ref ref) {
  return ImportService(
    ref.watch(panopticonDatabaseProvider),
    ref.watch(eventRepositoryProvider),
  );
}

@Riverpod(keepAlive: true)
InsightsRepository insightsRepository(Ref ref) {
  return InsightsRepository(ref.watch(panopticonDatabaseProvider));
}

@riverpod
Future<List<AppUsageSlice>> topAppsToday(Ref ref) {
  return ref.watch(insightsRepositoryProvider).topAppsForDate(DateTime.now());
}

@riverpod
Future<List<DailyTotal>> screenTimeWeek(Ref ref) {
  return ref.watch(insightsRepositoryProvider).dailyScreenTime();
}

@riverpod
Future<List<NotificationCount>> notificationsToday(Ref ref) {
  return ref
      .watch(insightsRepositoryProvider)
      .notificationsByAppForDate(DateTime.now());
}

@riverpod
Future<List<DailyTotal>> videoViewsMonth(Ref ref) {
  return ref.watch(insightsRepositoryProvider).videoViewsPerDay();
}

@riverpod
Future<List<NamedCount>> topChannels(Ref ref) {
  return ref.watch(insightsRepositoryProvider).topChannels();
}

@riverpod
Future<List<NamedCount>> topArtists(Ref ref) {
  return ref.watch(insightsRepositoryProvider).topArtists();
}

@riverpod
Future<List<RecentSearch>> recentSearches(Ref ref) {
  return ref.watch(insightsRepositoryProvider).recentSearches();
}

@Riverpod(keepAlive: true)
TextCaptureRepository textCaptureRepository(Ref ref) {
  final repo = TextCaptureRepository(ref.watch(panopticonDatabaseProvider));
  // Push current allowlist to native on app launch so a fresh process
  // sees the persisted state without waiting for the user to edit it.
  repo.bootstrapNative();
  return repo;
}

@riverpod
Stream<List<TextCaptureAllowlistData>> textCaptureAllowlist(Ref ref) {
  return ref.watch(textCaptureRepositoryProvider).watchAllowlist();
}

@riverpod
Future<List<Instrument>> availableInstruments(Ref ref) {
  return ref.watch(instrumentLoaderProvider).loadAll();
}

@riverpod
Future<Instrument> instrumentById(Ref ref, String id) {
  return ref.watch(instrumentLoaderProvider).load(id);
}

@riverpod
Future<DateTime?> lastAdministered(Ref ref, String instrumentId) {
  return ref.watch(instrumentRepositoryProvider).lastAdministeredAt(instrumentId);
}

@riverpod
Stream<List<InstrumentAdministration>> instrumentAdministrations(
  Ref ref,
  String instrumentId,
) {
  return ref
      .watch(instrumentRepositoryProvider)
      .watchAdministrationsFor(instrumentId);
}

@riverpod
Stream<List<Event>> manualEntries(Ref ref) {
  return ref.watch(manualRepositoryProvider).watchManualEntries();
}

@riverpod
Stream<int> totalEventCount(Ref ref) {
  return ref.watch(eventRepositoryProvider).watchTotalEventCount();
}

@riverpod
Stream<List<Event>> recentEvents(Ref ref, {int limit = 100}) {
  return ref.watch(eventRepositoryProvider).watchRecentEvents(limit: limit);
}
