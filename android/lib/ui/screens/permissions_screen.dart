import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../permissions/permission_status.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with WidgetsBindingObserver {
  PanopticonPermissionStatus _accessibility = PanopticonPermissionStatus.unknown;
  PanopticonPermissionStatus _notifListener = PanopticonPermissionStatus.unknown;
  PanopticonPermissionStatus _usageStats = PanopticonPermissionStatus.unknown;
  PanopticonPermissionStatus _postNotifications = PanopticonPermissionStatus.unknown;
  PanopticonPermissionStatus _batteryOpt = PanopticonPermissionStatus.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final results = await Future.wait([
      PanopticonPermissions.accessibilityStatus(),
      PanopticonPermissions.notificationListenerStatus(),
      PanopticonPermissions.usageStatsStatus(),
      PanopticonPermissions.postNotificationsStatus(),
      PanopticonPermissions.batteryOptimizationStatus(),
    ]);
    if (!mounted) return;
    setState(() {
      _accessibility = results[0];
      _notifListener = results[1];
      _usageStats = results[2];
      _postNotifications = results[3];
      _batteryOpt = results[4];
    });

    if (_anyCollectorGranted) {
      await ref.read(nativeBridgeProvider).startForegroundService();
    }
  }

  bool get _anyCollectorGranted {
    bool granted(PanopticonPermissionStatus s) =>
        s == PanopticonPermissionStatus.granted;
    return granted(_accessibility) || granted(_notifListener) || granted(_usageStats);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Permissions'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Panopticon needs the following Android permissions to observe '
              'your behavior. Each opens its own system settings page; you '
              'must grant them manually.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        SliverList.list(
          children: [
            _PermissionTile(
              title: 'Accessibility Service',
              subtitle: 'Observes which app is in the foreground and screen on/off events.',
              status: _accessibility,
              onOpen: () async {
                await PanopticonPermissions.openAccessibilitySettings();
              },
            ),
            _PermissionTile(
              title: 'Notification Listener',
              subtitle: 'Captures notification volume and timing as a behavioral signal.',
              status: _notifListener,
              onOpen: () async {
                await PanopticonPermissions.openNotificationListenerSettings();
              },
            ),
            _PermissionTile(
              title: 'Usage Access',
              subtitle: 'Reads daily per-app foreground time. More accurate than computing it from accessibility events.',
              status: _usageStats,
              onOpen: () async {
                await PanopticonPermissions.openUsageStatsSettings();
              },
            ),
            const Divider(),
            _PermissionTile(
              title: 'Post notifications',
              subtitle: 'Required to display the persistent foreground-service notification.',
              status: _postNotifications,
              onOpen: () async {
                await PanopticonPermissions.requestPostNotifications();
                await Future<void>.delayed(const Duration(milliseconds: 300));
                await _refresh();
              },
            ),
            _PermissionTile(
              title: 'Disable battery optimization',
              subtitle: 'Lets the foreground service survive aggressive Doze killing.',
              status: _batteryOpt,
              onOpen: () async {
                await PanopticonPermissions.openBatteryOptimizationSettings();
              },
            ),
          ],
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onOpen,
  });

  final String title;
  final String subtitle;
  final PanopticonPermissionStatus status;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, color, label) = switch (status) {
      PanopticonPermissionStatus.granted => (Icons.check_circle, cs.primary, 'Granted'),
      PanopticonPermissionStatus.denied => (Icons.cancel_outlined, cs.error, 'Not granted'),
      PanopticonPermissionStatus.unavailable => (Icons.block, cs.outline, 'Unavailable'),
      PanopticonPermissionStatus.unknown => (Icons.help_outline, cs.outline, 'Unknown'),
    };
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text('$subtitle\n$label', maxLines: 4),
      isThreeLine: true,
      trailing: status == PanopticonPermissionStatus.granted
          ? null
          : FilledButton.tonal(
              onPressed: onOpen,
              child: const Text('Open'),
            ),
      onTap: onOpen,
    );
  }
}
