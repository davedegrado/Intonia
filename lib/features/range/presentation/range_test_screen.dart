import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n.dart';
import '../../../app/note_text.dart';
import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_coach.dart';
import '../../settings/application/settings_providers.dart';
import '../../trainer/presentation/widgets/pitch_feedback_panel.dart';
import '../application/range_providers.dart';
import '../application/range_test_controller.dart';
import 'range_result_screen.dart';
import 'range_screen.dart' show confirmNotMine;

class RangeTestScreen extends ConsumerStatefulWidget {
  const RangeTestScreen({super.key});

  @override
  ConsumerState<RangeTestScreen> createState() => _RangeTestScreenState();
}

class _RangeTestScreenState extends ConsumerState<RangeTestScreen> with WidgetsBindingObserver {
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
    // App in background durante il test: microfono e piano vanno rilasciati.
    // Il test interrotto torna alla configurazione senza essere salvato.
    if (lifecycle == AppLifecycleState.hidden || lifecycle == AppLifecycleState.paused) {
      final phase = ref.read(rangeTestControllerProvider).phase;
      if (phase == RangePhase.findingStart ||
          phase == RangePhase.descending ||
          phase == RangePhase.ascending) {
        ref.read(rangeTestControllerProvider.notifier).cancel();
      }
    }
  }

  /// Riepilogo a schermo intero a fine test (solo se c'è un range salvato).
  Future<void> _showResult() async {
    final state = ref.read(rangeTestControllerProvider);
    final lowest = state.lowestMidi;
    final highest = state.highestMidi;
    if (lowest == null || highest == null) {
      return;
    }
    final action = await Navigator.of(context).push(RangeResultScreen.route(RangeResultScreen(
      lowestMidi: lowest,
      highestMidi: highest,
      startMidi: state.startMidi,
      notation: ref.read(notationProvider),
      previousSpan: state.previousRecord?.spanSemitones,
    )));
    if (action == RangeResultAction.retry && mounted) {
      await ref.read(rangeTestControllerProvider.notifier).start();
    }
    if (action == RangeResultAction.notMine && mounted) {
      await _discard();
    }
  }

  /// "Non ero io": dopo conferma toglie il test da risultati e storico.
  Future<void> _discard() async {
    final record = ref.read(rangeHistoryProvider).value?.lastOrNull;
    if (record == null || !await confirmNotMine(context, record) || !mounted) {
      return;
    }
    await ref.read(rangeTestControllerProvider.notifier).discardLastResult();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(rangeTestControllerProvider.select((state) => state.phase), (previous, next) {
      if (next == RangePhase.done && previous != RangePhase.done) {
        _showResult();
      }
    });
    final state = ref.watch(rangeTestControllerProvider);
    final controller = ref.read(rangeTestControllerProvider.notifier);
    final notation = ref.watch(notationProvider);

    // Il provider è autoDispose: uscendo dalla schermata microfono e audio
    // vengono fermati automaticamente in onDispose.
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.rangeTestTitle)),
      body: SafeArea(
        child: switch (state.phase) {
          RangePhase.setup => _SetupView(state: state, controller: controller, notation: notation),
          RangePhase.findingStart =>
            _FindingStartView(state: state, controller: controller, notation: notation),
          RangePhase.descending ||
          RangePhase.ascending =>
            _TestingView(state: state, controller: controller, notation: notation),
          RangePhase.done => _ResultView(
              state: state,
              controller: controller,
              notation: notation,
              onNotMine: _discard,
            ),
        },
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({required this.state, required this.controller, required this.notation});

  final RangeTestState state;
  final RangeTestController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _RangeCoach(state: state),
        const SizedBox(height: 16),
        Text(l10n.rangeHowItWorks,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          l10n.rangeHowItWorksBody,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Text(l10n.rangeSensitivity, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: state.toleranceCents,
                decoration: InputDecoration(
                  labelText: l10n.rangeTolerance,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final cents in const [20, 30, 40, 50])
                    DropdownMenuItem(value: cents, child: Text(l10n.rangeCents(cents))),
                ],
                onChanged: (value) => value == null ? null : controller.setTolerance(value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: state.stabilityMs,
                decoration: InputDecoration(
                  labelText: l10n.rangeStabilityTime,
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 100, child: Text('100 ms')),
                  DropdownMenuItem(value: 150, child: Text('150 ms')),
                  DropdownMenuItem(value: 200, child: Text('200 ms')),
                  DropdownMenuItem(value: 250, child: Text('250 ms')),
                ],
                onChanged: (value) => value == null ? null : controller.setStability(value),
              ),
            ),
          ],
        ),
        if (state.previousRecord != null) ...[
          const SizedBox(height: 16),
          NoteRangeText(
            low: spelledMidi(state.previousRecord!.minMidi),
            high: spelledMidi(state.previousRecord!.maxMidi),
            notation: notation,
            prefix: l10n.rangeLastTestPrefix,
            suffix: ' (${l10n.span(state.previousRecord!.spanSemitones)})',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (state.message != null) ...[
          const SizedBox(height: 12),
          Text(state.message!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: controller.start,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.rangeStartButton),
        ),
      ],
    );
  }
}

class _TestingView extends StatelessWidget {
  const _TestingView({required this.state, required this.controller, required this.notation});

