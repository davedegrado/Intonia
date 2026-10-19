import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/date_format.dart';
import '../../../app/l10n.dart';
import '../../../app/note_text.dart';
import '../../../core/music/note.dart';
import '../domain/tessitura.dart';

/// Etichetta dell'affidabilità nella lingua attiva.
String reliabilityLabel(AppLocalizations l10n, TessituraReliability reliability) =>
    switch (reliability) {
      TessituraReliability.low => l10n.tessituraReliabilityLow,
      TessituraReliability.medium => l10n.tessituraReliabilityMedium,
      TessituraReliability.high => l10n.tessituraReliabilityHigh,
    };

/// Riepilogo di un test di tessitura: mappa (estensione, zona comoda, note
/// da verificare), data, affidabilità e confronto con il test precedente.
class TessituraResultCard extends StatelessWidget {
  const TessituraResultCard({
    required this.record,
    required this.notation,
    this.previous,
    this.trailing,
    super.key,
  });

  final TessituraRecord record;
  final TessituraRecord? previous;
  final NoteNotation notation;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final caption = theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant);
    final value = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);

    return Card(
      key: const ValueKey('tessitura-result'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.tessituraComfortZone,
                      style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
                ),
                Text(formatShortDate(record.timestamp), style: caption),
                if (trailing != null) trailing! else const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: record.hasZone
                  ? NoteRangeText(
                      key: const ValueKey('tessitura-zone'),
                      low: spelledMidi(record.comfortLow!),
                      high: spelledMidi(record.comfortHigh!),
                      notation: notation,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      octaveColor: colors.onSurfaceVariant,
                    )
                  : Text(l10n.tessituraNoZone, key: const ValueKey('tessitura-zone'), style: value),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(
                  icon: Icons.verified_outlined,
                  label: l10n.tessituraReliability(reliabilityLabel(l10n, record.reliability)),
                ),
                if (record.provisional)
                  _Chip(
                    key: const ValueKey('tessitura-provisional'),
                    icon: Icons.hourglass_bottom_rounded,
                    label: l10n.tessituraProvisional,
                    warning: true,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TessituraMap(record: record),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.rangeLow != null && record.rangeHigh != null)
                    NoteRangeText(
                      low: spelledMidi(record.rangeLow!),
                      high: spelledMidi(record.rangeHigh!),
                      notation: notation,
                      prefix: '${l10n.tessituraMaxRange}: ',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (record.toVerify.isNotEmpty)
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '${l10n.tessituraToVerify}: '),
                        for (final (index, midi) in record.toVerify.indexed) ...[
                          if (index > 0) const TextSpan(text: ', '),
                          noteSpan(spelledMidi(midi), notation,
                              style: theme.textTheme.bodySmall ?? const TextStyle()),
                        ],
                      ]),
                      style: theme.textTheme.bodySmall,
                    ),
                  if (_comparison(l10n) case final text?) ...[
                    const SizedBox(height: 4),
                    Text(text,
                        key: const ValueKey('tessitura-compare'),
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confronto con il test precedente: ampiezza della zona comoda.
  String? _comparison(AppLocalizations l10n) {
    final before = previous;
    if (before == null || !before.hasZone || !record.hasZone) {
      return null;
    }
    final delta =
        (record.comfortHigh! - record.comfortLow!) - (before.comfortHigh! - before.comfortLow!);
    final date = formatShortDate(before.timestamp);
    return delta == 0
        ? l10n.tessituraCompareSame(date)
        : l10n.tessituraCompareDelta(date, '${delta > 0 ? '+' : ''}$delta');
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.warning = false, super.key});

  final IconData icon;
  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = warning ? colors.tertiary : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Mappa orizzontale: estensione massima (fascia tenue), zona comoda (fascia
/// colorata) e note da verificare (punti).
class TessituraMap extends StatelessWidget {
  const TessituraMap({required this.record, super.key});

  final TessituraRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final decor = context.decor;
    final notes = [
      if (record.rangeLow != null) record.rangeLow!,
      if (record.rangeHigh != null) record.rangeHigh!,
      if (record.comfortLow != null) record.comfortLow!,
      if (record.comfortHigh != null) record.comfortHigh!,
      ...record.toVerify,
    ];
    if (notes.isEmpty) {
      return const SizedBox.shrink();
    }
    final from = math.min(36, notes.reduce(math.min) - 2);
    final to = math.max(84, notes.reduce(math.max) + 2);
    double at(int midi) => (midi - from) / (to - from);

    return SizedBox(
      key: const ValueKey('tessitura-map'),
      height: 22,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          Widget band(int low, int high,
              {required double height, Color? color, Gradient? gradient}) {
            final left = width * at(low);
            final right = width * at(high);
            return Positioned(
              left: left,
              width: math.max(6, right - left),
              top: (22 - height) / 2,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              band(from, to, height: 6, color: colors.surfaceContainerHighest),
              if (record.rangeLow != null && record.rangeHigh != null)
                band(record.rangeLow!, record.rangeHigh!,
                    height: 10, color: colors.outlineVariant.withValues(alpha: 0.8)),
              if (record.hasZone)
                band(record.comfortLow!, record.comfortHigh!, height: 14, gradient: decor.spectrum),
              for (final midi in record.toVerify)
                Positioned(
                  left: width * at(midi) - 4,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: colors.tertiary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
