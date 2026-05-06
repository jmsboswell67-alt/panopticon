import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'crisis_screen.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const JournalEntryScreen()),
    );
  }

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  final _ctrl = TextEditingController();
  final _started = DateTime.now();
  bool _saving = false;

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
      final result = await repo.saveJournalEntry(
        text: text,
        completionSeconds:
            DateTime.now().difference(_started).inSeconds,
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
              'Journal saved. ${result.pipeline.sections.length} section(s), '
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal entry'),
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
                'pipeline tags sections (food, sleep, work, social, etc.), pulls '
                'out self-hypotheses ("I always X"), and computes some linguistic '
                'metrics — without modifying what you wrote.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
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
