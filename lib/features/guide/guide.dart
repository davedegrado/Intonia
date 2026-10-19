import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n.dart';
import 'guide_tour.dart';

/// Elementi dell'interfaccia che la guida può evidenziare.
enum GuideTarget {
  homeMic,
  homeStatus,
  dailyWorkout,
  exerciseCategories,
  customSequences,
  rangeTest,
  tessitura,
  profileStats,
  profileAchievements,
  profileHistory,
  settingsLanguage,
  settingsTheme,
  settingsNotation,
  settingsGuide,
  trainerKey,
  trainerOctave,
  trainerDirection,
  trainerRepeatTop,
}

/// Segna un elemento come bersaglio della guida. Non cambia aspetto né
/// comportamento del figlio: registra solo dove si trova. Se lo stesso
/// bersaglio è montato due volte (es. durante una transizione) vale
/// l'ultimo, senza errori.
class GuideAnchor extends StatefulWidget {
  const GuideAnchor({required this.target, required this.child, super.key});

  final GuideTarget target;
  final Widget child;

  static final _registry = <GuideTarget, _GuideAnchorState>{};

  /// Contesto dell'elemento [target] se è montato, altrimenti null.
  static BuildContext? contextOf(GuideTarget target) {
    final anchor = _registry[target];
    return anchor != null && anchor.mounted ? anchor.context : null;
  }

  @override
  State<GuideAnchor> createState() => _GuideAnchorState();
}

class _GuideAnchorState extends State<GuideAnchor> {
  @override
  void initState() {
    super.initState();
    GuideAnchor._registry[widget.target] = this;
  }

  @override
  void didUpdateWidget(GuideAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _unregister(oldWidget.target);
      GuideAnchor._registry[widget.target] = this;
    }
  }

  @override
  void dispose() {
    _unregister(widget.target);
    super.dispose();
  }

  void _unregister(GuideTarget target) {
    if (GuideAnchor._registry[target] == this) {
      GuideAnchor._registry.remove(target);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Un passaggio della guida: cosa spiega Intonia, quale elemento evidenzia
/// e in quale sezione si trova.
class GuideStep {
  const GuideStep({
    required this.icon,
    required this.title,
    required this.text,
    this.target,
    this.section,
  });

  final IconData icon;
  final String title;
  final String text;

  /// Elemento da evidenziare; null = spiegazione senza evidenziazione.
  final GuideTarget? target;

  /// Percorso della sezione in cui si trova (es. '/range'); null = la
  /// schermata attuale.
  final String? section;
}

/// Guida completa: Intonia accompagna nelle sezioni dell'app ed evidenzia
/// gli elementi di cui parla.
List<GuideStep> appGuideSteps(AppLocalizations l10n) => [
      GuideStep(
        icon: Icons.mic_rounded,
        title: l10n.guideMicTitle,
        text: l10n.guideMicText,
        target: GuideTarget.homeMic,
        section: '/',
      ),
      GuideStep(
        icon: Icons.fitness_center_rounded,
        title: l10n.workoutTitle,
        text: l10n.guideWorkoutText,
        target: GuideTarget.dailyWorkout,
        section: '/',
      ),
      GuideStep(
        icon: Icons.local_fire_department_rounded,
        title: l10n.guideStatusTitle,
        text: l10n.guideStatusText,
        target: GuideTarget.homeStatus,
        section: '/',
      ),
      GuideStep(
        icon: Icons.music_note_outlined,
        title: l10n.exercisesCategories,
        text: l10n.guideCategoriesText,
        target: GuideTarget.exerciseCategories,
        section: '/exercises',
      ),
      GuideStep(
        icon: Icons.edit_note,
        title: l10n.exercisesCreateTitle,
        text: l10n.guideCustomText,
        target: GuideTarget.customSequences,
        section: '/exercises',
      ),
      GuideStep(
        icon: Icons.bar_chart_outlined,
        title: l10n.rangeTestTitle,
        text: l10n.guideRangeText,
        target: GuideTarget.rangeTest,
        section: '/range',
      ),
      GuideStep(
        icon: Icons.tune_rounded,
        title: l10n.tessituraSectionTitle,
        text: l10n.guideTessituraText,
        target: GuideTarget.tessitura,
        section: '/range',
      ),
      GuideStep(
        icon: Icons.insights,
        title: l10n.guideStatsTitle,
        text: l10n.guideStatsText,
        target: GuideTarget.profileStats,
        section: '/profile',
      ),
      GuideStep(
        icon: Icons.military_tech_rounded,
        title: l10n.achievementsTitle,
        text: l10n.guideAchievementsText,
        target: GuideTarget.profileAchievements,
        section: '/profile',
      ),
      GuideStep(
        icon: Icons.history,
        title: l10n.guideHistoryTitle,
        text: l10n.guideHistoryText,
        target: GuideTarget.profileHistory,
        section: '/profile',
      ),
      GuideStep(
        icon: Icons.language,
        title: l10n.languageSectionTitle,
        text: l10n.guideLanguageText,
        target: GuideTarget.settingsLanguage,
        section: '/settings',
      ),
      GuideStep(
        icon: Icons.palette_outlined,
        title: l10n.settingsAppearance,
        text: l10n.guideThemeText,
        target: GuideTarget.settingsTheme,
        section: '/settings',
      ),
      GuideStep(
        icon: Icons.music_note_outlined,
        title: l10n.settingsNotation,
        text: l10n.guideNotationText,
        target: GuideTarget.settingsNotation,
        section: '/settings',
      ),
      GuideStep(
        icon: Icons.school_outlined,
        title: l10n.guideTitle,
        text: l10n.guideReopenText,
        target: GuideTarget.settingsGuide,
        section: '/settings',
      ),
    ];

/// Guida della schermata dell'esercizio: solo i controlli presenti.
List<GuideStep> exerciseGuideSteps(
  AppLocalizations l10n, {
  required bool hasKeyAndOctave,
  required bool hasRepeatTop,
}) =>
    [
      if (hasKeyAndOctave) ...[
        GuideStep(
          icon: Icons.piano,
          title: l10n.trainerKey,
          text: l10n.guideKey,
          target: GuideTarget.trainerKey,
        ),
        GuideStep(
          icon: Icons.height,
          title: l10n.trainerOctave,
          text: l10n.guideOctave,
          target: GuideTarget.trainerOctave,
        ),
      ],
      GuideStep(
        icon: Icons.swap_horiz,
        title: l10n.guideDirectionTitle,
        text: l10n.guideDirection,
        target: GuideTarget.trainerDirection,
      ),
      if (hasRepeatTop)
        GuideStep(
          icon: Icons.repeat_one,
          title: l10n.trainerRepeatTop,
          text: l10n.guideRepeatTop,
          target: GuideTarget.trainerRepeatTop,
        ),
    ];

/// Avvia la guida con Intonia sopra l'app. Torna quando l'utente la chiude,
/// la salta o arriva in fondo.
Future<void> showGuide(BuildContext context, List<GuideStep> steps) {
  return ProviderScope.containerOf(context, listen: false)
      .read(guideTourProvider.notifier)
      .start(steps);
}
