import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/manual_repository.dart';
import '../../data/providers.dart';
import '../../instruments/instrument.dart';
import 'crisis_screen.dart';

/// The daily check-in is the daily_scales instrument, persisted as a
/// `manual.daily_checkin` event (per the schema). Supports both new
/// administrations and editing a previous one.
class DailyCheckinScreen extends ConsumerWidget {
  const DailyCheckinScreen({super.key, this.editing});

  /// When non-null, edits this existing check-in event instead of creating
  /// a new one.
  final Event? editing;

  static Future<void> push(BuildContext context, {Event? editing}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => DailyCheckinScreen(editing: editing)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInstr = ref.watch(instrumentByIdProvider('daily_scales'));
    return Scaffold(
      appBar: AppBar(
        title: Text(editing == null ? 'Daily check-in' : 'Edit check-in'),
        actions: [
          IconButton(
            tooltip: 'Crisis resources',
            icon: const Icon(Icons.support_outlined),
            onPressed: () => CrisisScreen.push(context),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncInstr.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load: $e')),
          data: (instrument) =>
              _CheckinForm(instrument: instrument, editing: editing),
        ),
      ),
    );
  }
}

class _CheckinForm extends ConsumerStatefulWidget {
  const _CheckinForm({required this.instrument, required this.editing});
  final Instrument instrument;
  final Event? editing;

  @override
  ConsumerState<_CheckinForm> createState() => _CheckinFormState();
}

class _CheckinFormState extends ConsumerState<_CheckinForm> {
  final Map<String, Object?> _values = {};
  final Set<String> _skipped = {};
  bool _saving = false;
  late DateTime _at;

  @override
  void initState() {
    super.initState();
    _at = widget.editing == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(widget.editing!.timestampUtc);
    if (widget.editing != null) {
      for (final s in ManualPayloads.checkinScales(widget.editing!)) {
        if (s.skipped) {
          _skipped.add(s.scaleId);
        } else {
          _values[s.scaleId] = s.value;
        }
      }
    }
  }

  bool _isEndorsedSafetyCritical(InstrumentItem item, Object? value) {
    if (!item.safetyCritical) return false;
    if (value is num) return value > 0;
    if (value is String) {
      return value == 'active_no_plan' || value == 'active_with_plan';
    }
    return false;
  }

  void _set(InstrumentItem item, Object? value) {
    setState(() {
      _values[item.id] = value;
      _skipped.remove(item.id);
    });
    if (_isEndorsedSafetyCritical(item, value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CrisisScreen.push(
          context,
          triggerSummary:
              'Daily check-in: "${item.prompt}" answered with a value flagged as safety-critical.',
        );
      });
    }
  }

  void _toggleSkip(InstrumentItem item) {
    setState(() {
      if (_skipped.contains(item.id)) {
        _skipped.remove(item.id);
      } else {
        _skipped.add(item.id);
        _values.remove(item.id);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final scales = <DailyCheckinScale>[];
      for (final item in widget.instrument.allItems) {
        if (_skipped.contains(item.id)) {
          scales.add(DailyCheckinScale(scaleId: item.id, value: null, skipped: true));
          continue;
        }
        final v = _values[item.id];
        if (v == null) continue;
        scales.add(DailyCheckinScale(scaleId: item.id, value: v));
      }
      final repo = ref.read(manualRepositoryProvider);
      if (widget.editing == null) {
        await repo.saveDailyCheckin(scales: scales, at: _at);
      } else {
        await repo.updateDailyCheckin(
          eventId: widget.editing!.id,
          scales: scales,
          at: _at,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.editing == null
            ? 'Saved ${scales.length} response(s).'
            : 'Updated check-in.')),
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
    final i = widget.instrument;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          i.purpose,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _DateTimePickerTile(
          value: _at,
          label: 'When this check-in is for',
          onChanged: (d) => setState(() => _at = d),
        ),
        const SizedBox(height: 8),
        for (final item in i.allItems)
          _Row(
            item: item,
            value: _values[item.id],
            skipped: _skipped.contains(item.id),
            onChanged: (v) => _set(item, v),
            onToggleSkip: () => _toggleSkip(item),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving
              ? 'Saving…'
              : widget.editing == null ? 'Save check-in' : 'Update check-in'),
        ),
      ],
    );
  }
}

