import 'dart:async';

import 'package:flutter/services.dart';

import 'event_repository.dart';

/// Dart side of the Kotlin → Dart event flush channel.
///
/// The native foreground service buffers events in memory and periodically
/// flushes them to Dart in batches. We persist each batch atomically.
class NativeBridge {
  NativeBridge(this._repository);

  static const _methodChannel = MethodChannel('app.panopticon/control');
  static const _eventChannel = EventChannel('app.panopticon/events');

  final EventRepository _repository;
  StreamSubscription<dynamic>? _subscription;

  void start() {
    _subscription ??= _eventChannel.receiveBroadcastStream().listen(
      (dynamic batch) async {
        if (batch is! List) return;
        final typed = batch
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
        await _repository.insertManyFromNative(typed);
      },
      onError: (Object e, StackTrace st) {
        // Errors here are non-fatal — the native side will retry on the next flush.
      },
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Ask the native foreground service to start (idempotent).
  Future<void> startForegroundService() async {
    try {
      await _methodChannel.invokeMethod<void>('startForegroundService');
    } on MissingPluginException {
      // Running on a platform without the native side (iOS, desktop tests).
    } on PlatformException {
      // Service may already be running, or the OS denied us. Surfaced via permission UI.
    }
  }

  /// Ask the native foreground service to stop. Used when the user disables
  /// passive collection from the Privacy screen.
  Future<void> stopForegroundService() async {
    try {
      await _methodChannel.invokeMethod<void>('stopForegroundService');
    } on MissingPluginException {
      // No-op on platforms without the native side.
    } on PlatformException {
      // No-op.
    }
  }

  /// Trigger an immediate UsageStats rollup write. Used after granting Usage
  /// Access so the user sees data right away rather than waiting for the
  /// daily timer.
  Future<void> requestUsageStatsRollup() async {
    try {
      await _methodChannel.invokeMethod<void>('requestUsageStatsRollup');
    } on MissingPluginException {
      // No-op.
    } on PlatformException {
      // No-op.
    }
  }
}
