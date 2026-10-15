import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/note_text.dart';
import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../../core/session/range_record.dart';
import '../../mascot/domain/mascot_mood.dart';
import '../../mascot/presentation/mascot_coach.dart';
import '../../settings/application/settings_providers.dart';
import '../../trainer/presentation/widgets/pitch_feedback_panel.dart';
import '../application/range_test_controller.dart';
import 'range_result_screen.dart';

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
      appBar: AppBar(title: const Text('Test estensione vocale')),
      body: SafeArea(
        child: switch (state.phase) {
          RangePhase.setup => _SetupView(state: state, controller: controller, notation: notation),
          RangePhase.findingStart =>
            _FindingStartView(state: state, controller: controller, notation: notation),
          RangePhase.descending ||
          RangePhase.ascending =>
            _TestingView(state: state, controller: controller, notation: notation),
          RangePhase.done => _ResultView(state: state, controller: controller, notation: notation),
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _RangeCoach(state: state),
        const SizedBox(height: 16),
        Text('Come funziona',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Premi "Inizia" e canta una nota comoda, tenendola per un momento: '
          'la riconosco e da lì scendiamo un semitono alla volta. Si avanza '
          'solo quando becchi la nota; quando proprio non ci arrivi, premi '
          '"Limite raggiunto" (o salta la singola nota). Poi si sale verso '
          'l\'acuto allo stesso modo. Alla fine l\'estensione viene salvata nel profilo.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Text('Sensibilità', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: state.toleranceCents,
                decoration: const InputDecoration(
                  labelText: 'Tolleranza',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 20, child: Text('± 20 cent')),
                  DropdownMenuItem(value: 30, child: Text('± 30 cent')),
                  DropdownMenuItem(value: 40, child: Text('± 40 cent')),
                  DropdownMenuItem(value: 50, child: Text('± 50 cent')),
                ],
                onChanged: (value) => value == null ? null : controller.setTolerance(value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: state.stabilityMs,
                decoration: const InputDecoration(
                  labelText: 'Durata stabilità',
                  border: OutlineInputBorder(),
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
            prefix: 'Ultimo test: ',
            suffix: ' (${formatSpan(state.previousRecord!.spanSemitones)})',
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
          label: const Text('Inizia il test'),
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
                    descending ? 'Verso il grave' : 'Verso l\'acuto',
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
                        Text('Canta questa nota (tocca per risentirla)',
                            style: theme.textTheme.labelLarge),
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
                  prefix: 'Range convalidato finora: ',
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
                          child: const Text('Salta questa nota'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: controller.endPhase,
                          child: Text(
                              descending ? 'Limite grave raggiunto' : 'Limite acuto raggiunto'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.cancel,
                    child: const Text('Annulla il test'),
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
                      Text('Canta una nota comoda e tienila', style: theme.textTheme.labelLarge),
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
                              : Text('In ascolto…',
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
                        'Quando la barra è piena, quella è la tua nota di partenza.',
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
              child: const Text('Annulla il test'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state, required this.controller, required this.notation});

  final RangeTestState state;
  final RangeTestController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowest = state.lowestMidi;
    final highest = state.highestMidi;
    final previous = state.previousRecord;

    String? progressText;
    if (lowest != null && highest != null && previous != null) {
      final delta = (highest - lowest) - previous.spanSemitones;
      progressText = delta > 0
          ? '+$delta semitoni rispetto all\'ultimo test 🎉'
          : delta == 0
              ? 'Stessa ampiezza dell\'ultimo test'
              : '$delta semitoni rispetto all\'ultimo test';
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
                Text('La tua estensione',
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
                    '${formatSpan(highest - lowest)} (${highest - lowest} semitoni)',
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
          lowest != null
              ? 'Risultato salvato nel profilo: lo storico dei test ti mostra i progressi nel tempo.'
              : '',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: controller.start,
          icon: const Icon(Icons.refresh),
          label: const Text('Riprova il test'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Chiudi'),
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
      _flash(MascotMood.success, 'Bravo! Prossima nota.');
    } else if (now.skippedCount > before.skippedCount) {
      _flash(MascotMood.retry, 'Nessun problema, proviamo la prossima.');
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
    final (mood, message) = switch (state.phase) {
      RangePhase.setup => (
          MascotMood.idle,
          'Parti da una nota comoda: scendiamo insieme verso il grave.',
        ),
      RangePhase.findingStart => (
          MascotMood.listening,
          'Canta una nota comoda e tienila: la riconosco io.',
        ),
      RangePhase.descending => (MascotMood.listening, 'Canta la nota: andiamo verso il grave.'),
      RangePhase.ascending => (MascotMood.listening, 'Ora saliamo verso l\'acuto!'),
      RangePhase.done => state.lowestMidi != null
          ? (MascotMood.success, 'Ecco la tua estensione! Ottimo lavoro.')
          : (MascotMood.retry, 'Riproviamo partendo da una nota più comoda.'),
    };
    return MascotCoach(
      mood: mood,
      reaction: _reaction,
      message: _flashMessage ?? message,
    );
  }
}
