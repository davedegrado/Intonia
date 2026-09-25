import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final cents = detection?.cents ?? 0;
    final normalized = ((cents.clamp(-50, 50) + 50) / 100).toDouble();
    final hasPitch = detection != null && detection!.confidence > 0;
    final label = !hasPitch
        ? 'In ascolto'
        : cents.abs() <= toleranceCents
            ? 'intonata'
            : cents < 0
                ? 'troppo bassa'
                : 'troppo alta';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riconoscimento', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Nota rilevata',
                    value: !hasPitch
                        ? '-'
                        : root != null
                            ? NoteSpeller.spellNote(detection!.note, root: root!).label(notation)
                            : detection!.note.labelFor(notation),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Scostamento',
                    value: hasPitch ? '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(0)} cent' : '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
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
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.onSurface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.primary)),
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
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
