import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers.dart';
import 'crisis_screen.dart';
import 'daily_checkin_screen.dart';
import 'instrument_list_screen.dart';
import 'journal_entry_screen.dart';
import 'observed_interaction_screen.dart';

/// The "Log" tab — the place where the user puts data IN to Panopticon
/// (passive collection happens elsewhere). Lists the entry surfaces:
/// daily check-in, journal entry, observed interaction, instruments.
class LogScreen extends ConsumerWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Log'),
          actions: [
            IconButton(
              tooltip: 'Crisis resources',
              icon: const Icon(Icons.support_outlined),
              onPressed: () => CrisisScreen.push(context),
            ),
          ],
        ),
        SliverList.list(
          children: [
            _Section(
              title: 'Quick entries',
              children: [
                _Tile(
                  icon: Icons.tune,
                  title: 'Daily check-in',
                  subtitle:
                      'Sliding scales — mood, energy, focus, sleep, etc. ~1 min.',
                  onTap: () => DailyCheckinScreen.push(context),
                ),
                _Tile(
                  icon: Icons.edit_note_outlined,
                  title: 'Journal entry',
                  subtitle:
                      'Free prose. Auto-tagged with section & self-hypothesis hints.',
                  onTap: () => JournalEntryScreen.push(context),
                ),
                _Tile(
                  icon: Icons.bolt_outlined,
                  title: 'Observed interaction',
                  subtitle:
                      'Timestamp a moment — interaction with a person or animal.',
                  onTap: () => ObservedInteractionScreen.push(context),
                ),
              ],
            ),
            _Section(
              title: 'Instruments',
              children: [
                _Tile(
                  icon: Icons.assignment_outlined,
                  title: 'Browse all instruments',
                  subtitle:
                      'PHQ-9, GAD-7, WHO-5, IRI, MFQ-30 — cadence varies. Each shows tier & last administered.',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const InstrumentListScreen()),
                  ),
                ),
              ],
            ),
            const _Section(
              title: 'Recent activity',
              children: [_RecentActivity()],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manual = ref.watch(manualRepositoryProvider);
    return FutureBuilder<List<DateTime?>>(
      future: Future.wait([
        manual.latestJournalEntry().then((e) =>
            e == null ? null : DateTime.fromMillisecondsSinceEpoch(e.timestampUtc)),
        manual.latestCheckin().then((e) =>
            e == null ? null : DateTime.fromMillisecondsSinceEpoch(e.timestampUtc)),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 24);
        final lastJournal = snapshot.data![0];
        final lastCheckin = snapshot.data![1];
        String fmt(DateTime? t) =>
            t == null ? 'never' : DateFormat.yMMMd().add_jm().format(t);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last journal entry: ${fmt(lastJournal)}'),
                const SizedBox(height: 4),
                Text('Last check-in: ${fmt(lastCheckin)}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
