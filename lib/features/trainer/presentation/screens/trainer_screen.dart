import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/music/exercise.dart';
import '../../../../core/music/note.dart';
import '../../../../core/music/note_spelling.dart';
import '../../../settings/application/settings_providers.dart';
import '../../domain/trainer_state.dart';
import '../../domain/training_settings.dart';
import '../controllers/trainer_controller.dart';
import '../widgets/pitch_feedback_panel.dart';
import '../widgets/scale_sequence_view.dart';
import '../widgets/session_stats_panel.dart';

/// Trainer mobile-first: note sempre visibili in alto, controlli essenziali
/// fissi in basso, impostazioni avanzate in un bottom sheet.
class TrainerScreen extends ConsumerStatefulWidget {
  const TrainerScreen({required this.exercise, super.key});

  final ExerciseDefinition exercise;

  @override
  ConsumerState<TrainerScreen> createState() => _TrainerScreenState();
}

class _TrainerScreenState extends ConsumerState<TrainerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainerControllerProvider.notifier).selectExercise(widget.exercise);
    });
  }

  @override
  void deactivate() {
    ref.read(trainerControllerProvider.notifier).stop();
    super.deactivate();
  }

  void _openAdvancedSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _AdvancedSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerControllerProvider);
    final controller = ref.read(trainerControllerProvider.notifier);
    final notation = ref.watch(notationProvider);
    final theme = Theme.of(context);
    final spelled = NoteSpeller.spellSequence(state.sequence);
    final currentLabel = state.currentIndex < spelled.length
        ? spelled[state.currentIndex].fullLabel(notation)
        : state.currentNote.fullLabelFor(notation);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        actions: [
          IconButton(
            tooltip: 'Impostazioni avanzate',
            icon: const Icon(Icons.tune),
            onPressed: state.isPlaying ? null : _openAdvancedSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Nota corrente', style: theme.textTheme.labelLarge),
                                    Text(
                                      currentLabel,
                                      style: theme.textTheme.displaySmall
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusPill(isPlaying: state.isPlaying, isListening: state.isListening),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ScaleSequenceView(
                            sequence: state.sequence,
                            progress: state.progress,
                            currentIndex: state.currentIndex,
                            onTapCurrent: controller.listenCurrentNote,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.settings.mode == TrainerMode.train)
                    PitchFeedbackPanel(
                      detection: state.detectedPitch,
                      toleranceCents: state.settings.toleranceCents,
                      root: state.sequence.isNotEmpty ? state.sequence.first : null,
                    ),
                  if (state.message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        state.message!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: const Text('Statistiche sessione'),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    shape: const Border(),
                    children: [SessionStatsPanel(stats: state.sessionStats)],
                  ),
                ],
              ),
            ),
            _BottomControlBar(state: state, controller: controller, exercise: widget.exercise),
          ],
        ),
      ),
    );
  }
}

class _BottomControlBar extends ConsumerWidget {
  const _BottomControlBar({
    required this.state,
    required this.controller,
    required this.exercise,
  });

