import 'package:flutter/material.dart';

import '../../app/l10n.dart';
import '../mascot/domain/mascot_mood.dart';
import '../mascot/presentation/intonia_mascot.dart';

/// Un passaggio della guida: icona della sezione, titolo e spiegazione.
class GuideStep {
  const GuideStep({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;
}

/// Guida completa di Intonia, una sezione per passaggio.
List<GuideStep> appGuideSteps(AppLocalizations l10n) => [
      GuideStep(icon: Icons.home_outlined, title: l10n.navHome, text: l10n.guideHome),
      GuideStep(
          icon: Icons.music_note_outlined, title: l10n.navExercises, text: l10n.guideExercises),
      GuideStep(
          icon: Icons.tune,
          title: l10n.guideExerciseSettingsTitle,
          text: l10n.guideExerciseSettings),
      GuideStep(icon: Icons.bar_chart_outlined, title: l10n.navRange, text: l10n.guideRange),
      GuideStep(icon: Icons.person_outline, title: l10n.navProfile, text: l10n.guideProfile),
      GuideStep(
          icon: Icons.settings_outlined, title: l10n.guideSettingsTitle, text: l10n.guideSettings),
    ];

/// Guida della schermata dell'esercizio: solo i controlli presenti.
List<GuideStep> exerciseGuideSteps(
  AppLocalizations l10n, {
  required bool hasKeyAndOctave,
  required bool hasRepeatTop,
}) =>
    [
      if (hasKeyAndOctave) ...[
        GuideStep(icon: Icons.piano, title: l10n.trainerKey, text: l10n.guideKey),
        GuideStep(icon: Icons.height, title: l10n.trainerOctave, text: l10n.guideOctave),
      ],
      GuideStep(icon: Icons.swap_horiz, title: l10n.guideDirectionTitle, text: l10n.guideDirection),
      if (hasRepeatTop)
        GuideStep(icon: Icons.repeat_one, title: l10n.trainerRepeatTop, text: l10n.guideRepeatTop),
    ];

/// Mostra la guida in un pannello con la mascotte. Torna quando l'utente la
/// chiude, la salta o arriva in fondo.
Future<void> showGuide(BuildContext context, List<GuideStep> steps) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => GuideSheet(steps: steps),
  );
}

class GuideSheet extends StatefulWidget {
  const GuideSheet({required this.steps, super.key});

  final List<GuideStep> steps;

  @override
  State<GuideSheet> createState() => _GuideSheetState();
}

class _GuideSheetState extends State<GuideSheet> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final step = widget.steps[_index];
    final last = _index == widget.steps.length - 1;
    void close() => Navigator.of(context).pop();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          key: const ValueKey('guide-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l10n.guideProgress(_index + 1, widget.steps.length),
                  style: theme.textTheme.labelMedium,
                ),
                const Spacer(),
                if (!last)
                  TextButton(
                    key: const ValueKey('guide-skip'),
                    onPressed: close,
                    child: Text(l10n.guideSkip),
                  ),
                IconButton(
                  key: const ValueKey('guide-close'),
                  tooltip: l10n.commonClose,
                  icon: const Icon(Icons.close),
                  onPressed: close,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntoniaMascot(
                  mood: _index == 0 ? MascotMood.greeting : MascotMood.idle,
                  size: 72,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(step.icon, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(step.title,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(step.text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_index > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('guide-back'),
                      onPressed: () => setState(() => _index--),
                      child: Text(l10n.commonBack),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('guide-next'),
                    onPressed: last ? close : () => setState(() => _index++),
                    child: Text(last ? l10n.guideDone : l10n.guideNext),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