class _DateTimePickerTile extends StatelessWidget {
  const _DateTimePickerTile({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final DateTime value;
  final String label;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_outlined),
        title: Text(label),
        subtitle: Text(
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'
          '  '
          '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
        ),
        trailing: const Icon(Icons.edit_calendar),
        onTap: () => _pick(context),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.value,
    required this.skipped,
    required this.onChanged,
    required this.onToggleSkip,
  });

  final InstrumentItem item;
  final Object? value;
  final bool skipped;
  final ValueChanged<Object?> onChanged;
  final VoidCallback onToggleSkip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.prompt, style: Theme.of(context).textTheme.bodyLarge)),
                if (item.safetyCritical)
                  Tooltip(
                    message: 'Safety-critical',
                    child: Icon(Icons.shield_moon_outlined,
                        color: Theme.of(context).colorScheme.error, size: 18),
                  ),
                IconButton(
                  tooltip: skipped ? 'Undo skip' : 'Skip',
                  icon: Icon(skipped ? Icons.undo : Icons.skip_next_outlined),
                  onPressed: onToggleSkip,
                ),
              ],
            ),
            if (skipped)
              Text(
                'Skipped — tap the undo arrow to answer it again.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              _input(context),
          ],
        ),
      ),
    );
  }

  Widget _input(BuildContext context) {
    final fmt = item.responseFormat;
    return switch (fmt) {
      LikertScaleResponseFormat(:final min, :final max, :final anchorLow, :final anchorHigh) =>
        _Slider(
          min: min,
          max: max,
          anchorLow: anchorLow,
          anchorHigh: anchorHigh,
          value: value is num ? (value as num).toDouble() : null,
          onChanged: onChanged,
        ),
      IntegerResponseFormat(:final min, :final max) => _IntField(
          min: min,
          max: max,
          value: value is num ? (value as num).toInt() : null,
          onChanged: onChanged,
        ),
      EnumResponseFormat(:final options) => Column(
          children: options
              .map((o) => RadioListTile<String>(
                    value: o.value,
                    // ignore: deprecated_member_use
                    groupValue: value as String?,
                    // ignore: deprecated_member_use
                    onChanged: (v) => onChanged(v),
                    title: Text(o.label),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.min,
    required this.max,
    required this.anchorLow,
    required this.anchorHigh,
    required this.value,
    required this.onChanged,
  });
  final int min;
  final int max;
  final String? anchorLow;
  final String? anchorHigh;
  final double? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = value ?? ((min + max) / 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Slider(
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          value: v.clamp(min.toDouble(), max.toDouble()),
          label: v.round().toString(),
          onChanged: (nv) => onChanged(nv.round()),
        ),
        Row(
          children: [
            Expanded(child: Text(anchorLow ?? '$min', style: Theme.of(context).textTheme.bodySmall)),
            Text(
              value == null ? 'tap to set' : value!.round().toString(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Expanded(
              child: Text(anchorHigh ?? '$max',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ],
    );
  }
}

class _IntField extends StatefulWidget {
  const _IntField({required this.min, required this.max, required this.value, required this.onChanged});
  final int? min;
  final int? max;
  final int? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<_IntField> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value?.toString() ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        helperText: widget.min != null || widget.max != null
            ? 'Range: ${widget.min ?? '−∞'} to ${widget.max ?? '∞'}'
            : null,
      ),
      onChanged: (s) => widget.onChanged(int.tryParse(s)),
    );
  }
}
