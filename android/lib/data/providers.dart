import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../instruments/instrument.dart';
import '../instruments/instrument_loader.dart';
import 'database.dart';
import 'event_repository.dart';
import 'instrument_repository.dart';
import 'manual_repository.dart';
import 'native_bridge.dart';

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
