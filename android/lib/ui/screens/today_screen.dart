import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../data/event_models.dart';
import '../../data/providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalEventCountProvider);
    final recentAsync = ref.watch(recentEventsProvider());

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Today'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(recentEventsProvider),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Events observed (all time)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          totalAsync.when(
                            data: (n) => Text(
                              NumberFormat.decimalPattern().format(n),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            loading: () => const Text('—'),
                            error: (_, _) => const Text('—'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Recent events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        recentAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              );
            }
            return SliverList.builder(
              itemCount: events.length,
              itemBuilder: (context, i) => _EventTile(event: events[i]),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Error: $e')),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final ts = DateTime.fromMillisecondsSinceEpoch(event.timestampUtc).toLocal();
    final timeStr = DateFormat('MMM d, HH:mm:ss').format(ts);
    final subtitle = event.packageName ?? '—';

    return ListTile(
      dense: true,
      leading: _IconForSource(source: event.source),
      title: Text('${event.source} · ${event.eventType}'),
      subtitle: Text('$timeStr · $subtitle'),
      onTap: () => _showPayload(context, event),
    );
  }

  void _showPayload(BuildContext context, Event event) {
    final payloadStr = event.payloadJson == null
        ? '(no payload)'
        : const JsonEncoder.withIndent('  ')
            .convert(jsonDecode(event.payloadJson!));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              payloadStr,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconForSource extends StatelessWidget {
  const _IconForSource({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final icon = switch (source) {
      EventSource.accessibility => Icons.touch_app_outlined,
      EventSource.notification => Icons.notifications_outlined,
      EventSource.usagestats => Icons.bar_chart_outlined,
      EventSource.manual => Icons.edit_note_outlined,
      EventSource.instrument => Icons.assignment_outlined,
      EventSource.cognitiveTest => Icons.psychology_outlined,
      EventSource.coach => Icons.auto_awesome_outlined,
      _ => Icons.bubble_chart_outlined,
    };
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(icon, size: 18),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'No events captured yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Grant the three OS permissions on the Permissions tab to start observing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
