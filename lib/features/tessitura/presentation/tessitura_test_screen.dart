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

/// Test di tessitura a schermo intero: introduzione, prove guidate una nota
/// alla volta, sforzo percepito, risultato.
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
          TessituraPhase.attempt =>
            _AttemptView(state: state, controller: controller, notation: notation),
          TessituraPhase.rating => _RatingView(state: state, controller: controller),
          TessituraPhase.strainChoice => _StrainView(controller: controller),
          TessituraPhase.melodicOffer => _MelodicOfferView(controller: controller),
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
      TessituraMessage.cannotCalibrate => l10n.tessituraCannotCalibrate,
      TessituraMessage.interrupted => l10n.tessituraInterrupted,
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
          Text(message,
              key: const ValueKey('tessitura-message'),
              style: TextStyle(color: theme.colorScheme.error)),
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

String _stageLabel(AppLocalizations l10n, TessituraStage stage) => switch (stage) {
      TessituraStage.calibration => l10n.tessituraStageCalibration,
      TessituraStage.explore => l10n.tessituraStageExplore,
      TessituraStage.hold => l10n.tessituraStageHold,
      TessituraStage.repeat => l10n.tessituraStageRepeat,
      TessituraStage.melodic => l10n.tessituraStageMelodic,
    };

String _cueText(AppLocalizations l10n, TessituraCue cue) => switch (cue) {
      TessituraCue.calibrate => l10n.tessituraCueCalibrate,
      TessituraCue.recenter => l10n.tessituraCueRecenter,
      TessituraCue.notHeard => l10n.tessituraCueNotHeard,
      TessituraCue.retry => l10n.tessituraCueRetry,
      TessituraCue.stepUp => l10n.tessituraCueStepUp,
      TessituraCue.stepDown => l10n.tessituraCueStepDown,
      TessituraCue.backToComfort => l10n.tessituraCueBackToComfort,
      TessituraCue.hold => l10n.tessituraCueHold,
      TessituraCue.repeat => l10n.tessituraCueRepeat,
      TessituraCue.melodic => l10n.tessituraCueMelodic,
    };

class _AttemptView extends StatelessWidget {
  const _AttemptView({required this.state, required this.controller, required this.notation});

