import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Surface that takes over when a `safety_critical` instrument item is
/// endorsed, when the safety regex matches journal/notes prose, or when
/// the user taps the always-visible crisis link.
///
/// Per docs/screening-instruments.md the LLM coaching layer is bypassed
/// while this is shown — we surface plain resources, that's it.
class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key, this.triggerSummary});

  /// Optional one-line description of what surfaced this screen, e.g.
  /// "Triggered by PHQ-9 question 9". Hidden if null.
  final String? triggerSummary;

  static Future<void> push(BuildContext context, {String? triggerSummary}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CrisisScreen(triggerSummary: triggerSummary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crisis resources'),
        backgroundColor: cs.errorContainer,
        foregroundColor: cs.onErrorContainer,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (triggerSummary != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: cs.onSurface),
                    const SizedBox(width: 12),
                    Expanded(child: Text(triggerSummary!)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'You don’t have to handle this alone.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'A real human will pick up. They’ve heard whatever you’re carrying. '
              'Calling or texting one of these is a reasonable next step.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const _ResourceCard(
              region: 'United States',
              name: '988 Suicide & Crisis Lifeline',
              detail: 'Call or text 988',
              copyValue: '988',
            ),
            const _ResourceCard(
              region: 'United Kingdom & Ireland',
              name: 'Samaritans',
              detail: 'Call 116 123',
              copyValue: '116 123',
            ),
            const _ResourceCard(
              region: 'International',
              name: 'Find a Helpline',
              detail: 'findahelpline.com',
              copyValue: 'https://findahelpline.com',
            ),
            const _ResourceCard(
              region: 'Emergency',
              name: 'Local emergency services',
              detail: '911 (US) / 999 (UK) / 112 (EU) / 000 (AU)',
              copyValue: '',
            ),
            const SizedBox(height: 24),
            Text(
              'A note about this app',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Panopticon is a research project, not a treatment tool. While this '
              'screen is showing, the AI coaching layer is bypassed. Your '
              'response was logged so trends can be reviewed later, but no '
              'AI-generated reply will be produced for this entry.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I’ve seen these. Continue.'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dismiss without continuing'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.region,
    required this.name,
    required this.detail,
    required this.copyValue,
  });

  final String region;
  final String name;
  final String detail;
  final String copyValue;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(name),
        subtitle: Text('$region\n$detail'),
        isThreeLine: true,
        trailing: copyValue.isEmpty
            ? null
            : IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: copyValue));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied: $copyValue')),
                  );
                },
              ),
      ),
    );
  }
}
