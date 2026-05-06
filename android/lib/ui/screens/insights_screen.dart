import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers.dart';

/// Aggregate view of the data Panopticon has on you. Replaces the raw
/// "Today" event log as the default landing surface — that view is still
/// available via Privacy → "Browse raw events" (TODO).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(topAppsTodayProvider);
        ref.invalidate(screenTimeWeekProvider);
        ref.invalidate(notificationsTodayProvider);
        ref.invalidate(videoViewsMonthProvider);
        ref.invalidate(topChannelsProvider);
        ref.invalidate(topArtistsProvider);
        ref.invalidate(recentSearchesProvider);
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: const [
          SliverAppBar(pinned: true, title: Text('Insights')),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _ScreenTimeWeekCard(),
                SizedBox(height: 16),
                _TopAppsCard(),
                SizedBox(height: 16),
                _NotificationsTodayCard(),
                SizedBox(height: 16),
                _VideoViewsCard(),
                SizedBox(height: 16),
                _TopChannelsCard(),
                SizedBox(height: 16),
                _TopArtistsCard(),
                SizedBox(height: 16),
                _RecentSearchesCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Cards
// =============================================================================

class _ScreenTimeWeekCard extends ConsumerWidget {
  const _ScreenTimeWeekCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWeek = ref.watch(screenTimeWeekProvider);
    return _Card(
      title: 'Screen time, last 7 days',
      child: asyncWeek.when(
        loading: () => const _LoadingBlock(),
        error: (e, _) => Text('Error: $e'),
        data: (data) {
          if (data.every((d) => d.totalMs == 0)) {
            return const _EmptyHint(
                'No usagestats data yet — grant Usage Access on the Permissions tab.');
          }
          final today = data.last;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BigStat(
                value: _formatDuration(today.totalMs),
                label: 'today',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: _BarChart(
                  bars: [
                    for (var i = 0; i < data.length; i++)
                      _BarDatum(
                        x: i,
                        y: data[i].totalMs / 60000.0, // minutes
                        label: DateFormat.E().format(data[i].date),
                      ),
                  ],
                  yAxisLabel: 'min',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopAppsCard extends ConsumerWidget {
  const _TopAppsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTop = ref.watch(topAppsTodayProvider);
    return _Card(
      title: 'Top apps today',
      child: asyncTop.when(
        loading: () => const _LoadingBlock(),
        error: (e, _) => Text('Error: $e'),
        data: (slices) {
          if (slices.isEmpty) {
            return const _EmptyHint('No usagestats data captured yet today.');
          }
          final shown = slices.take(8).toList();
          final maxMs = shown.first.foregroundMs.toDouble();
          return Column(
            children: [
              for (final s in shown)
                _RankedRow(
                  label: _shortPackage(s.packageName),
                  sublabel: '${s.launchCount} launches',
                  value: _formatDuration(s.foregroundMs),
                  progress: maxMs == 0 ? 0 : s.foregroundMs / maxMs,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationsTodayCard extends ConsumerWidget {
  const _NotificationsTodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(notificationsTodayProvider);
    return _Card(
      title: 'Notifications today',
      child: asyncList.when(
        loading: () => const _LoadingBlock(),
        error: (e, _) => Text('Error: $e'),
        data: (counts) {
          if (counts.isEmpty) {
            return const _EmptyHint('No notifications captured today yet.');
          }
          final total = counts.fold<int>(0, (a, c) => a + c.count);
          final shown = counts.take(8).toList();
          final maxC = shown.first.count.toDouble();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BigStat(
                value: NumberFormat.decimalPattern().format(total),
                label: 'notifications, ${counts.length} app(s)',
              ),
              const SizedBox(height: 12),
              for (final c in shown)
                _RankedRow(
                  label: _shortPackage(c.packageName),
                  value: '${c.count}',
                  progress: maxC == 0 ? 0 : c.count / maxC,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VideoViewsCard extends ConsumerWidget {
  const _VideoViewsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMonth = ref.watch(videoViewsMonthProvider);
    return _Card(
      title: 'Video views, last 30 days',
      child: asyncMonth.when(
        loading: () => const _LoadingBlock(),
        error: (e, _) => Text('Error: $e'),
        data: (days) {
          final total = days.fold<int>(0, (a, d) => a + d.totalMs);
          if (total == 0) {
            return const _EmptyHint(
                'No video views imported yet. Try `panopticon-collector import` against a Google Takeout, then Privacy → Import.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BigStat(value: '$total', label: 'videos in 30 days'),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: _LineChart(
                  points: [
                    for (var i = 0; i < days.length; i++)
                      FlSpot(i.toDouble(), days[i].totalMs.toDouble()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopChannelsCard extends ConsumerWidget {
  const _TopChannelsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(topChannelsProvider);
    return _Card(
      title: 'Most-watched channels',
      child: asyncList.when(
        loading: () => const _LoadingBlock(),
        error: (e, _) => Text('Error: $e'),
        data: (counts) {
          if (counts.isEmpty) {
            return const _EmptyHint('No video data imported yet.');
          }
          final maxC = counts.first.count.toDouble();
          return Column(
            children: [
              for (final c in counts)
                _RankedRow(
                  label: c.name,
                  value: '${c.count}',
                  progress: maxC == 0 ? 0 : c.count / maxC,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TopArtistsCard extends ConsumerWidget {
  const _TopArtistsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(topArtistsProvider);
    return _Card(
      title: 'Most-played artists',
      child: asyncList.when(
        loading: () => const _LoadingBlock(),
        error: (e, _) => Text('Error: $e'),
        data: (counts) {
          if (counts.isEmpty) {
            return const _EmptyHint('No audio plays imported yet.');
          }
          final maxC = counts.first.count.toDouble();
          return Column(
            children: [
              for (final c in counts)
                _RankedRow(
                  label: c.name,
                  value: '${c.count}',
                  progress: maxC == 0 ? 0 : c.count / maxC,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RecentSearchesCard extends ConsumerWidget {
  const _RecentSearchesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(recentSearchesProvider);
    return _Card(
      title: 'Recent searches',
      child: asyncList.when(
        loading: () => const _LoadingBlock(),
        error: (e, _) => Text('Error: $e'),
        data: (queries) {
          if (queries.isEmpty) {
            return const _EmptyHint('No search queries imported yet.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final q in queries.take(15))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.query),
                            Text(
                              '${q.engine} · ${DateFormat.MMMd().add_jm().format(q.at)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// Reusable widgets
// =============================================================================

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.label,
    this.sublabel,
    required this.value,
    required this.progress,
  });

  final String label;
  final String? sublabel;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(sublabel!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(value,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _BarDatum {
  _BarDatum({required this.x, required this.y, required this.label});
  final int x;
  final double y;
  final String label;
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.bars, this.yAxisLabel});

  final List<_BarDatum> bars;
  final String? yAxisLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = bars.map((b) => b.y).fold<double>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY == 0 ? 1 : maxY * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(bars[i].label,
                      style: Theme.of(context).textTheme.bodySmall),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (final b in bars)
            BarChartGroupData(
              x: b.x,
              barRods: [
                BarChartRodData(
                  toY: b.y,
                  color: cs.primary,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.points});
  final List<FlSpot> points;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = points.map((p) => p.y).fold<double>(0, (a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            color: cs.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

String _formatDuration(int ms) {
  final totalMin = (ms / 60000).round();
  if (totalMin < 60) return '${totalMin}m';
  final h = totalMin ~/ 60;
  final m = totalMin % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String _shortPackage(String pkg) {
  // "com.zhiliaoapp.musically" → "musically"; cheap, no installed-app lookup.
  // The full package is shown on tap of an event row in the raw log.
  final parts = pkg.split('.');
  if (parts.length <= 1) return pkg;
  final last = parts.last;
  return last.isEmpty ? pkg : last;
}