  final TessituraTestState state;
  final TessituraTestController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final step = state.step!;
    final target = step.midi;
    final singing = state.attemptStep == AttemptStep.singing;
    final instruction = switch (step.stage) {
      TessituraStage.hold => l10n.tessituraInstructionHold,
      TessituraStage.repeat => l10n.tessituraInstructionRepeat(step.repetition, step.repetitions),
      TessituraStage.melodic => l10n.tessituraInstructionMelodic(step.repetition, step.repetitions),
      _ => l10n.tessituraInstructionNote,
    };
    final status = switch (state.attemptStep) {
      AttemptStep.ready => l10n.tessituraGetReady,
      AttemptStep.guide => l10n.tessituraListen,
      AttemptStep.waiting => l10n.tessituraYourTurn,
      AttemptStep.singing => l10n.tessituraSinging,
    };

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Una sola indicazione alla volta: perché questa nota.
              MascotCoach(
                key: const ValueKey('tessitura-cue'),
                mood: singing ? MascotMood.listening : MascotMood.greeting,
                message: _cueText(l10n, step.cue),
              ),
              const SizedBox(height: 12),
              Text(
                _stageLabel(l10n, step.stage),
                key: const ValueKey('tessitura-stage'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: state.attemptStep == AttemptStep.waiting ? controller.replayNote : null,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(instruction,
                            textAlign: TextAlign.center, style: theme.textTheme.labelLarge),
                        const SizedBox(height: 6),
                        NoteText(
                          spelledMidi(target),
                          key: const ValueKey('tessitura-target'),
                          notation: notation,
                          style:
                              theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(status,
                            key: const ValueKey('tessitura-status'),
                            style: theme.textTheme.bodyMedium?.copyWith(color: colors.primary)),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: state.progress, minHeight: 8),
                        if (state.attemptStep == AttemptStep.waiting) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            key: const ValueKey('tessitura-replay'),
                            onPressed: controller.replayNote,
                            icon: const Icon(Icons.volume_up_outlined, size: 18),
                            label: Text(l10n.tessituraReplay),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PitchFeedbackPanel(
                detection: state.detected,
                toleranceCents: TessituraThresholds.standard.toleranceCents,
                root: MusicalNote.fromMidi(target),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  key: const ValueKey('tessitura-register'),
                  selected: state.registerShift,
                  onSelected: (_) => controller.toggleRegisterShift(),
                  avatar: const Icon(Icons.swap_vert, size: 18),
                  label: Text(l10n.tessituraRegisterShift),
                ),
              ),
            ],
          ),
        ),
        Material(
          elevation: 8,
          color: colors.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const ValueKey('tessitura-skip'),
                        onPressed: controller.skipNote,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(l10n.rangeSkipNote, maxLines: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: step.stage == TessituraStage.hold && singing
                          ? FilledButton.tonal(
                              key: const ValueKey('tessitura-end-note'),
                              onPressed: controller.endNote,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.tessituraEndNote, maxLines: 1),
                              ),
                            )
                          : OutlinedButton(
                              key: const ValueKey('tessitura-strain'),
                              style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                              onPressed: controller.reportStrain,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.tessituraStrain, maxLines: 1),
                              ),
                            ),
                    ),
                  ],
                ),
                if (step.stage == TessituraStage.hold && singing)
                  TextButton(
                    key: const ValueKey('tessitura-strain'),
                    style: TextButton.styleFrom(foregroundColor: colors.error),
                    onPressed: controller.reportStrain,
                    child: Text(l10n.tessituraStrain),
                  ),
                TextButton(
                  key: const ValueKey('tessitura-finish'),
                  onPressed: controller.finish,
                  child: Text(l10n.tessituraFinishNow),
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
    final labels = [
      l10n.tessituraEffort1,
      l10n.tessituraEffort2,
      l10n.tessituraEffort3,
      l10n.tessituraEffort4,
      l10n.tessituraEffort5,
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MascotCoach(mood: MascotMood.greeting, message: l10n.tessituraCoachRate),
        const SizedBox(height: 20),
        Text(
          l10n.tessituraEffortQuestion,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (final rating in EffortRating.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.tonal(
              key: ValueKey('tessitura-effort-${rating.value}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                alignment: Alignment.centerLeft,
              ),
              onPressed: () => controller.rate(rating),
              child: Text(labels[rating.value - 1]),
            ),
          ),
        TextButton(
          key: const ValueKey('tessitura-effort-skip'),
          onPressed: () => controller.rate(null),
          child: Text(l10n.tessituraEffortSkip),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: controller.finish, child: Text(l10n.tessituraFinishNow)),
      ],
    );
  }
}

class _StrainView extends StatelessWidget {
  const _StrainView({required this.controller});

  final TessituraTestController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MascotCoach(mood: MascotMood.greeting, message: l10n.tessituraStrainTitle),
        const SizedBox(height: 16),
        Text(l10n.tessituraStrainBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('tessitura-strain-continue'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: controller.continueAfterStrain,
          child: Text(l10n.tessituraStrainContinue),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('tessitura-strain-finish'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: controller.finish,
          child: Text(l10n.tessituraStrainFinish),
        ),
      ],
    );
  }
}

class _MelodicOfferView extends StatelessWidget {
  const _MelodicOfferView({required this.controller});

  final TessituraTestController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MascotCoach(mood: MascotMood.greeting, message: l10n.tessituraMelodicTitle),
        const SizedBox(height: 16),
        Text(l10n.tessituraMelodicBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('tessitura-melodic-yes'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => controller.chooseMelodic(true),
          child: Text(l10n.tessituraMelodicYes),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('tessitura-melodic-no'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => controller.chooseMelodic(false),
          child: Text(l10n.tessituraMelodicNo),
        ),
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
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final record = state.record;
    final insufficient = record == null || !record.hasZone;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MascotCoach(
          mood: insufficient || record.provisional ? MascotMood.greeting : MascotMood.success,
          message: insufficient
              ? l10n.tessituraInsufficientHint
              : record.provisional
                  ? l10n.tessituraCoachProvisional
                  : l10n.tessituraCoachDone,
        ),
        if (state.message == TessituraMessage.interrupted) ...[
          const SizedBox(height: 12),
          Text(l10n.tessituraInterrupted, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 16),
        if (record != null)
          TessituraResultCard(record: record, previous: state.previous, notation: notation)
        else
          Text(l10n.tessituraNoValidData,
              key: const ValueKey('tessitura-no-data'), style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        Text(l10n.tessituraLegend, style: theme.textTheme.bodySmall),
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