  final RangeTestState state;
  final RangeTestController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final descending = state.phase == RangePhase.descending;
    final l10n = context.l10n;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _RangeCoach(state: state),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(descending ? Icons.south : Icons.north, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    descending ? l10n.rangeTowardLow : l10n.rangeTowardHigh,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: controller.replayTarget,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(l10n.rangeSingThisNote, style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        NoteText(
                          spelledMidi(state.targetMidi),
                          notation: notation,
                          style:
                              theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PitchFeedbackPanel(
                detection: state.detected,
                toleranceCents: state.toleranceCents,
                root: state.targetNote,
              ),
              const SizedBox(height: 12),
              if (state.lowestMidi != null && state.highestMidi != null)
                NoteRangeText(
                  low: spelledMidi(state.lowestMidi!),
                  high: spelledMidi(state.highestMidi!),
                  notation: notation,
                  prefix: l10n.rangeValidatedSoFar,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        Material(
          elevation: 8,
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.skipNote,
                          child: Text(l10n.rangeSkipNote),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: controller.endPhase,
                          child: Text(
                              descending ? l10n.rangeLowLimitReached : l10n.rangeHighLimitReached),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.cancel,
                    child: Text(l10n.rangeCancelTest),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FindingStartView extends StatelessWidget {
  const _FindingStartView({required this.state, required this.controller, required this.notation});

  final RangeTestState state;
  final RangeTestController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detected = state.detected;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _RangeCoach(state: state),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(context.l10n.rangeSingComfortable, style: theme.textTheme.labelLarge),
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
                              : Text(context.l10n.rangeListening,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          key: const ValueKey('start-hold-progress'),
                          value: state.startHoldProgress,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.rangeStartHoldHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton(
              onPressed: controller.cancel,
              child: Text(context.l10n.rangeCancelTest),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.state,
    required this.controller,
    required this.notation,
    required this.onNotMine,
  });

  final RangeTestState state;
  final RangeTestController controller;
  final NoteNotation notation;
  final VoidCallback onNotMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowest = state.lowestMidi;
    final highest = state.highestMidi;
    final previous = state.previousRecord;
    final l10n = context.l10n;

    String? progressText;
    if (lowest != null && highest != null && previous != null) {
      final delta = (highest - lowest) - previous.spanSemitones;
      progressText = delta > 0
          ? '${l10n.rangeProgressBetter(delta)} 🎉'
          : delta == 0
              ? l10n.rangeProgressSame
              : l10n.rangeProgressWorse(-delta);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _RangeCoach(state: state),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(l10n.rangeYourRange,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                const SizedBox(height: 8),
                if (lowest != null && highest != null)
                  NoteRangeText(
                    low: spelledMidi(lowest),
                    high: spelledMidi(highest),
                    notation: notation,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                else
                  Text('—',
                      style: theme.textTheme.displaySmall
                          ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                if (lowest != null && highest != null)
                  Text(
                    l10n.rangeSpanDetail(l10n.span(highest - lowest), highest - lowest),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (progressText != null)
          Text(progressText, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
        if (state.message != null)
          Text(state.message!,
              textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 20),
        Text(
          lowest != null ? l10n.rangeSavedToProfile : '',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: controller.start,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.rangeRetryTest),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: Text(l10n.commonClose),
        ),
        if (lowest != null)
          TextButton.icon(
            key: const ValueKey('range-view-not-mine'),
            onPressed: onNotMine,
            icon: const Icon(Icons.person_off_outlined),
            label: Text(l10n.rangeNotMineResult),
          ),
      ],
    );
  }
}

/// Mascotte del test di estensione: stato di base per fase e reazione breve a
/// ogni nota convalidata (festa) o saltata (incoraggiamento).
class _RangeCoach extends StatefulWidget {
  const _RangeCoach({required this.state});

  final RangeTestState state;

  @override
  State<_RangeCoach> createState() => _RangeCoachState();
}

class _RangeCoachState extends State<_RangeCoach> {
  static const _flashDuration = Duration(milliseconds: 1400);

  MascotReaction? _reaction;
  String? _flashMessage;
  Timer? _flashTimer;
  int _events = 0;

  @override
  void didUpdateWidget(_RangeCoach oldWidget) {
    super.didUpdateWidget(oldWidget);
    final now = widget.state;
    final before = oldWidget.state;
    if (now.validatedCount > before.validatedCount) {
      _flash(MascotMood.success, context.l10n.rangeCoachValidated);
    } else if (now.skippedCount > before.skippedCount) {
      _flash(MascotMood.retry, context.l10n.rangeCoachSkipped);
    }
  }

  void _flash(MascotMood mood, String message) {
    _events++;
    _reaction = MascotReaction(mood: mood, id: _events, duration: _flashDuration);
    _flashMessage = message;
    _flashTimer?.cancel();
    _flashTimer = Timer(_flashDuration, () {
      if (mounted) {
        setState(() => _flashMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = context.l10n;
    final (mood, message) = switch (state.phase) {
      RangePhase.setup => (MascotMood.idle, l10n.rangeCoachSetup),
      RangePhase.findingStart => (MascotMood.listening, l10n.rangeCoachFindingStart),
      RangePhase.descending => (MascotMood.listening, l10n.rangeCoachDescending),
      RangePhase.ascending => (MascotMood.listening, l10n.rangeCoachAscending),
      RangePhase.done => state.lowestMidi != null
          ? (MascotMood.success, l10n.rangeCoachDone)
          : (MascotMood.retry, l10n.rangeCoachRetry),
    };
    return MascotCoach(
      mood: mood,
      reaction: _reaction,
      message: _flashMessage ?? message,
    );
  }
}
