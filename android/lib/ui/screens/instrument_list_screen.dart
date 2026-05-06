import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers.dart';
import '../../instruments/instrument.dart';
import 'instrument_detail_screen.dart';

class InstrumentListScreen extends ConsumerWidget {
  const InstrumentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(availableInstrumentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Instruments')),
      body: SafeArea(
        child: asyncList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load instruments: $e')),
          data: (list) => ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (_, i) => _InstrumentCard(instrument: list[i]),
          ),
        ),
      ),
    );
  }
}

class _InstrumentCard extends ConsumerWidget {
  const _InstrumentCard({required this.instrument});

  final Instrument instrument;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastAsync = ref.watch(lastAdministeredProvider(instrument.id));
    return Card(
      child: ListTile(
        title: Text(instrument.name),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instrument.tier.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                instrument.purpose,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              lastAsync.when(
                data: (when) => Text(
                  when == null
                      ? 'Never administered · ~${instrument.estimatedMinutes} min'
                      : 'Last: ${DateFormat.yMMMd().add_jm().format(when)} · ~${instrument.estimatedMinutes} min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                loading: () => const SizedBox(height: 14),
                error: (_, _) => const SizedBox(height: 14),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
        onTap: () => InstrumentDetailScreen.push(context, instrument),
      ),
    );
  }
}
