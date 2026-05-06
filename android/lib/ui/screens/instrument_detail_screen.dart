import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/instrument_repository.dart';
import '../../data/providers.dart';
import '../../instruments/instrument.dart';
import '../../instruments/instrument_scoring.dart';
import 'instrument_runner_screen.dart';

/// Detail page for a single instrument. Shows tier, purpose, last
/// administered date, and a chronological list of past administrations
/// with computed scores. Tap an administration to see per-subscale
/// interpretation; swipe to delete.
class InstrumentDetailScreen extends ConsumerWidget {
  const InstrumentDetailScreen({super.key, required this.instrument});

  final Instrument instrument;

  static Future<void> push(BuildContext context, Instrument instrument) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => InstrumentDetailScreen(instrument: instrument),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(instrumentAdministrationsProvider(instrument.id));

    return Scaffold(
      appBar: AppBar(title: Text(instrument.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(instrument: instrument),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Take it now'),
              onPressed: () =>
                  InstrumentRunnerScreen.push(context, instrument),
            ),
            const SizedBox(height: 24),
            Text(
              'Past administrations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            asyncHistory.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Failed to load history: $e'),
              data: (admins) {
                if (admins.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'You haven’t taken this yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final a in admins)
                      _AdministrationCard(instrument: instrument, admin: a),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.instrument});
  final Instrument instrument;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isValidated = instrument.tier == InstrumentTier.validatedScreen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              Text(instrument.tier.label),
              const Spacer(),
              const Text('Not a diagnosis',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(instrument.purpose, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          '~${instrument.estimatedMinutes} min · suggested cadence: every '
          '${instrument.minimumIntervalDays} day(s)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AdministrationCard extends ConsumerWidget {
  const _AdministrationCard({required this.instrument, required this.admin});

  final Instrument instrument;
  final InstrumentAdministration admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ts = DateFormat.yMMMEd().add_jm().format(admin.at);
    final scorer = InstrumentScorer(instrument);

    final scoredEntries = admin.subscaleScores.entries.toList();
    final mainScore = scoredEntries.firstWhere(
      (e) => instrument.subscales.any(
        (s) => s.id == e.key && s.interpretation.isNotEmpty,
      ),
      orElse: () => scoredEntries.isEmpty
          ? const MapEntry('', 0)
          : scoredEntries.first,
    );
    final InterpretationRange? mainBand =
        scorer.interpretFor(mainScore.key, mainScore.value);

    return Dismissible(
      key: ValueKey('admin-${admin.eventId}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        await ref
            .read(instrumentRepositoryProvider)
            .deleteAdministration(admin.eventId);
        messenger.showSnackBar(
          SnackBar(content: Text('Deleted administration from $ts.')),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(Icons.delete_outline,
            color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      child: Card(
        child: ListTile(
          title: Text(ts),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mainScore.key.isNotEmpty)
                  Text(
                    '${_subscaleName(instrument, mainScore.key)}: '
                    '${_format(mainScore.value)}'
                    '${mainBand == null ? '' : ' · ${mainBand.label}'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (admin.subscaleScores.length > 1)
                  Text(
                    '${admin.subscaleScores.length - 1} more subscale(s) — tap for details',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showDetails(context),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete administration?'),
        content: const Text(
            'This permanently removes this administration and any flags it triggered.'),
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

  void _showDetails(BuildContext context) {
    final scorer = InstrumentScorer(instrument);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${instrument.name} · ${DateFormat.yMMMEd().add_jm().format(admin.at)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (admin.subscaleScores.isEmpty)
                  const Text('No computed scores for this instrument.'),
                for (final entry in admin.subscaleScores.entries)
                  _SubscaleRow(
                    instrument: instrument,
                    subscaleId: entry.key,
                    value: entry.value,
                    band: scorer.interpretFor(entry.key, entry.value),
                  ),
                const SizedBox(height: 16),
                if (admin.itemResponses.isNotEmpty) ...[
                  Text('Item responses', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (final ir in admin.itemResponses)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${ir.itemId} → ${ir.value}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _format(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String _subscaleName(Instrument instrument, String id) {
    for (final s in instrument.subscales) {
      if (s.id == id) return s.name;
    }
    return id;
  }
}

class _SubscaleRow extends StatelessWidget {
  const _SubscaleRow({
    required this.instrument,
    required this.subscaleId,
    required this.value,
    required this.band,
  });

  final Instrument instrument;
  final String subscaleId;
  final double value;
  final InterpretationRange? band;

  @override
  Widget build(BuildContext context) {
    final sub = instrument.subscales.firstWhere(
      (s) => s.id == subscaleId,
      orElse: () => Subscale(id: subscaleId, name: subscaleId, method: ''),
    );
    final cs = Theme.of(context).colorScheme;
    final color = switch (band?.severity) {
      'urgent' => cs.error,
      'concern' => cs.tertiary,
      'watch' => cs.secondary,
      _ => cs.onSurfaceVariant,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.name, style: Theme.of(context).textTheme.bodyMedium),
                if (band != null)
                  Text(
                    band!.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
                  ),
              ],
            ),
          ),
          Text(
            value == value.roundToDouble()
                ? value.toInt().toString()
                : value.toStringAsFixed(2),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
