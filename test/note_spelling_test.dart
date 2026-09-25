import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/exercise.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/music/note_spelling.dart';

void main() {
  const library = ExerciseLibrary();

  List<String> labels(List<SpelledNote> spelled, [NoteNotation n = NoteNotation.italian]) {
    return [for (final note in spelled) note.label(n)];
  }

  test('F major scale uses SIb, not LA#', () {
    final exercise = library.byId('major')!;
    final sequence = exercise.buildSequence(key: PitchClass.f, octave: 3);
    final spelled = NoteSpeller.spellSequence(sequence);

    expect(labels(spelled).sublist(0, 8), [
      'FA', 'SOL', 'LA', 'SIb', 'DO', 'RE', 'MI', 'FA',
    ]);
  });

  test('C natural minor uses MIb, LAb, SIb', () {
    final exercise = library.byId('natural_minor')!;
    final sequence = exercise.buildSequence(key: PitchClass.c, octave: 4);
    final spelled = NoteSpeller.spellSequence(sequence);

    expect(labels(spelled).sublist(0, 8), [
      'DO', 'RE', 'MIb', 'FA', 'SOL', 'LAb', 'SIb', 'DO',
    ]);
  });

  test('A harmonic minor uses SOL# for the leading tone', () {
    final exercise = library.byId('harmonic_minor')!;
    final sequence = exercise.buildSequence(key: PitchClass.a, octave: 3);
    final spelled = NoteSpeller.spellSequence(sequence);

    expect(labels(spelled).sublist(0, 8), [
      'LA', 'SI', 'DO', 'RE', 'MI', 'FA', 'SOL#', 'LA',
    ]);
  });

  test('augmented triad is spelled with #5, not b6', () {
    final exercise = library.byId('triad_augmented')!;
    final sequence = exercise.buildSequence(key: PitchClass.c, octave: 4);
    final spelled = NoteSpeller.spellSequence(sequence);

    expect(labels(spelled), ['DO', 'MI', 'SOL#', 'MI', 'DO']);
  });

  test('diminished triad keeps the flat fifth', () {
    final exercise = library.byId('triad_diminished')!;
    final sequence = exercise.buildSequence(key: PitchClass.c, octave: 4);
    final spelled = NoteSpeller.spellSequence(sequence);

    expect(labels(spelled), ['DO', 'MIb', 'SOLb', 'MIb', 'DO']);
  });

  test('black-key tonics use the preferred name (SIb major)', () {
    final exercise = library.byId('major')!;
    final sequence = exercise.buildSequence(key: PitchClass.aSharp, octave: 3);
    final spelled = NoteSpeller.spellSequence(sequence);

    expect(labels(spelled).sublist(0, 8), [
      'SIb', 'DO', 'RE', 'MIb', 'FA', 'SOL', 'LA', 'SIb',
    ]);
    expect(NoteSpeller.keyLabel(PitchClass.aSharp, NoteNotation.italian), 'SIb');
    expect(NoteSpeller.keyLabel(PitchClass.aSharp, NoteNotation.english), 'Bb');
    expect(NoteSpeller.keyLabel(PitchClass.fSharp, NoteNotation.italian), 'FA#');
  });

  test('english notation spells Eb major with flats', () {
    final exercise = library.byId('major')!;
    final sequence = exercise.buildSequence(key: PitchClass.dSharp, octave: 4);
    final spelled = NoteSpeller.spellSequence(sequence);

    expect(labels(spelled, NoteNotation.english).sublist(0, 8), [
      'Eb', 'F', 'G', 'Ab', 'Bb', 'C', 'D', 'Eb',
    ]);
  });

  test('negative offsets are spelled below the root', () {
    const custom = ExerciseDefinition(
      id: 'c',
      name: 'giù',
      category: ExerciseCategory.custom,
      steps: [0, -1, -12],
      isCustom: true,
    );
    final sequence = custom.buildSequence(key: PitchClass.c, octave: 4);
    final spelled = NoteSpeller.spellSequence(sequence);

    expect([for (final note in spelled) note.fullLabel(NoteNotation.italian)], [
      'DO4', 'SI3', 'DO3',
    ]);
  });

  test('melodic minor harmonization exists with 24 notes', () {
    final exercise = library.byId('harmonized_melodic_minor')!;
    expect(exercise.steps.length, 24);
    final sequence = exercise.buildSequence(key: PitchClass.c, octave: 4);
    final spelled = NoteSpeller.spellSequence(sequence);
    // I grado del C minore melodico: DO-MIb-SOL.
    expect(labels(spelled).sublist(0, 3), ['DO', 'MIb', 'SOL']);
  });
}
