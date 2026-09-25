import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/exercise.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';

void main() {
  const library = ExerciseLibrary();

  test('major scale keeps ascending/descending shape with repeated top note', () {
    final exercise = library.byId('major')!;
    final sequence = exercise.buildSequence(key: PitchClass.c, octave: 4);

    expect(sequence.map((note) => note.label), [
      'DO', 'RE', 'MI', 'FA', 'SOL', 'LA', 'SI', 'DO',
      'DO',
      'SI', 'LA', 'SOL', 'FA', 'MI', 'RE', 'DO',
    ]);
  });

  test('major triad is arpeggiated up and down without repeating the top', () {
    final exercise = library.byId('triad_major')!;
    final sequence = exercise.buildSequence(key: PitchClass.c, octave: 4);

    expect(sequence.map((note) => note.label), ['DO', 'MI', 'SOL', 'MI', 'DO']);
  });

  test('minor arpeggio spans the octave', () {
    final exercise = library.byId('arpeggio_minor_octave')!;
    final sequence = exercise.buildSequence(key: PitchClass.a, octave: 3);

    expect(sequence.map((note) => note.fullLabel), [
      'LA3', 'DO4', 'MI4', 'LA4', 'MI4', 'DO4', 'LA3',
    ]);
  });

  test('harmonized major scale starts with the diatonic triads of each degree', () {
    final exercise = library.byId('harmonized_major')!;
    final sequence = exercise.buildSequence(key: PitchClass.c, octave: 4);

    // 8 gradi (ottava compresa) x 3 note.
    expect(sequence.length, 24);
    // I grado: DO-MI-SOL, II grado: RE-FA-LA, VII grado: SI-RE-FA.
    expect(sequence.sublist(0, 6).map((note) => note.label), [
      'DO', 'MI', 'SOL', 'RE', 'FA', 'LA',
    ]);
    expect(sequence.sublist(18, 21).map((note) => note.fullLabel), [
      'SI4', 'RE5', 'FA5',
    ]);
    // VIII grado: DO⁺-MI⁺-SOL⁺.
    expect(sequence.sublist(21).map((note) => note.fullLabel), [
      'DO5', 'MI5', 'SOL5',
    ]);
  });

  test('custom exercises survive JSON round-trip including rootMidi', () {
    const original = ExerciseDefinition(
      id: 'custom_1',
      name: 'Da RE a RE++',
      category: ExerciseCategory.custom,
      steps: [0, 12, 24],
      isCustom: true,
      rootMidi: 62, // RE4
      focus: 'Estensione',
      group: 'Riscaldamento',
    );

    final restored = ExerciseDefinition.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.steps, original.steps);
    expect(restored.rootMidi, 62);
    expect(restored.focus, 'Estensione');
    expect(restored.group, 'Riscaldamento');
    expect(restored.isCustom, isTrue);
    expect(restored.category, ExerciseCategory.custom);
  });

  test('custom exercises allow repeated and descending notes', () {
    const extension = ExerciseDefinition(
      id: 'custom_ext',
      name: 'Soli DO',
      category: ExerciseCategory.custom,
      steps: [0, 0, 0, -12],
      isCustom: true,
    );
    final sequence = extension.buildSequence(key: PitchClass.c, octave: 4);

    expect(sequence.map((note) => note.fullLabel), ['DO4', 'DO4', 'DO4', 'DO3']);
  });

  test('english notation maps DO-RE-MI to C-D-E', () {
    const note = MusicalNote(pitchClass: PitchClass.c, octave: 4);
    expect(note.labelFor(NoteNotation.italian), 'DO');
    expect(note.labelFor(NoteNotation.english), 'C');
    expect(note.fullLabelFor(NoteNotation.english), 'C4');
    expect(PitchClass.fSharp.labelFor(NoteNotation.english), 'F#');
  });

  test('transposition follows the selected key', () {
    final exercise = library.byId('triad_major')!;
    final sequence = exercise.buildSequence(key: PitchClass.g, octave: 3);

    expect(sequence.first.fullLabel, 'SOL3');
    expect(sequence[2].fullLabel, 'RE4');
  });
}
