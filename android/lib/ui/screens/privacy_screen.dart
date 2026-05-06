import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/providers.dart';
import 'import_screen.dart';
import 'text_capture_screen.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalEventCountProvider);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(pinned: true, title: Text('Privacy')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where your data lives',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'All data is stored locally in a SQLite database on this device. '
                  'Nothing is uploaded anywhere by Phase 1 code paths. '
                  'There is no account, no analytics, no crash reporting.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.storage_outlined),
                    title: const Text('Total events stored'),
                    subtitle: totalAsync.when(
                      data: (n) =>
                          Text(NumberFormat.decimalPattern().format(n)),
                      loading: () => const Text('…'),
                      error: (_, _) => const Text('—'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList.list(
          children: [
            ListTile(
              leading: const Icon(Icons.input_outlined),
              title: const Text('Import desktop collector NDJSON'),
              subtitle: const Text(
                  'Bring in YouTube watch history, Spotify listens, etc. produced by the Python desktop collector.'),
              onTap: () => ImportScreen.push(context),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Text capture allowlist'),
              subtitle: const Text(
                  'Per-app opt-in for the accessibility service to read on-screen text. Off by default.'),
              onTap: () => TextCaptureScreen.push(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export everything as JSON'),
              subtitle: const Text(
                  'Writes a JSON file with every event, then offers it via the system share sheet.'),
              onTap: () => _export(context, ref),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete everything',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text(
                  'Wipes every event, session, notification, and rollup. Cannot be undone.'),
              onTap: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final events = await repo.allEvents();

      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      // NDJSON — one event per line. Same shape as the desktop collector
      // emits, so the Import screen accepts it without special-casing.
      final file = File(p.join(dir.path, 'panopticon-export-$stamp.ndjson'));
      final sink = file.openWrite();
      try {
        for (final e in events) {
          sink.writeln(jsonEncode({
            'timestamp_utc': e.timestampUtc,
            'timezone_offset': e.timezoneOffset,
            'source': e.source,
            'event_type': e.eventType,
            'package_name': e.packageName,
            'payload_json': e.payloadJson == null ? null : jsonDecode(e.payloadJson!),
            'schema_version': e.schemaVersion,
          }));
        }
      } finally {
        await sink.close();
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Panopticon export (${events.length} events)',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
            'This permanently removes every event, session, notification, and rollup stored on this device. There is no undo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(eventRepositoryProvider);
    final n = await repo.deleteAllEvents();
    messenger.showSnackBar(SnackBar(content: Text('Deleted $n events.')));
  }
}
