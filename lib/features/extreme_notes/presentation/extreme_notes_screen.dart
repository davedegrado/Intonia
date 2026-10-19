import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n.dart';
import '../../../app/note_text.dart';
import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_coach.dart';
import '../../range/presentation/range_screen.dart';
import '../../settings/application/settings_providers.dart';
import '../application/extreme_notes_controller.dart';
import '../domain/extreme_notes.dart';

/// "Trova le note estreme" a schermo intero: spiegazione, ascolto del canto
/// libero con il pulsante per terminare sempre visibile, risultato.
class ExtremeNotesScreen extends ConsumerStatefulWidget {
  const ExtremeNotesScreen({super.key});

  @override
  ConsumerState<ExtremeNotesScreen> createState() => _ExtremeNotesScreenState();
}

class _ExtremeNotesScreenState extends ConsumerState<ExtremeNotesScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // In background il microfono si rilascia: la sessione si chiude con
    // quello che è stato sentito.
    if (lifecycle == AppLifecycleState.hidden || lifecycle == AppLifecycleState.paused) {
      ref.read(extremeNotesControllerProvider.notifier).stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(extremeNotesControllerProvider);
    final controller = ref.read(extremeNotesControllerProvider.notifier);
    final notation = ref.watch(notationProvider);

    // Provider autoDispose: uscendo si ferma il microfono.
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.extremeTitle)),
      body: SafeArea(
        child: switch (state.phase) {
          ExtremeNotesPhase.intro => _IntroView(state: state, controller: controller),
          ExtremeNotesPhase.listening =>
            _ListeningView(state: state, controller: controller, notation: notation),
          ExtremeNotesPhase.done =>
            _ResultView(state: state, controller: controller, notation: notation),
        },
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({required this.state, required this.controller});

  final ExtremeNotesState state;
  final ExtremeNotesController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final message = switch (state.message) {
      ExtremeNotesMessage.microphoneDenied => l10n.rangeMicDenied,
      ExtremeNotesMessage.audioUnavailable => l10n.rangeAudioInitFailed,
      ExtremeNotesMessage.interrupted => l10n.extremeInterrupted,
      null => null,
    };
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MascotCoach(mood: MascotMood.greeting, message: l10n.extremeSectionIntro),
        const SizedBox(height: 16),
        Text(l10n.extremeIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(l10n.extremeDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message,
              key: const ValueKey('extreme-message'),
              style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const ValueKey('extreme-start'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: controller.start,
          icon: const Icon(Icons.mic),
          label: Text(l10n.extremeStart),
        ),
      ],
    );
  }
}

class _ListeningView extends StatelessWidget {
  const _ListeningView({required this.state, required this.controller, required this.notation});

  final ExtremeNotesState state;
  final ExtremeNotesController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final detected = state.detected;
    final seconds = state.elapsed.inSeconds;
    final clock = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    Widget extreme(String label, int? midi, Key key) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                children: [
                  Text(label, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6),
                  midi == null
                      ? Text('—', key: key, style: theme.textTheme.headlineSmall)
                      : NoteText(
                          spelledMidi(midi),
                          key: key,
                          notation: notation,
                          style:
                              theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                ],
              ),
            ),
          ),
        );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              MascotCoach(mood: MascotMood.listening, message: l10n.extremeListening),
              const SizedBox(height: 16),
              // Riscontro essenziale: la nota che si sta cantando, piccola.
              Center(
                child: SizedBox(
                  height: 56,
                  child: Center(
                    child: detected == null
                        ? Text(clock, style: theme.textTheme.titleLarge)
                        : NoteText(
                            NoteSpeller.spellRoot(detected.note),
                            key: const ValueKey('extreme-current'),
                            notation: notation,
                            style: theme.textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.w800, color: colors.primary),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  extreme(
                      l10n.extremeLowestSoFar, state.lowest, const ValueKey('extreme-live-low')),
                  const SizedBox(width: 10),
                  extreme(
                      l10n.extremeHighestSoFar, state.highest, const ValueKey('extreme-live-high')),
                ],
              ),
            ],
          ),
        ),
        // Sempre visibile durante la sessione.
        Material(
          elevation: 8,
          color: colors.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: FilledButton.icon(
              key: const ValueKey('extreme-stop'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: controller.stop,
              icon: const Icon(Icons.stop),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l10n.extremeStop, maxLines: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state, required this.controller, required this.notation});

  final ExtremeNotesState state;
  final ExtremeNotesController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final result = state.result ?? ExtremeNotesResult.empty;
    final caption = theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant);
    final noteStyle = theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);
    final quality = switch (result.quality) {
      DetectionQuality.good => l10n.extremeQualityGood,
      DetectionQuality.fair => l10n.extremeQualityFair,
      DetectionQuality.poor => l10n.extremeQualityPoor,
    };
    Widget note(String label, int midi, bool certain, Key key) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: caption),
            NoteText(spelledMidi(midi), key: key, notation: notation, style: noteStyle),
            if (!certain)
              Text(l10n.extremeUncertain,
                  key: ValueKey('${(key as ValueKey<String>).value}-uncertain'),
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.tertiary)),
          ],
        );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (state.message == ExtremeNotesMessage.interrupted) ...[
          Text(l10n.extremeInterrupted, style: TextStyle(color: colors.error)),
          const SizedBox(height: 12),
        ],
        Card(
          key: const ValueKey('extreme-result'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: result.isEmpty
                ? Text(l10n.extremeNone,
                    key: const ValueKey('extreme-none'), style: theme.textTheme.bodyLarge)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (result.single) ...[
                        note(l10n.extremeLowest, result.lowest!, result.lowestCertain,
                            const ValueKey('extreme-single')),
                        const SizedBox(height: 8),
                        Text(l10n.extremeSingle, style: theme.textTheme.bodyMedium),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: note(l10n.extremeLowest, result.lowest!, result.lowestCertain,
                                  const ValueKey('extreme-low')),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topRight,
                                child: note(l10n.extremeHighest, result.highest!,
                                    result.highestCertain, const ValueKey('extreme-high')),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.rangeSpanDetail(
                              l10n.span(result.spanSemitones!), result.spanSemitones!),
                          key: const ValueKey('extreme-span'),
                          style:
                              theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),
                        RangeBar(low: result.lowest!, high: result.highest!),
                      ],
                      if (!result.lowestCertain || !result.highestCertain) ...[
                        const SizedBox(height: 10),
                        Text(l10n.extremeUncertainHint, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(l10n.extremeQuality(quality),
            key: const ValueKey('extreme-quality'), style: theme.textTheme.labelLarge),
        if (result.quality != DetectionQuality.good)
          Text(l10n.extremeQualityHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(l10n.extremeDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('extreme-again'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: controller.start,
          icon: const Icon(Icons.replay),
          label: Text(l10n.extremeAgain),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('extreme-back'),
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.extremeBack),
        ),
      ],
    );
  }
}
