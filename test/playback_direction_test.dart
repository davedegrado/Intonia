import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/exercise.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';

ExerciseDefinition _def(List<int> steps) =>
    ExerciseDefinition(id: 'x', name: 'x', category: ExerciseCategory.custom, steps: steps);

const _major = [0, 2, 4, 5, 7, 9, 11, 12];

void main() {
  test('round trip with repeated top: base is the ascent only', () {
    final scale = _def(upDownWithRepeatedTop(_major));
    expect(scale.baseSteps, _major);
    expect(scale.isRoundTrip, isTrue);
    expect(scale.defaultDirection, PlaybackDirection.complete);
  });

  test('complete does not repeat the top note unless asked', () {
    final scale = _def(upDownWithRepeatedTop(_major));
    // C D E F G A B C B A G F E D C
    expect(scale.stepsFor(PlaybackDirection.complete),
        [0, 2, 4, 5, 7, 9, 11, 12, 11, 9, 7, 5, 4, 2, 0]);
    // C D E F G A B C C B A G F E D C
    expect(scale.stepsFor(PlaybackDirection.complete, repeatTop: true),
        [0, 2, 4, 5, 7, 9, 11, 12, 12, 11, 9, 7, 5, 4, 2, 0]);
  });

  test('forward and reverse ignore the repeat option and never duplicate the descent', () {
    final triad = _def(upDown(const [0, 4, 7]));
    expect(triad.baseSteps, [0, 4, 7]);
    expect(triad.stepsFor(PlaybackDirection.forward, repeatTop: true), [0, 4, 7]);
    expect(triad.stepsFor(PlaybackDirection.reverse, repeatTop: true), [7, 4, 0]);
    expect(triad.stepsFor(PlaybackDirection.complete), [0, 4, 7, 4, 0]);
  });

  test('non-mirrored sequences: forward is the original, complete goes back', () {
    final pattern = _def(const [0, 2, 4, 2, 7]);
    expect(pattern.isRoundTrip, isFalse);
    expect(pattern.defaultDirection, PlaybackDirection.forward);
    expect(pattern.stepsFor(PlaybackDirection.forward), [0, 2, 4, 2, 7]);
    expect(pattern.stepsFor(PlaybackDirection.complete), [0, 2, 4, 2, 7, 2, 4, 2, 0]);
  });

  test('the top is repeated only when the turn is really the highest note', () {
    final descending = _def(const [12, 7, 4, 0]);
    expect(descending.hasApex, isFalse);
    expect(
        descending.stepsFor(PlaybackDirection.complete, repeatTop: true), [12, 7, 4, 0, 4, 7, 12]);
  });

  test('every built-in exercise keeps its notes in the default mode, apart from the top', () {
    for (final exercise in const ExerciseLibrary().builtIn) {
      final built = exercise.stepsFor(exercise.defaultDirection);
      if (exercise.isRoundTrip) {
        // Unica differenza ammessa: il vertice ripetuto delle scale.
        final withTop = exercise.stepsFor(exercise.defaultDirection, repeatTop: true);
        expect(
          built.length == exercise.steps.length ? built : withTop,
          exercise.steps,
          reason: exercise.id,
        );
      } else {
        expect(built, exercise.steps, reason: exercise.id);
      }
    }
  });

  test('buildSequence follows the chosen direction', () {
    final triad = _def(upDown(const [0, 4, 7]));
    final notes = triad.buildSequence(
      key: PitchClass.c,
      octave: 4,
      direction: PlaybackDirection.reverse,
    );
    expect(notes.map((n) => n.midiNumber), [67, 64, 60]);
  });
}
