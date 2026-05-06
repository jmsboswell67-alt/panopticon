import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../data/event_models.dart';
import '../../data/providers.dart';
import 'daily_checkin_screen.dart';
import 'journal_entry_screen.dart';
import 'notable_event_screen.dart';

/// Browse + edit + delete past manual entries (journal, check-in, notable
/// event). Streams from the DB so deletions and saves refresh in place.
class ManualHistoryScreen extends ConsumerWidget {
  const ManualHistoryScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ManualHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEntries = ref.watch(manualEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: asyncEntries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load: $e')),
          data: (entries) {
            if (entries.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No manual entries yet. Add a journal entry, check-in, or '
                    'notable event from the Log tab.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _EntryRow(event: entries[i]),
            );
          },
        ),
      ),
    );
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ts = DateTime.fromMillisecondsSinceEpoch(event.timestampUtc);
    final tsStr = DateFormat.yMMMEd().add_jm().format(ts);
    final (icon, title, subtitle) = _summarise(event);

    return Dismissible(
      key: ValueKey('manual-${event.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final repo = ref.read(manualRepositoryProvider);
        await repo.deleteManualEvent(event.id);
        messenger.showSnackBar(SnackBar(content: Text('Deleted "$title".')));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(Icons.delete_outline,
            color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text('$tsStr\n$subtitle', maxLines: 3, overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => _edit(context),
      ),
    );
  }

  void _edit(BuildContext context) {
    switch (event.eventType) {
      case ManualEventType.journalEntry:
        JournalEntryScreen.push(context, editing: event);
      case ManualEventType.dailyCheckin:
        DailyCheckinScreen.push(context, editing: event);
      case ManualEventType.notableEvent:
        NotableEventScreen.push(context, editing: event);
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text(
            'This permanently removes the entry. Any safety flags it triggered are also removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
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
    return ok ?? false;
  }

  (IconData, String, String) _summarise(Event event) {
    Map<String, dynamic>? payload;
    final raw = event.payloadJson;
    if (raw != null) {
      try {
        payload = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    payload ??= const {};

    switch (event.eventType) {
      case ManualEventType.journalEntry:
        final text = (payload['text'] as String?) ?? '';
        return (
          Icons.edit_note_outlined,
          'Journal entry',
          text.isEmpty ? '(empty)' : text.substring(0, text.length.clamp(0, 140)),
        );
      case ManualEventType.dailyCheckin:
        final scales = (payload['scales'] as List?) ?? const [];
        return (
          Icons.tune,
          'Daily check-in',
          '${scales.length} scale(s) recorded',
        );
      case ManualEventType.notableEvent:
        final title = (payload['title'] as String?) ?? '(untitled)';
        final desc = (payload['description'] as String?) ?? '';
        return (
          Icons.bookmark_outline,
          title,
          desc.isEmpty ? '(no description)' : desc,
        );
      default:
        return (Icons.bubble_chart_outlined, event.eventType, '');
    }
  }
}
