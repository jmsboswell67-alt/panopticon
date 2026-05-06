import 'package:flutter/services.dart';

/// Status of a single Panopticon permission. Distinct from `permission_handler`
/// because Accessibility, NotificationListener, and Usage Access aren't covered
/// by the standard runtime-permission API — we have to ask the platform layer.
enum PanopticonPermissionStatus {
  unknown,
  granted,
  denied,
  unavailable,
}

class PanopticonPermissions {
  PanopticonPermissions._();

  static const _channel = MethodChannel('app.panopticon/control');

  static Future<PanopticonPermissionStatus> accessibilityStatus() =>
      _query('isAccessibilityEnabled');

  static Future<PanopticonPermissionStatus> notificationListenerStatus() =>
      _query('isNotificationListenerEnabled');

  static Future<PanopticonPermissionStatus> usageStatsStatus() =>
      _query('isUsageStatsEnabled');

  static Future<PanopticonPermissionStatus> postNotificationsStatus() =>
      _query('isPostNotificationsGranted');

  static Future<PanopticonPermissionStatus> batteryOptimizationStatus() =>
      _query('isBatteryOptimizationDisabled');

  static Future<void> openAccessibilitySettings() =>
      _invoke('openAccessibilitySettings');

  static Future<void> openNotificationListenerSettings() =>
      _invoke('openNotificationListenerSettings');

  static Future<void> openUsageStatsSettings() =>
      _invoke('openUsageStatsSettings');

  static Future<void> requestPostNotifications() =>
      _invoke('requestPostNotifications');

  static Future<void> openBatteryOptimizationSettings() =>
      _invoke('openBatteryOptimizationSettings');

  static Future<PanopticonPermissionStatus> _query(String method) async {
    try {
      final result = await _channel.invokeMethod<bool>(method);
      if (result == null) return PanopticonPermissionStatus.unknown;
      return result
          ? PanopticonPermissionStatus.granted
          : PanopticonPermissionStatus.denied;
    } on MissingPluginException {
      return PanopticonPermissionStatus.unavailable;
    } on PlatformException {
      return PanopticonPermissionStatus.unknown;
    }
  }

  static Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // No-op.
    } on PlatformException {
      // No-op.
    }
  }
}
