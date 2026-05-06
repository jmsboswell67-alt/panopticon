import 'package:flutter/services.dart';

/// Tiny wrapper around the native `getInstalledLaunchableApps` channel call.
/// Returns user-facing apps that have a launcher intent (so we don't list
/// system services or background-only packages in the picker).
class InstalledAppsBridge {
  InstalledAppsBridge._();

  static const _channel = MethodChannel('app.panopticon/control');

  static Future<List<InstalledApp>> list() async {
    try {
      final raw = await _channel.invokeListMethod<dynamic>('getInstalledLaunchableApps');
      if (raw == null) return const [];
      return raw
          .whereType<Map>()
          .map((m) => InstalledApp(
                packageName: m['package_name'] as String,
                displayName: (m['display_name'] as String?) ?? m['package_name'] as String,
              ))
          .toList();
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }
}

class InstalledApp {
  InstalledApp({required this.packageName, required this.displayName});
  final String packageName;
  final String displayName;
}
