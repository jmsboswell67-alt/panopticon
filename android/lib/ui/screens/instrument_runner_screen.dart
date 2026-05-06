import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../instruments/instrument.dart';
import 'crisis_screen.dart';

/// Generic instrument administration UI. Walks the instrument's parts and
/// items, collects responses, and persists on submit. Endorsing a
/// `safety_critical` item with a non-zero/positive value pushes the crisis
/// screen immediately.
class InstrumentRunnerScreen extends ConsumerStatefulWidget {
  const InstrumentRunnerScreen({super.key, required this.instrument});

  final Instrument instrument;

  static Future<void> push(BuildContext context, Instrument instrument) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => InstrumentRunnerScreen(instrument: instrument),
      ),
    );
  }

  @override
  ConsumerState<InstrumentRunnerScreen> createState() =>
      _InstrumentRunnerScreenState();
}

class _InstrumentRunnerScreenState
    extends ConsumerState<InstrumentRunnerScreen> {
  final Map<String, Object?> _responses = {};
  bool _saving = false;

  Instrument get _i => widget.instrument;

  void _setResponse(InstrumentItem item, Object? value) {
    setState(() => _responses[item.id] = value);
    if (item.safetyCritical) _maybeTriggerCrisis(item, value);
  }

  void _maybeTriggerCrisis(InstrumentItem item, Object? value) {
    final endorsed = switch (value) {
      num n => n > 0,
      String s => s != 'none' && s.isNotEmpty,
      _ => false,
    };
    if (!endorsed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CrisisScreen.push(
        context,
        triggerSummary:
            'Triggered by ${_i.name} — ${item.id} (item flagged as safety-critical).',
      );
    });
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(instrumentRepositoryProvider);
      final result = await repo.saveAdministration(
        instrument: _i,
        responses: _responses,
      );
      if (!mounted) return;

      // Surface crisis if any safety-category flag fired during scoring.
      final safetyFlag = result.firedFlags.cast<dynamic>().firstWhere(
            (f) => f.isSafetyCategory && f.isConcernOrAbove,
            orElse: () => null,
          );
      if (safetyFlag != null) {
        await CrisisScreen.push(
          context,
          triggerSummary:
              'Score on ${_i.name} triggered the crisis path.',
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${_i.name}.')),
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
    final cs = Theme.of(context).colorScheme;
    final allItems = _i.allItems.toList();
    final answered = _responses.keys.where((k) => _responses[k] != null).length;
    final progress = allItems.isEmpty ? 0.0 : answered / allItems.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_i.name),
        actions: [
          IconButton(
            tooltip: 'Crisis resources',
            icon: const Icon(Icons.support_outlined),
            onPressed: () => CrisisScreen.push(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TierBanner(tier: _i.tier),
            const SizedBox(height: 12),
            Text(
              _i.purpose,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            for (final part in _i.parts) ...[
              if (part.stem != null) ...[
                Text(
                  part.stem!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
              ],
              for (final item in part.items)
                _ItemTile(
                  item: item,
                  value: _responses[item.id],
                  onChanged: (v) => _setResponse(item, v),
                ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Saving…' : 'Save administration'),
            ),
            const SizedBox(height: 8),
            Text(
              'Answered $answered of ${allItems.length}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TierBanner extends StatelessWidget {
  const _TierBanner({required this.tier});

  final InstrumentTier tier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isValidated = tier == InstrumentTier.validatedScreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isValidated ? cs.primaryContainer : cs.tertiaryContainer)
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(isValidated ? Icons.verified_outlined : Icons.tune,
              size: 18,
              color: isValidated ? cs.onPrimaryContainer : cs.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tier.label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const Text(
            'Not a diagnosis',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.value, required this.onChanged});

  final InstrumentItem item;
  final Object? value;
  final ValueChanged<Object?> onChanged;

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
                Expanded(
                  child: Text(
                    item.prompt,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (item.safetyCritical) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Safety-critical item',
                    child: Icon(Icons.shield_moon_outlined,
                        color: Theme.of(context).colorScheme.error, size: 18),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _renderInput(context),
          ],
        ),
      ),
    );
  }

  Widget _renderInput(BuildContext context) {
    final fmt = item.responseFormat;
    return switch (fmt) {
      LikertResponseFormat(:final options) => _LikertInput(
          options: options,
          value: value is num ? (value as num).toDouble() : null,
          onChanged: onChanged,
        ),
      LikertScaleResponseFormat(:final min, :final max, :final anchorLow, :final anchorHigh) =>
        _SliderInput(
          min: min,
          max: max,
          anchorLow: anchorLow,
          anchorHigh: anchorHigh,
          value: value is num ? (value as num).toDouble() : null,
          onChanged: onChanged,
        ),
      IntegerResponseFormat(:final min, :final max) => _IntegerInput(
          min: min,
          max: max,
          value: value is num ? (value as num).toInt() : null,
          onChanged: onChanged,
        ),
      EnumResponseFormat(:final options) => _EnumInput(
          options: options,
          value: value as String?,
          onChanged: onChanged,
        ),
      TextResponseFormat _ => _TextInput(
          value: value as String?,
          onChanged: onChanged,
        ),
    };
  }
}

class _LikertInput extends StatelessWidget {
  const _LikertInput({required this.options, required this.value, required this.onChanged});

  final List<LikertOption> options;
  final double? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options
          .map((o) => RadioListTile<double>(
                value: o.value,
                // ignore: deprecated_member_use
                groupValue: value,
                // ignore: deprecated_member_use
                onChanged: (v) => onChanged(v),
                title: Text(o.label),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ))
          .toList(),
    );
  }
}

class _SliderInput extends StatelessWidget {
  const _SliderInput({
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
            Expanded(
              child: Text(
                anchorLow ?? '$min',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              value == null ? 'tap to set' : value!.round().toString(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Expanded(
              child: Text(
                anchorHigh ?? '$max',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IntegerInput extends StatefulWidget {
  const _IntegerInput({required this.min, required this.max, required this.value, required this.onChanged});

  final int? min;
  final int? max;
  final int? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_IntegerInput> createState() => _IntegerInputState();
}

class _IntegerInputState extends State<_IntegerInput> {
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
      onChanged: (s) {
        final parsed = int.tryParse(s);
        widget.onChanged(parsed);
      },
    );
  }
}

class _EnumInput extends StatelessWidget {
  const _EnumInput({required this.options, required this.value, required this.onChanged});

  final List<EnumOption> options;
  final String? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options
          .map((o) => RadioListTile<String>(
                value: o.value,
                // ignore: deprecated_member_use
                groupValue: value,
                // ignore: deprecated_member_use
                onChanged: (v) => onChanged(v),
                title: Text(o.label),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ))
          .toList(),
    );
  }
}

class _TextInput extends StatefulWidget {
  const _TextInput({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.value ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      maxLines: 3,
      minLines: 1,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      onChanged: widget.onChanged,
    );
  }
}
