import 'package:flutter/material.dart';

import '../../../../app/l10n.dart';
import '../../../../core/session/session_stats.dart';

class SessionStatsPanel extends StatelessWidget {
  const SessionStatsPanel({
    required this.stats,
    super.key,
  });

  final SessionStats stats;

  @override
  Widget build(BuildContext context) {
    final accuracy = (stats.accuracy * 100).toStringAsFixed(0);
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.trainerSessionStats, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatTile(label: l10n.trainerStatTime, value: _formatDuration(stats.elapsed)),
                _StatTile(label: l10n.trainerStatErrors, value: '${stats.errors}'),
                _StatTile(label: l10n.trainerStatAccuracy, value: '$accuracy%'),
                _StatTile(label: l10n.trainerStatCorrect, value: '${stats.correctNotes}'),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: stats.accuracy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