  final TrainerState state;
  final TrainerController controller;
  final ExerciseDefinition exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notation = ref.watch(notationProvider);
    final theme = Theme.of(context);
    // Le sequenze custom sono costruite su note assolute: niente selettori
    // di tonalità/ottava, si parte dalla nota con cui sono state create.
    final fixedRoot = exercise.isCustom && exercise.rootMidi != null
        ? NoteSpeller.spellRoot(MusicalNote.fromMidi(exercise.rootMidi!)).fullLabel(notation)
        : null;

    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fixedRoot != null)
              Row(
                children: [
                  Icon(Icons.push_pin_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Nota di partenza: $fixedRoot',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PitchClass>(
                      initialValue: state.settings.key,
                      decoration: const InputDecoration(
                        labelText: 'Tonalità',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final pitch in PitchClass.values)
                          DropdownMenuItem(
                            value: pitch,
                            child: Text(NoteSpeller.keyLabel(pitch, notation)),
                          ),
                      ],
                      onChanged: state.isPlaying
                          ? null
                          : (value) => value == null ? null : controller.updateKey(value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: state.settings.octave,
                      decoration: const InputDecoration(
                        labelText: 'Ottava',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text('2')),
                        DropdownMenuItem(value: 3, child: Text('3')),
                        DropdownMenuItem(value: 4, child: Text('4')),
                        DropdownMenuItem(value: 5, child: Text('5')),
                        DropdownMenuItem(value: 6, child: Text('6')),
                      ],
                      onChanged: state.isPlaying
                          ? null
                          : (value) => value == null ? null : controller.updateOctave(value),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                SegmentedButton<TrainerMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: TrainerMode.listen,
                      icon: Icon(Icons.headphones),
                      tooltip: 'Ascolto',
                    ),
                    ButtonSegment(
                      value: TrainerMode.train,
                      icon: Icon(Icons.mic),
                      tooltip: 'Allenamento',
                    ),
                  ],
                  selected: {state.settings.mode},
                  onSelectionChanged: state.isPlaying
                      ? null
                      : (selection) => controller.updateMode(selection.first),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: state.isPlaying
                      ? FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                          onPressed: controller.stop,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        )
                      : FilledButton.icon(
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          onPressed: controller.play,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
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

class _AdvancedSettingsSheet extends ConsumerStatefulWidget {
  const _AdvancedSettingsSheet();

  @override
  ConsumerState<_AdvancedSettingsSheet> createState() => _AdvancedSettingsSheetState();
}

class _AdvancedSettingsSheetState extends ConsumerState<_AdvancedSettingsSheet> {
  bool _calibrating = false;

  Future<void> _calibrate() async {
    setState(() => _calibrating = true);
    final threshold =
        await ref.read(trainerControllerProvider.notifier).calibrateNoise();
    if (!mounted) {
      return;
    }
    setState(() => _calibrating = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(threshold == null
          ? 'Calibrazione non riuscita: controlla il permesso microfono.'
          : 'Calibrazione completata: rumore di fondo filtrato.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerControllerProvider);
    final controller = ref.read(trainerControllerProvider.notifier);
    final theme = Theme.of(context);
    final disabled = state.isPlaying;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Impostazioni avanzate', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          _SliderRow(
            label: 'BPM',
            value: state.settings.bpm,
            min: 40,
            max: 140,
            divisions: 20,
            format: (value) => '$value',
            onChanged: disabled ? null : controller.updateBpm,
          ),
          _SliderRow(
            label: 'Tolleranza',
            value: state.settings.toleranceCents,
            min: 10,
            max: 40,
            divisions: 3,
            format: (value) => '± $value cent',
            onChanged: disabled ? null : controller.updateTolerance,
          ),
          _SliderRow(
            label: 'Durata stabilità',
            value: state.settings.stabilityMs,
            min: 100,
            max: 300,
            divisions: 4,
            format: (value) => '$value ms',
            onChanged: disabled ? null : controller.updateStability,
          ),
          SwitchListTile.adaptive(
            value: state.settings.guideEveryNote,
            onChanged: state.settings.mode == TrainerMode.train && !disabled
                ? controller.updateGuideEveryNote
                : null,
            title: const Text('Suona la guida su ogni nota'),
            subtitle: const Text('Se disattivo, senti solo la prima nota'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: state.settings.loop,
            onChanged: state.settings.mode == TrainerMode.listen && !disabled
                ? controller.updateLoop
                : null,
            title: const Text('Loop (solo modalità Ascolto)'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: controller.listenCurrentNote,
            icon: const Icon(Icons.volume_up),
            label: const Text('Ascolta nota corrente'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: disabled || _calibrating ? null : _calibrate,
            icon: _calibrating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.graphic_eq),
            label: Text(_calibrating
                ? 'Resta in silenzio… (3 s)'
                : 'Calibra rumore di fondo'),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  final String label;
  final int value;
  final double min;
  final double max;
  final int divisions;
  final String Function(int value) format;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${format(value)}', style: Theme.of(context).textTheme.labelLarge),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: format(value),
          onChanged: onChanged == null ? null : (next) => onChanged!(next.round()),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isPlaying, required this.isListening});

  final bool isPlaying;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = isListening
        ? 'Microfono attivo'
        : isPlaying
            ? 'Riproduzione'
            : 'Pronta';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPlaying ? colors.primaryContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}
