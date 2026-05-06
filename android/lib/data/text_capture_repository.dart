import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import 'database.dart';

/// Source of truth for the per-app text-capture allowlist.
///
/// The Drift table is the canonical store; on every change we mirror the
/// current package list into Android SharedPreferences via the native
/// bridge so [PanopticonAccessibilityService] can read the allowlist
/// without crossing the platform channel on every accessibility event.
class TextCaptureRepository {
  TextCaptureRepository(this._db);

  static const _channel = MethodChannel('app.panopticon/control');

  final PanopticonDatabase _db;

  Stream<List<TextCaptureAllowlistData>> watchAllowlist() {
    final q = _db.select(_db.textCaptureAllowlist)
      ..orderBy([(t) => OrderingTerm.asc(t.packageName)]);
    return q.watch();
  }

  Future<List<TextCaptureAllowlistData>> currentAllowlist() {
    final q = _db.select(_db.textCaptureAllowlist)
      ..orderBy([(t) => OrderingTerm.asc(t.packageName)]);
    return q.get();
  }

  Future<void> add(String packageName, {String? displayName}) async {
    await _db.into(_db.textCaptureAllowlist).insertOnConflictUpdate(
          TextCaptureAllowlistCompanion.insert(
            packageName: packageName,
            displayName: Value(displayName),
            addedAtUtc: DateTime.now().toUtc().millisecondsSinceEpoch,
          ),
        );
    await _syncToNative();
  }

  Future<void> remove(String packageName) async {
    await (_db.delete(_db.textCaptureAllowlist)
          ..where((t) => t.packageName.equals(packageName)))
        .go();
    await _syncToNative();
  }

  Future<void> clear() async {
    await _db.delete(_db.textCaptureAllowlist).go();
    await _syncToNative();
  }

  /// Push the full allowlist to Android side. Called automatically after
  /// add/remove/clear; also called on app startup so a fresh process
  /// picks up the persisted state.
  Future<void> _syncToNative() async {
    final rows = await currentAllowlist();
    final packages = rows.map((r) => r.packageName).toList();
    try {
      await _channel.invokeMethod<void>(
        'updateTextCaptureAllowlist',
        {'packages': packages},
      );
    } on MissingPluginException {
      // No-op on platforms without the native side (iOS, desktop tests).
    } on PlatformException {
      // Native side will retry on its next allowlist read.
    }
  }

  /// Public entrypoint for app-init code paths to push the persisted
  /// allowlist to native after a fresh app launch.
  Future<void> bootstrapNative() => _syncToNative();
}
