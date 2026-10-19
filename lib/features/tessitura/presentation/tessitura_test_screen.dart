import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n.dart';
import '../../../app/note_text.dart';
import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_coach.dart';
import '../../settings/application/settings_providers.dart';
import '../../trainer/presentation/widgets/pitch_feedback_panel.dart';
import '../application/tessitura_test_controller.dart';
import '../domain/tessitura.dart';
import 'tessitura_map.dart';

/// Test di tessitura a schermo intero: introduzione, prove guidate con la
/// domanda sul comfort dopo ognuna, risultato.
class TessituraTestScreen extends ConsumerStatefulWidget {
  const TessituraTestScreen({super.key});

  @override
  ConsumerState<TessituraTestScreen> createState() => _TessituraTestScreenState();
}

class _TessituraTestScreenState extends ConsumerState<TessituraTestScreen>
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
    // In background microfono e piano vanno rilasciati: il test si annulla
    // senza salvare.
    if (lifecycle == AppLifecycleState.hidden || lifecycle == AppLifecycleState.paused) {
      final phase = ref.read(tessituraTestControllerProvider).phase;
      if (phase != TessituraPhase.intro && phase != TessituraPhase.done) {
        ref.read(tessituraTestControllerProvider.notifier).cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tessituraTestControllerProvider);
    final controller = ref.read(tessituraTestControllerProvider.notifier);
    final notation = ref.watch(notationProvider);

    // Provider autoDispose: uscendo si fermano microfono e piano.
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tessituraTitle)),
      body: SafeArea(
        child: switch (state.phase) {
          TessituraPhase.intro =>
            _IntroView(state: state, controller: controller, notation: notation),
          TessituraPhase.findingStart =>
            _FindingStartView(state: state, controller: controller, notation: notation),
          TessituraPhase.singing ||
          TessituraPhase.sustaining =>
            _SingingView(state: state, controller: controller, notation: notation),
          TessituraPhase.rating => _RatingView(state: state, controller: controller),
          TessituraPhase.done =>
            _DoneView(state: state, controller: controller, notation: notation),
        },
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({required this.state, required this.controller, required this.notation});

  final TessituraTestState state;
  final TessituraTestController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final message = switch (state.message) {
      TessituraMessage.microphoneDenied => l10n.rangeMicDenied,
      TessituraMessage.audioUnavailable => l10n.rangeAudioInitFailed,
      null => null,
    };
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MascotCoach(mood: MascotMood.greeting, message: l10n.tessituraCoachIntro),
        const SizedBox(height: 16),
        Text(l10n.rangeHowItWorks,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(l10n.tessituraHowItWorks, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          state.hasRange ? l10n.tessituraUsesRange : l10n.tessituraNoRange,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tessituraNotAClassification,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const ValueKey('tessitura-start'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: controller.start,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.tessituraStart),
        ),
        if (state.previous != null) ...[
          const SizedBox(height: 24),
          Text(l10n.tessituraLastResult, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TessituraResultCard(record: state.previous!, notation: notation),
        ],
      ],
    );
  }
}

class _FindingStartView extends StatelessWidget {
  const _FindingStartView({required this.state, required this.controller, required this.notation});

  final TessituraTestState state;
  final TessituraTestController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final detected = state.detected;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              MascotCoach(mood: MascotMood.listening, message: l10n.tessituraCoachFindStart),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(l10n.rangeSingComfortable, style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 64,
                        child: Center(
                          child: detected != null && detected.isStable
                              ? NoteText(
                                  NoteSpeller.spellRoot(detected.note),
                                  notation: notation,
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                )
                              : Text(l10n.rangeListening, style: theme.textTheme.titleMedium),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: state.startHoldProgress, minHeight: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: controller.cancel, child: Text(l10n.tessituraCancel)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SingingView extends StatelessWidget {
  const _SingingView({required this.state, required this.controller, required this.notation});

  final TessituraTestState state;
  final TessituraTestController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final sustaining = state.phase == TessituraPhase.sustaining;
    final root = state.rootMidi!;
    final target = state.targetMidi!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              MascotCoach(
                mood: MascotMood.listening,
                message: sustaining ? l10n.tessituraCoachSustain : l10n.tessituraCoachSing,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tessituraTrial(state.trialNumber),
                key: const ValueKey('tessitura-trial'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              // Il frammento della prova, con la nota corrente evidenziata.
              Row(
                children: [
                  for (final (index, step) in TessituraTrial.pattern.indexed)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: index == state.noteIndex
                              ? colors.primary
                              : index < state.noteIndex
                                  ? colors.primaryContainer
                                  : colors.surfaceContainerHighest,
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: NoteText(
                            spelledMidi(root + step),
                            notation: notation,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: index == state.noteIndex ? colors.onPrimary : colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: controller.replayNote,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(sustaining ? l10n.tessituraHoldNote : l10n.rangeSingThisNote,
                            style: theme.textTheme.labelLarge),
                        const SizedBox(height: 6),
                        NoteText(
                          spelledMidi(target),
                          key: const ValueKey('tessitura-target'),
                          notation: notation,
                          style:
                              theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (sustaining) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: state.sustainProgress, minHeight: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PitchFeedbackPanel(
                detection: state.detected,
                toleranceCents: 40,
                root: MusicalNote.fromMidi(target),
              ),
            ],
          ),
        ),
        Material(
          elevation: 8,
          color: colors.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('tessitura-skip'),
                    onPressed: controller.skipNote,
                    child: Text(l10n.rangeSkipNote),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    key: const ValueKey('tessitura-finish'),
                    onPressed: controller.finish,
                    child: Text(l10n.tessituraFinishNow),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingView extends StatelessWidget {
  const _RatingView({required this.state, required this.controller});

  final TessituraTestState state;
  final TessituraTestController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    Widget option(ComfortRating rating, IconData icon, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FilledButton.tonalIcon(
            key: ValueKey('tessitura-rate-${rating.name}'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              alignment: Alignment.centerLeft,
            ),
            onPressed: () => controller.rate(rating),
            icon: Icon(icon),
            label: Text(label),
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MascotCoach(mood: MascotMood.greeting, message: l10n.tessituraCoachRate),
        const SizedBox(height: 20),
        Text(
          l10n.tessituraRateQuestion,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        option(ComfortRating.easy, Icons.sentiment_very_satisfied_outlined, l10n.tessituraRateEasy),
        option(ComfortRating.effort, Icons.sentiment_neutral_outlined, l10n.tessituraRateEffort),
        option(ComfortRating.hard, Icons.sentiment_dissatisfied_outlined, l10n.tessituraRateHard),
        TextButton(
          key: const ValueKey('tessitura-rate-failed'),
          onPressed: () => controller.rate(null),
          child: Text(l10n.tessituraRateFailed),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: controller.finish, child: Text(l10n.tessituraFinishNow)),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.state, required this.controller, required this.notation});

  final TessituraTestState state;
  final TessituraTestController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = state.record!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MascotCoach(
          mood: record.provisional ? MascotMood.greeting : MascotMood.success,
          message: record.provisional ? l10n.tessituraCoachProvisional : l10n.tessituraCoachDone,
        ),
        const SizedBox(height: 16),
        TessituraResultCard(record: record, previous: state.previous, notation: notation),
        const SizedBox(height: 12),
        Text(
          l10n.tessituraLegend,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        FilledButton(
          key: const ValueKey('tessitura-done'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.sessionContinue),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: controller.start,
          icon: const Icon(Icons.replay),
          label: Text(l10n.tessituraRetake),
        ),
      ],
    );
  }
}
