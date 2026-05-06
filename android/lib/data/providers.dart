import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database.dart';
import 'event_repository.dart';
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

@riverpod
Stream<int> totalEventCount(Ref ref) {
  return ref.watch(eventRepositoryProvider).watchTotalEventCount();
}

@riverpod
Stream<List<Event>> recentEvents(Ref ref, {int limit = 100}) {
  return ref.watch(eventRepositoryProvider).watchRecentEvents(limit: limit);
}
