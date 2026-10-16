import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n.dart';
import '../../../../core/music/note.dart';
import '../../../../core/music/note_spelling.dart';
import '../../../../core/pitch/pitch_detection_result.dart';
import '../../../settings/application/settings_providers.dart';

class PitchFeedbackPanel extends ConsumerWidget {
  const PitchFeedbackPanel({
    required this.detection,
    required this.toleranceCents,
    this.root,
    super.key,
  });

  final PitchDetectionResult? detection;
  final int toleranceCents;

  /// Tonica dell'esercizio, usata per lo spelling corretto (es. SIb vs LA#).
  final MusicalNote? root;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notation = ref.watch(notationProvider);
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final cents = detection?.cents ?? 0;
    final normalized = ((cents.clamp(-50, 50) + 50) / 100).toDouble();
    final hasPitch = detection != null && detection!.confidence > 0;
    final label = !hasPitch
        ? l10n.trainerListening
        : cents.abs() <= toleranceCents
            ? l10n.trainerInTune
            : cents < 0
                ? l10n.trainerTooLow
                : l10n.trainerTooHigh;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titolo e stato sulla stessa riga: il pannello resta basso.
            Row(
              children: [
                Expanded(
                  child: Text(l10n.trainerDetection,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.primary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: l10n.trainerDetectedNote,
                    value: !hasPitch
                        ? '-'
                        : root != null
                            ? NoteSpeller.spellNote(detection!.note, root: root!).label(notation)
                            : detection!.note.labelFor(notation),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: l10n.trainerDeviation,
                    value: hasPitch
                        ? l10n.trainerCentsValue(
                            '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(0)}')
                        : '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB84A62), Color(0xFF1F8A5B), Color(0xFFB84A62)],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment((normalized * 2) - 1, 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 4,
                      height: 26,
                      decoration: BoxDecoration(
                        color: colors.onSurface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
