import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n.dart';
import '../../app/main_shell.dart';
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
  trainerMode,
  trainerAdvanced,
  trainerHelp,
  trainerBack,
  firstExercise,
  profileSettings,
  navHome,
  navExercises,
  navRange,
  navProfile,
}

/// Voce della barra di navigazione di una sezione principale.
GuideTarget navTarget(String path) => switch (path) {
      '/exercises' => GuideTarget.navExercises,
      '/range' => GuideTarget.navRange,
      '/profile' => GuideTarget.navProfile,
      _ => GuideTarget.navHome,
    };

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
///
/// Un passaggio "da toccare" ([awaitRoute] o [awaitTarget]) non ha Avanti:
/// è l'utente a toccare l'elemento evidenziato (es. una voce della barra di
/// navigazione) e la guida prosegue da sola quando arriva dove deve.
class GuideStep {
  const GuideStep({
    required this.icon,
    required this.title,
    required this.text,
    this.target,
    this.section,
    this.awaitRoute,
    this.awaitTarget,
    this.optional = false,
  });

  final IconData icon;
  final String title;
  final String text;

  /// Elemento da evidenziare; null = spiegazione senza evidenziazione.
  final GuideTarget? target;

  /// Percorso della sezione in cui si trova (es. '/range'); null = la
  /// schermata attuale.
  final String? section;

  /// La guida prosegue quando l'utente arriva a questo percorso.
  final String? awaitRoute;

  /// La guida prosegue quando questo elemento compare (es. gli esercizi di
  /// una categoria appena aperta).
  final GuideTarget? awaitTarget;

  /// Se l'elemento non c'è (es. un controllo che quell'esercizio non ha) il
  /// passaggio si salta invece di spiegarlo al centro.
  final bool optional;

  bool get interactive => awaitRoute != null || awaitTarget != null;

  /// Saltato quando l'elemento manca: opzionale o da toccare.
  bool get skipIfMissing => optional || interactive;
}

/// Sezioni in cui la guida sa portare da sola; nelle altre (es. un
/// esercizio aperto) ci arriva solo l'utente.
const guideReachableSections = {'/', '/exercises', '/range', '/profile', '/settings'};

/// Guida completa: Intonia accompagna nelle sezioni dell'app ed evidenzia
/// gli elementi di cui parla. Per cambiare sezione è l'utente a toccare la
/// barra in basso (o la freccia, l'ingranaggio, l'esercizio), così impara
/// dove si trovano le cose.
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
      _navStep(l10n, from: '/', to: '/exercises', icon: Icons.music_note_outlined),
      GuideStep(
        icon: Icons.edit_note,
        title: l10n.exercisesCreateTitle,
        text: l10n.guideCustomText,
        target: GuideTarget.customSequences,
        section: '/exercises',
      ),
      GuideStep(
        icon: Icons.music_note_outlined,
        title: l10n.exercisesCategories,
        text: l10n.guideCategoriesText,
        target: GuideTarget.exerciseCategories,
        section: '/exercises',
      ),
      GuideStep(
        icon: Icons.touch_app_outlined,
        title: l10n.guideOpenCategoryTitle,
        text: l10n.guideOpenCategoryText,
        target: GuideTarget.exerciseCategories,
        section: '/exercises',
        awaitTarget: GuideTarget.firstExercise,
      ),
      GuideStep(
        icon: Icons.touch_app_outlined,
        title: l10n.guideOpenExerciseTitle,
        text: l10n.guideOpenExerciseText,
        target: GuideTarget.firstExercise,
        section: '/exercises',
        awaitRoute: '/trainer',
      ),
      ...exerciseGuideSteps(l10n, section: '/trainer'),
      GuideStep(
        icon: Icons.help_outline,
        title: l10n.guideHelpTitle,
        text: l10n.guideHelpText,
        target: GuideTarget.trainerHelp,
        section: '/trainer',
      ),
      GuideStep(
        icon: Icons.arrow_back,
        title: l10n.guideBackTitle,
        text: l10n.guideBackText,
        target: GuideTarget.trainerBack,
        section: '/trainer',
        awaitRoute: '/exercises',
      ),
      _navStep(l10n, from: '/exercises', to: '/range', icon: Icons.bar_chart_outlined),
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
      _navStep(l10n, from: '/range', to: '/profile', icon: Icons.person_outline),
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
        icon: Icons.settings_outlined,
        title: l10n.guideOpenSettingsTitle,
        text: l10n.guideOpenSettingsText,
        target: GuideTarget.profileSettings,
        section: '/profile',
        awaitRoute: '/settings',
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

/// "Tocca «Esercizi» nella barra in basso": la guida aspetta il tocco.
GuideStep _navStep(
  AppLocalizations l10n, {
  required String from,
  required String to,
  required IconData icon,
}) {
  final name = destinationLabel(l10n, to);
  return GuideStep(
    icon: icon,
    title: l10n.guideNavTitle(name),
    text: l10n.guideNavText(name),
    target: navTarget(to),
    section: from,
    awaitRoute: to,
  );
}

/// Guida della schermata dell'esercizio: solo i controlli presenti
/// (tonalità e ottava mancano nelle sequenze con nota fissa, il vertice
/// solo in Completo). [section] è il percorso dell'esercizio quando questi
/// passaggi fanno parte della guida completa: lì l'esercizio lo sceglie
/// l'utente e i controlli assenti si saltano.
List<GuideStep> exerciseGuideSteps(
  AppLocalizations l10n, {
  bool hasKeyAndOctave = true,
  bool hasRepeatTop = true,
  String? section,
}) =>
    [
      if (hasKeyAndOctave) ...[
        GuideStep(
          icon: Icons.piano,
          title: l10n.trainerKey,
          text: l10n.guideKey,
          target: GuideTarget.trainerKey,
          section: section,
          optional: true,
        ),
        GuideStep(
          icon: Icons.height,
          title: l10n.trainerOctave,
          text: l10n.guideOctave,
          target: GuideTarget.trainerOctave,
          section: section,
          optional: true,
        ),
      ],
      GuideStep(
        icon: Icons.swap_horiz,
        title: l10n.guideDirectionTitle,
        text: l10n.guideDirection,
        target: GuideTarget.trainerDirection,
        section: section,
      ),
      if (hasRepeatTop)
        GuideStep(
          icon: Icons.repeat_one,
          title: l10n.trainerRepeatTop,
          text: l10n.guideRepeatTop,
          target: GuideTarget.trainerRepeatTop,
          section: section,
          optional: true,
        ),
      GuideStep(
        icon: Icons.mic,
        title: l10n.guideModeTitle,
        text: l10n.guideModeText,
        target: GuideTarget.trainerMode,
        section: section,
      ),
      GuideStep(
        icon: Icons.tune,
        title: l10n.trainerAdvancedSettings,
        text: l10n.guideAdvancedText,
        target: GuideTarget.trainerAdvanced,
        section: section,
      ),
    ];

/// Avvia la guida con Intonia sopra l'app. Torna quando l'utente la chiude,
/// la salta o arriva in fondo.
Future<void> showGuide(BuildContext context, List<GuideStep> steps) {
  return ProviderScope.containerOf(context, listen: false)
      .read(guideTourProvider.notifier)
      .start(steps);
}
