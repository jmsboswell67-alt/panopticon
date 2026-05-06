import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/manual_repository.dart';
import '../../data/providers.dart';
import 'crisis_screen.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({super.key, this.editing});

  /// When non-null, edits this existing journal_entry event instead of
  /// creating a new one.
  final Event? editing;

  static Future<void> push(BuildContext context, {Event? editing}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => JournalEntryScreen(editing: editing)),
    );
  }

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  late final TextEditingController _ctrl;
  late final DateTime _started;
  late DateTime _at;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    _ctrl = TextEditingController(
        text: widget.editing == null ? '' : ManualPayloads.journalText(widget.editing!));
    _at = widget.editing == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(widget.editing!.timestampUtc);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(manualRepositoryProvider);
      final result = widget.editing == null
          ? await repo.saveJournalEntry(
              text: text,
              completionSeconds:
                  DateTime.now().difference(_started).inSeconds,
              at: _at,
            )
          : await repo.updateJournalEntry(
              eventId: widget.editing!.id,
              text: text,
              completionSeconds:
                  DateTime.now().difference(_started).inSeconds,
              at: _at,
            );

      if (!mounted) return;
      if (result.pipeline.safety.isNotEmpty) {
        await CrisisScreen.push(
          context,
          triggerSummary:
              'Your journal mentioned phrases the safety scanner flagged.',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${widget.editing == null ? 'Saved' : 'Updated'}. '
              '${result.pipeline.sections.length} section(s), '
              '${result.pipeline.selfHypotheses.length} self-hypothesis pattern(s) detected.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (time == null) return;
    setState(() => _at =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing == null ? 'Journal entry' : 'Edit entry'),
        actions: [
          IconButton(
            tooltip: 'Crisis resources',
            icon: const Icon(Icons.support_outlined),
            onPressed: () => CrisisScreen.push(context),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Free prose. Anything from a sentence to a few paragraphs. The '
                'pipeline tags sections, pulls out self-hypotheses, and computes '
                'linguistic metrics — without modifying what you wrote.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Date this entry is for'),
                  subtitle: Text(
                    '${_at.year}-${_at.month.toString().padLeft(2, '0')}-${_at.day.toString().padLeft(2, '0')}'
                    '  '
                    '${_at.hour.toString().padLeft(2, '0')}:${_at.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _pickDateTime,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'How was today?',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
