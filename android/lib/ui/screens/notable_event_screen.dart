import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/manual_repository.dart';
import '../../data/providers.dart';
import 'crisis_screen.dart';

/// Notable life event tracker — a discrete moment worth marking, optionally
/// backdated. Replaces the older "observed interaction" surface; the schema
/// keeps both event types so prior data is preserved.
class NotableEventScreen extends ConsumerStatefulWidget {
  const NotableEventScreen({super.key, this.editing});

  final Event? editing;

  static Future<void> push(BuildContext context, {Event? editing}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => NotableEventScreen(editing: editing)),
    );
  }

  @override
  ConsumerState<NotableEventScreen> createState() => _NotableEventScreenState();
}

class _NotableEventScreenState extends ConsumerState<NotableEventScreen> {
  static const _suggestedCategories = <String>[
    'milestone',
    'win',
    'loss',
    'change',
    'conflict',
    'medical',
    'travel',
    'relationship',
    'work',
    'family',
    'other',
  ];

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _category;
  late DateTime _occurredAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      final fields = ManualPayloads.notableFields(widget.editing!);
      _titleCtrl.text = fields.title;
      _descCtrl.text = fields.description ?? '';
      _category = fields.category;
      _occurredAt = fields.occurredAt;
    } else {
      _occurredAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 50)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    setState(() {
      if (time == null) {
        _occurredAt = DateTime(date.year, date.month, date.day,
            _occurredAt.hour, _occurredAt.minute);
      } else {
        _occurredAt = DateTime(
            date.year, date.month, date.day, time.hour, time.minute);
      }
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(manualRepositoryProvider);
      final desc = _descCtrl.text.trim();
      if (widget.editing == null) {
        await repo.saveNotableEvent(
          title: title,
          description: desc.isEmpty ? null : desc,
          category: _category,
          occurredAt: _occurredAt,
        );
      } else {
        await repo.updateNotableEvent(
          eventId: widget.editing!.id,
          title: title,
          description: desc.isEmpty ? null : desc,
          category: _category,
          occurredAt: _occurredAt,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.editing == null
            ? 'Notable event saved.'
            : 'Notable event updated.')),
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
        title: Text(widget.editing == null ? 'Notable event' : 'Edit notable event'),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'A discrete moment worth marking — milestone, loss, change, '
              'conflict, anything you might want to look back on later. Use the '
              'date picker to log something that happened earlier.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('When this happened'),
                subtitle: Text(
                  '${_occurredAt.year}-${_occurredAt.month.toString().padLeft(2, '0')}-${_occurredAt.day.toString().padLeft(2, '0')}'
                  '  '
                  '${_occurredAt.hour.toString().padLeft(2, '0')}:${_occurredAt.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem(value: null, child: Text('— none —')),
                ..._suggestedCategories.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
