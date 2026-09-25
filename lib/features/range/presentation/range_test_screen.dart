import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../../core/session/range_record.dart';
import '../../settings/application/settings_providers.dart';
import '../../trainer/presentation/widgets/pitch_feedback_panel.dart';
import '../application/range_test_controller.dart';

class RangeTestScreen extends ConsumerWidget {
  const RangeTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          RangePhase.descending ||
          RangePhase.ascending =>
            _TestingView(state: state, controller: controller, notation: notation),
          RangePhase.done => _ResultView(state: state, controller: controller, notation: notation),
        },
      ),
    );
  }
}

String _noteLabel(int midi, NoteNotation notation) {
  return NoteSpeller.spellRoot(MusicalNote.fromMidi(midi)).fullLabel(notation);
}

class _SetupView extends StatelessWidget {
  const _SetupView({required this.state, required this.controller, required this.notation});

  final RangeTestState state;
  final RangeTestController controller;
  final NoteNotation notation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = MusicalNote.fromMidi(state.startMidi);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Come funziona', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Parti da una nota comoda e scendi un semitono alla volta: si avanza '
          'solo quando becchi la nota. Quando proprio non ci arrivi, premi '
          '"Limite raggiunto" (o salta la singola nota). Poi si sale verso '
          'l\'acuto allo stesso modo. Alla fine l\'estensione viene salvata nel profilo.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Text('Nota di partenza (comoda)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<PitchClass>(
                initialValue: start.pitchClass,
                decoration: const InputDecoration(labelText: 'Nota', border: OutlineInputBorder()),
                items: [
                  for (final pitch in PitchClass.values)
                    DropdownMenuItem(value: pitch, child: Text(NoteSpeller.keyLabel(pitch, notation))),
                ],
                onChanged: (value) => value == null ? null : controller.setStartNote(key: value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: start.octave,
                decoration: const InputDecoration(labelText: 'Ottava', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                  DropdownMenuItem(value: 5, child: Text('5')),
                ],
                onChanged: (value) => value == null ? null : controller.setStartNote(octave: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Sensibilità', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
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
          Text(
            'Ultimo test: ${_noteLabel(state.previousRecord!.minMidi, notation)} – '
            '${_noteLabel(state.previousRecord!.maxMidi, notation)} '
            '(${formatSpan(state.previousRecord!.spanSemitones)})',
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
                        Text(
                          _noteLabel(state.targetMidi, notation),
                          style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
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
              Text(
                'Range convalidato finora: '
                '${state.lowestMidi != null ? _noteLabel(state.lowestMidi!, notation) : '—'}'
                ' – '
                '${state.highestMidi != null ? _noteLabel(state.highestMidi!, notation) : '—'}',
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
                          child: Text(descending ? 'Limite grave raggiunto' : 'Limite acuto raggiunto'),
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
                Text(
                  lowest != null && highest != null
                      ? '${_noteLabel(lowest, notation)} – ${_noteLabel(highest, notation)}'
                      : '—',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
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
          child: const Text('Torna alla libreria'),
        ),
      ],
    );
  }
}
