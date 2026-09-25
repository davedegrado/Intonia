import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/music/exercise.dart';
import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../settings/application/settings_providers.dart';
import '../../trainer/presentation/controllers/trainer_controller.dart';
import '../application/exercise_providers.dart';

/// Editor a note assolute: scegli l'ottava e tocchi le note reali
/// (es. da RE3 a RE5, note ripetute, anche discendenti). La sequenza resta
/// trasponibile: viene salvata come offset dalla prima nota.
class CustomExerciseEditorScreen extends ConsumerStatefulWidget {
  const CustomExerciseEditorScreen({this.initial, super.key});

  final ExerciseDefinition? initial;

  @override
  ConsumerState<CustomExerciseEditorScreen> createState() => _CustomExerciseEditorScreenState();
}

class _CustomExerciseEditorScreenState extends ConsumerState<CustomExerciseEditorScreen> {
  static const _defaultRootMidi = 60; // DO4

  static const focusOptions = ['Precisione', 'Controllo', 'Estensione', 'Agilità', 'Orecchio'];

  late final TextEditingController _nameController;
  late final TextEditingController _groupController;
  late final List<int> _midis;
  String? _focus;
  int _pickerOctave = 4;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _groupController = TextEditingController(text: widget.initial?.group ?? '');
    _focus = widget.initial?.focus;
    final root = widget.initial?.rootMidi ?? _defaultRootMidi;
    _midis = [
      for (final step in widget.initial?.steps ?? const <int>[0]) root + step,
    ];
    if (_midis.isNotEmpty) {
      _pickerOctave = MusicalNote.fromMidi(_midis.last).octave.clamp(2, 6).toInt();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    if (_midis.isEmpty || _previewing) {
      return;
    }
    setState(() => _previewing = true);
    final audio = ref.read(pianoAudioServiceProvider);
    try {
      await audio.playSequence(
        notes: _midis.map(MusicalNote.fromMidi).toList(),
        bpm: 100,
        loop: false,
        onNote: (_) {},
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio non disponibile: verifica il SoundFont piano.sf2.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _previewing = false);
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Dai un nome alla sequenza.')));
      return;
    }
    if (_midis.length < 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Aggiungi almeno 2 note.')));
      return;
    }

    final root = _midis.first;
    final group = _groupController.text.trim();
    final exercise = ExerciseDefinition(
      id: widget.initial?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: ExerciseCategory.custom,
      steps: [for (final midi in _midis) midi - root],
      isCustom: true,
      rootMidi: root,
      focus: _focus,
      group: group.isEmpty ? null : group,
    );
    await ref.read(customExercisesProvider.notifier).upsert(exercise);
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notation = ref.watch(notationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Nuova sequenza' : 'Modifica sequenza'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Salva'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Es. Estensione sui DO / Vocalizzo 1-3-5-8',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groupController,
              decoration: const InputDecoration(
                labelText: 'Gruppo (opzionale)',
                hintText: 'Es. Riscaldamento, Lezione 3…',
                border: OutlineInputBorder(),
              ),
            ),
            // Suggerimenti dai gruppi già esistenti.
            Builder(builder: (context) {
              final existing = ref.watch(customExercisesProvider).value ?? const [];
              final groups = {
                for (final exercise in existing)
                  if (exercise.group != null) exercise.group!,
              }.toList()
                ..sort();
              if (groups.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final group in groups)
                      ActionChip(
                        label: Text(group),
                        onPressed: () => setState(() => _groupController.text = group),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Text('Tag (opzionale)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in focusOptions)
                  ChoiceChip(
                    label: Text(option),
                    selected: _focus == option,
                    onSelected: (selected) =>
                        setState(() => _focus = selected ? option : null),
                  ),
              ],
            ),
            // Prima il picker (posizione fissa), poi la sequenza selezionata:
            // così aggiungere note non fa "scendere" i tasti da premere.
            const SizedBox(height: 20),
            Text('Aggiungi note', style: theme.textTheme.titleMedium),
            Text(
              'Puoi partire da qualsiasi nota, ripetere la stessa nota e scendere sotto la prima. '
              'Nel trainer potrai comunque trasporre tutta la sequenza.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Center(
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 2, label: Text('Ott. 2')),
                  ButtonSegment(value: 3, label: Text('Ott. 3')),
                  ButtonSegment(value: 4, label: Text('Ott. 4')),
                  ButtonSegment(value: 5, label: Text('Ott. 5')),
                  ButtonSegment(value: 6, label: Text('Ott. 6')),
                ],
                selected: {_pickerOctave},
                onSelectionChanged: (selection) => setState(() => _pickerOctave = selection.first),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var semitone = 0; semitone < 12; semitone++)
                  _noteButton(context, notation, semitone),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Sequenza (${_midis.length} note)', style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Anteprima',
                  onPressed: _previewing ? null : _preview,
                  icon: Icon(_previewing ? Icons.hourglass_top : Icons.play_circle_outline),
                ),
                IconButton(
                  tooltip: 'Rimuovi ultima nota',
                  onPressed: _midis.isEmpty ? null : () => setState(_midis.removeLast),
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_midis.isEmpty)
              Text('Tocca le note qui sopra per costruire la sequenza.', style: theme.textTheme.bodySmall)
            else
              Builder(builder: (context) {
                final spelled = NoteSpeller.spellSequence(
                  [for (final midi in _midis) MusicalNote.fromMidi(midi)],
                );
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < spelled.length; i++)
                      InputChip(
                        label: Text(spelled[i].fullLabel(notation)),
                        onDeleted: () => setState(() => _midis.removeAt(i)),
                      ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _noteButton(BuildContext context, NoteNotation notation, int semitone) {
    final colors = Theme.of(context).colorScheme;
    final pitch = PitchClass.fromSemitone(semitone);
    final note = MusicalNote(pitchClass: pitch, octave: _pickerOctave);
    final isBlackKey = pitch.italianLabel.contains('#');
    return SizedBox(
      width: 74,
      height: 48,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isBlackKey ? colors.surfaceContainerHighest : null,
        ),
        onPressed: () => setState(() => _midis.add(note.midiNumber)),
        child: Text('${NoteSpeller.keyLabel(pitch, notation)}$_pickerOctave'),
      ),
    );
  }
}
