import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n.dart';
import '../../../app/note_text.dart';
import '../../../core/music/exercise.dart';
import '../../access/application/access_providers.dart';
import '../../access/domain/entitlement.dart';
import '../../../core/music/note.dart';
import '../../../core/music/note_spelling.dart';
import '../../../l10n/exercise_l10n.dart';
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

  /// Ordine dei tag nell'editor; si salva il valore storico italiano.
  static const focusOptions = [
    ExerciseFocus.accuracy,
    ExerciseFocus.control,
    ExerciseFocus.range,
    ExerciseFocus.agility,
    ExerciseFocus.ear,
  ];

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
    final initialFocus = widget.initial?.focus;
    _focus = initialFocus == null
        ? null
        : ExerciseFocus.parse(initialFocus)?.storedValue ?? initialFocus;
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
          SnackBar(content: Text(context.l10n.editorAudioUnavailable)),
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
          .showSnackBar(SnackBar(content: Text(context.l10n.editorErrorNoName)));
      return;
    }
    if (_midis.length < 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.editorErrorTooFewNotes)));
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
    final saved = await ref.read(customExercisesProvider.notifier).upsert(exercise);
    if (mounted && saved) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final notation = ref.watch(notationProvider);
    if (!ref.watch(entitlementProvider).allows(ProFeature.customSequences)) {
      return const _CustomSequencesPro();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? l10n.editorTitleNew : l10n.editorTitleEdit),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(l10n.commonSave),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.editorNameLabel,
                hintText: l10n.editorNameHint,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _groupController,
              decoration: InputDecoration(
                labelText: l10n.editorGroupLabel,
                hintText: l10n.editorGroupHint,
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
            Text(l10n.editorTagLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in focusOptions)
                  ChoiceChip(
                    label: Text(l10n.focusLabel(option.storedValue)),
                    selected: _focus == option.storedValue,
                    onSelected: (selected) =>
                        setState(() => _focus = selected ? option.storedValue : null),
                  ),
              ],
            ),
            // Prima il picker (posizione fissa), poi la sequenza selezionata:
            // così aggiungere note non fa "scendere" i tasti da premere.
            const SizedBox(height: 20),
            Text(l10n.editorAddNotesTitle, style: theme.textTheme.titleMedium),
            Text(
              l10n.editorAddNotesHint,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Center(
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (var octave = 2; octave <= 6; octave++)
                    ButtonSegment(value: octave, label: Text(l10n.editorOctaveShort(octave))),
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
                  child: Text(
                    l10n.editorSequenceTitle(_midis.length),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.editorPreview,
                  onPressed: _previewing ? null : _preview,
                  icon: Icon(_previewing ? Icons.hourglass_top : Icons.play_circle_outline),
                ),
                IconButton(
                  tooltip: l10n.editorRemoveLast,
                  onPressed: _midis.isEmpty ? null : () => setState(_midis.removeLast),
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_midis.isEmpty)
              Text(l10n.editorEmptySequence, style: theme.textTheme.bodySmall)
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
                        label: NoteText(spelled[i], notation: notation),
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

/// "Crea la tua sequenza" per gli utenti Free: spiega la funzione Pro senza
/// permettere di creare o salvare sequenze.
class _CustomSequencesPro extends StatelessWidget {
  const _CustomSequencesPro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editorProTitle)),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('custom-sequences-pro'),
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.edit_note, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              l10n.editorProHeadline,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.editorProBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.editorProNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/pro'),
              icon: const Icon(Icons.workspace_premium),
              label: Text(l10n.editorProCta),
            ),
          ],
        ),
      ),
    );
  }
}
