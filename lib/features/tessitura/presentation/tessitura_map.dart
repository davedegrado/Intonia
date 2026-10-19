import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/date_format.dart';
import '../../../app/l10n.dart';
import '../../../app/note_text.dart';
import '../../../core/music/note.dart';
import '../domain/tessitura.dart';

/// Etichetta dell'attendibilità nella lingua attiva.
String reliabilityLabel(AppLocalizations l10n, TessituraReliability reliability) =>
    switch (reliability) {
      TessituraReliability.insufficient => l10n.tessituraReliabilityInsufficient,
      TessituraReliability.low => l10n.tessituraReliabilityLow,
      TessituraReliability.medium => l10n.tessituraReliabilityMedium,
      TessituraReliability.high => l10n.tessituraReliabilityHigh,
    };

/// Riepilogo di un test di tessitura: zona comoda, estensione utilizzabile ed
/// estensione osservata su tre fasce separate (mai confuse in una sola),
/// attendibilità, note da verificare e confronto con il test precedente.
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
    final decor = context.decor;
    final l10n = context.l10n;
    final caption = theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant);
    final small = theme.textTheme.bodySmall;
    final muted = small?.copyWith(color: colors.onSurfaceVariant);
    // Test delle versioni precedenti: niente estensione utilizzabile.
    final legacy = record.invalidRatio == null && !record.hasUsable;

    final notes = [
      if (record.rangeLow != null) record.rangeLow!,
      if (record.rangeHigh != null) record.rangeHigh!,
      if (record.usableLow != null) record.usableLow!,
      if (record.usableHigh != null) record.usableHigh!,
      if (record.comfortLow != null) record.comfortLow!,
      if (record.comfortHigh != null) record.comfortHigh!,
      ...record.toVerify,
    ];
    final from = math.min(36, (notes.isEmpty ? 48 : notes.reduce(math.min)) - 2);
    final to = math.max(84, (notes.isEmpty ? 72 : notes.reduce(math.max)) + 2);

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
                  : Text(l10n.tessituraNoZone,
                      key: const ValueKey('tessitura-zone'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(
                  key: const ValueKey('tessitura-reliability'),
                  icon: Icons.verified_outlined,
                  label: l10n.tessituraReliability(reliabilityLabel(l10n, record.reliability)),
                  warning: record.reliability == TessituraReliability.insufficient,
                ),
                if (record.provisional && record.hasZone)
                  _Chip(
                    key: const ValueKey('tessitura-provisional'),
                    icon: Icons.hourglass_bottom_rounded,
                    label: l10n.tessituraProvisional,
                    warning: true,
                  ),
              ],
            ),
            if (!record.hasZone) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(l10n.tessituraInsufficientHint,
                    key: const ValueKey('tessitura-insufficient'), style: small),
              ),
            ],
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BandRow(
                    key: const ValueKey('tessitura-band-comfort'),
                    label: l10n.tessituraComfortZone,
                    low: record.comfortLow,
                    high: record.comfortHigh,
                    from: from,
                    to: to,
                    notation: notation,
                    gradient: decor.spectrum,
                    height: 12,
                    dots: record.toVerify,
                  ),
                  if (!legacy)
                    _BandRow(
                      key: const ValueKey('tessitura-band-usable'),
                      label: l10n.tessituraUsable,
                      low: record.usableLow,
                      high: record.usableHigh,
                      from: from,
                      to: to,
                      notation: notation,
                      color: colors.primary.withValues(alpha: 0.55),
                      height: 9,
                    ),
                  _BandRow(
                    key: const ValueKey('tessitura-band-observed'),
                    label: l10n.tessituraObserved,
                    low: record.rangeLow,
                    high: record.rangeHigh,
                    from: from,
                    to: to,
                    notation: notation,
                    color: colors.outline.withValues(alpha: 0.7),
                    height: 7,
                  ),
                  if (record.rangeLow != null && record.rangeHigh != null && !legacy)
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '${l10n.tessituraLowestObserved}: '),
                        noteSpan(spelledMidi(record.rangeLow!), notation,
                            style: small ?? const TextStyle()),
                        TextSpan(text: ' · ${l10n.tessituraHighestObserved}: '),
                        noteSpan(spelledMidi(record.rangeHigh!), notation,
                            style: small ?? const TextStyle()),
                      ]),
                      style: small,
                    ),
                  if (record.toVerify.isNotEmpty)
                    _NoteList(
                        label: l10n.tessituraToVerify, notes: record.toVerify, notation: notation),
                  if (record.registerNotes.isNotEmpty)
                    _NoteList(
                      key: const ValueKey('tessitura-register'),
                      label: l10n.tessituraRegisterNotes,
                      notes: record.registerNotes,
                      notation: notation,
                    ),
                  if (record.signalIssues)
                    Text(l10n.tessituraSignalIssues,
                        key: const ValueKey('tessitura-signal'), style: muted),
                  if (_comparison(l10n) case final text?) ...[
                    const SizedBox(height: 4),
                    Text(text, key: const ValueKey('tessitura-compare'), style: muted),
                  ],
                  const SizedBox(height: 4),
                  Text(l10n.tessituraEstimateDisclaimer, style: muted),
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

class _NoteList extends StatelessWidget {
  const _NoteList({required this.label, required this.notes, required this.notation, super.key});

  final String label;
  final List<int> notes;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '$label: '),
        for (final (index, midi) in notes.indexed) ...[
          if (index > 0) const TextSpan(text: ', '),
          noteSpan(spelledMidi(midi), notation, style: style ?? const TextStyle()),
        ],
      ]),
      style: style,
    );
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
          Flexible(child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color))),
        ],
      ),
    );
  }
}

/// Una fascia su una scala comune alle altre: etichetta, note estreme e
/// tratto colorato (o "—" se il dato manca). Punti: note da verificare.
class _BandRow extends StatelessWidget {
  const _BandRow({
    required this.label,
    required this.low,
    required this.high,
    required this.from,
    required this.to,
    required this.notation,
    required this.height,
    this.color,
    this.gradient,
    this.dots = const [],
    super.key,
  });

  final String label;
  final int? low;
  final int? high;
  final int from;
  final int to;
  final NoteNotation notation;
  final double height;
  final Color? color;
  final Gradient? gradient;
  final List<int> dots;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelStyle = theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant);
    final valueStyle = theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    double at(int midi) => ((midi - from) / (to - from)).clamp(0.0, 1.0);
    final has = low != null && high != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: labelStyle)),
              if (has)
                NoteRangeText(
                  low: spelledMidi(low!),
                  high: spelledMidi(high!),
                  notation: notation,
                  style: valueStyle,
                )
              else
                Text('—', style: valueStyle),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 5,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (has)
                      Positioned(
                        left: width * at(low!),
                        width: math.max(6, width * (at(high!) - at(low!))),
                        top: (14 - height) / 2,
                        height: height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(height / 2),
                          ),
                        ),
                      ),
                    for (final midi in dots)
                      Positioned(
                        left: width * at(midi) - 4,
                        top: 3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.tertiary,
                            border: Border.all(color: colors.surface, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
