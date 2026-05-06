import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/providers.dart';
import '../../permissions/installed_apps.dart';

/// Manage the per-app text-capture allowlist. Empty by default; the user
/// adds individual apps they want the accessibility service to read text
/// from (e.g. TikTok, Instagram). Adding an app here flips text capture
/// on for it; removing turns it back off.
class TextCaptureScreen extends ConsumerWidget {
  const TextCaptureScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const TextCaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(textCaptureAllowlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Text capture')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _ExplainerCard(),
            const SizedBox(height: 16),
            Text('Allowlist',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            asyncList.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Failed to load allowlist: $e'),
              data: (rows) => rows.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Empty. Text capture is currently OFF for every app.',
                        ),
                      ),
                    )
                  : Column(
                      children: rows
                          .map((r) => _AllowlistTile(row: r))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add an app'),
              onPressed: () => _AppPickerSheet.show(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplainerCard extends StatelessWidget {
  const _ExplainerCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.tertiary),
                const SizedBox(width: 8),
                Text('Read this first',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Adding an app to this list lets Panopticon read all text '
              'currently visible inside that app — captions, post text, '
              'creator handles, hashtags, like counts, anything rendered '
              'on screen. It does NOT capture password fields or fields '
              'you type into. Capture happens only while the app is in the '
              'foreground, and is throttled to one snapshot every ~2 seconds.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Use this for feed-style apps where what the algorithm shows '
              'you is the data you actually want — TikTok, Instagram, '
              'YouTube, Reddit. Do NOT add messaging apps, banking apps, '
              'or anything where on-screen text would surface other people\'s '
              'private info.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllowlistTile extends ConsumerWidget {
  const _AllowlistTile({required this.row});

  final TextCaptureAllowlistData row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.visibility_outlined),
        title: Text(row.displayName ?? row.packageName),
        subtitle: row.displayName == null
            ? null
            : Text(row.packageName,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
        trailing: IconButton(
          tooltip: 'Remove from allowlist',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await ref.read(textCaptureRepositoryProvider).remove(row.packageName);
            messenger.showSnackBar(
              SnackBar(content: Text('Removed ${row.displayName ?? row.packageName}.')),
            );
          },
        ),
      ),
    );
  }
}

class _AppPickerSheet {
  _AppPickerSheet._();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => _AppPickerSheetContent(controller: controller),
      ),
    );
  }
}

class _AppPickerSheetContent extends ConsumerStatefulWidget {
  const _AppPickerSheetContent({required this.controller});
  final ScrollController controller;

  @override
  ConsumerState<_AppPickerSheetContent> createState() => _AppPickerSheetContentState();
}

class _AppPickerSheetContentState extends ConsumerState<_AppPickerSheetContent> {
  late Future<List<InstalledApp>> _future;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _future = InstalledAppsBridge.list();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text('Add app to text-capture allowlist',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Filter by name…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (s) => setState(() => _filter = s.toLowerCase()),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<InstalledApp>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final apps = snap.data!.where((a) {
                  if (_filter.isEmpty) return true;
                  return a.displayName.toLowerCase().contains(_filter) ||
                      a.packageName.toLowerCase().contains(_filter);
                }).toList();
                return ListView.builder(
                  controller: widget.controller,
                  itemCount: apps.length,
                  itemBuilder: (context, i) {
                    final app = apps[i];
                    return ListTile(
                      title: Text(app.displayName),
                      subtitle: Text(app.packageName,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                      trailing: const Icon(Icons.add),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        await ref.read(textCaptureRepositoryProvider).add(
                              app.packageName,
                              displayName: app.displayName,
                            );
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(content: Text('Added ${app.displayName} to allowlist.')),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
