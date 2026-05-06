import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../data/import_service.dart';
import '../../data/providers.dart';

/// Phone-side counterpart to the Python desktop collector. Picks an NDJSON
/// file, previews it, and commits on confirmation.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ImportScreen()),
    );
  }

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportPreview? _preview;
  bool _loading = false;
  bool _committing = false;
  String? _error;

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _error = null;
      _preview = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) {
        setState(() => _loading = false);
        return;
      }
      final file = File(result.files.single.path!);
      final preview =
          await ref.read(importServiceProvider).preview(file);
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _commit() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() => _committing = true);
    try {
      final n = await ref.read(importServiceProvider).commit(preview);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $n event(s).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return Scaffold(
      appBar: AppBar(title: const Text('Import data export')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Import an NDJSON file produced by the desktop collector — your '
              'YouTube watch history from Google Takeout, Spotify streaming '
              'history, etc. Each line in the file is one event.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(_loading ? 'Reading…' : 'Choose NDJSON file'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                ),
              ),
            ],
            if (preview != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.basename(preview.file.path),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _StatRow(
                        label: 'Read from file',
                        value: NumberFormat.decimalPattern().format(preview.totalLines),
                      ),
                      _StatRow(
                        label: 'Already in your database',
                        value: NumberFormat.decimalPattern().format(preview.duplicateCount),
                        muted: true,
                      ),
                      _StatRow(
                        label: 'New, ready to import',
                        value: NumberFormat.decimalPattern().format(preview.validCount),
                        emphasised: true,
                      ),
                      if (preview.eventTypeCounts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Breakdown of new events:'),
                        for (final entry in preview.eventTypeCounts.entries)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(
                              '· ${entry.key}: '
                              '${NumberFormat.decimalPattern().format(entry.value)}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                          ),
                      ],
                      if (preview.hasIssues) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Skipped ${preview.issues.length} malformed line(s)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                        for (final issue in preview.issues.take(5))
                          Text('· $issue',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: !preview.isImportable || _committing ? null : _commit,
                child: Text(_committing ? 'Importing…' : 'Import these events'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading || _committing ? null : _pickFile,
                child: const Text('Pick a different file'),
              ),
              const SizedBox(height: 24),
              Text(
                'Re-imports are deduplicated by (source, event_type, '
                'timestamp, payload-hash) — importing the same file twice '
                'is safe and won\'t produce duplicates.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.emphasised = false,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool emphasised;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = muted ? cs.onSurfaceVariant : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
          Text(
            value,
            style: (emphasised
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyLarge)
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
