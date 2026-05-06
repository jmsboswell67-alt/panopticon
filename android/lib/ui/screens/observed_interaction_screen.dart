import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import 'crisis_screen.dart';

class ObservedInteractionScreen extends ConsumerStatefulWidget {
  const ObservedInteractionScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ObservedInteractionScreen()),
    );
  }

  @override
  ConsumerState<ObservedInteractionScreen> createState() =>
      _ObservedInteractionScreenState();
}

class _ObservedInteractionScreenState
    extends ConsumerState<ObservedInteractionScreen> {
  static const _categories = [
    'animal', 'family', 'friend', 'partner', 'stranger', 'colleague', 'child',
    'self', 'other',
  ];
  static const _valences = ['positive', 'neutral', 'negative', 'mixed'];

  String _category = 'friend';
  String _valence = 'neutral';
  int _intensity = 3;
  final _partiesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _partiesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final parties = _partiesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final repo = ref.read(manualRepositoryProvider);
      await repo.saveObservedInteraction(
        category: _category,
        valence: _valence,
        intensity: _intensity,
        parties: parties,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interaction logged.')),
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
        title: const Text('Observed interaction'),
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
              'A discrete moment you want timestamped now rather than '
              'retrospectively at end-of-day.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category', border: OutlineInputBorder()),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _valence,
              decoration: const InputDecoration(
                labelText: 'Valence', border: OutlineInputBorder()),
              items: _valences
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _valence = v ?? _valence),
            ),
            const SizedBox(height: 12),
            Text('Intensity: $_intensity', style: Theme.of(context).textTheme.titleSmall),
            Slider(
              min: 1,
              max: 5,
              divisions: 4,
              value: _intensity.toDouble(),
              label: '$_intensity',
              onChanged: (v) => setState(() => _intensity = v.round()),
            ),
            TextField(
              controller: _partiesCtrl,
              decoration: const InputDecoration(
                labelText: 'Parties (comma-separated, free-form)',
                hintText: 'e.g. mom, Cooper',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
