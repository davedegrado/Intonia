import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/session/session_record.dart';
import 'package:vocal_scale_trainer/core/session/session_stats.dart';

void main() {
  test('builds record from stats with per-note counts and vocal range', () {
    const c4 = MusicalNote(pitchClass: PitchClass.c, octave: 4);
    const e4 = MusicalNote(pitchClass: PitchClass.e, octave: 4);
    const g4 = MusicalNote(pitchClass: PitchClass.g, octave: 4);
    var stats = SessionStats.started();
    stats = stats
        .addAttempt(NoteAttempt(target: c4, detected: c4, cents: 3, correct: true, timestamp: DateTime(2026)))
        .addAttempt(NoteAttempt(target: e4, detected: g4, cents: 12, correct: false, timestamp: DateTime(2026)))
        .addAttempt(NoteAttempt(target: e4, detected: e4, cents: -5, correct: true, timestamp: DateTime(2026)))
        .addAttempt(NoteAttempt(target: g4, detected: g4, cents: 8, correct: true, timestamp: DateTime(2026)));

    final record = SessionRecord.fromStats(
      stats: stats.finish(),
      exerciseId: 'triad_major',
      exerciseName: 'Triade maggiore',
    );

    expect(record.correct, 3);
    expect(record.errors, 1);
    expect(record.perNote[e4.midiNumber], [1, 1]);
    expect(record.minCorrectMidi, c4.midiNumber);
    expect(record.maxCorrectMidi, g4.midiNumber);

    final restored = SessionRecord.fromJson(record.toJson());
    expect(restored.perNote, record.perNote);
    expect(restored.accuracy, record.accuracy);
    expect(restored.exerciseName, 'Triade maggiore');
  });

  group('computeStreak', () {
    final now = DateTime(2026, 7, 8, 20);

    test('counts consecutive days ending today', () {
      final streak = computeStreak([
        DateTime(2026, 7, 8, 9),
        DateTime(2026, 7, 7, 21),
        DateTime(2026, 7, 6, 8),
        DateTime(2026, 7, 3),
      ], now);
      expect(streak, 3);
    });

    test('still alive if last session was yesterday', () {
      expect(computeStreak([DateTime(2026, 7, 7)], now), 1);
    });

    test('broken streak returns 0', () {
      expect(computeStreak([DateTime(2026, 7, 5)], now), 0);
    });

    test('multiple sessions in one day count once', () {
      final streak = computeStreak([
        DateTime(2026, 7, 8, 9),
        DateTime(2026, 7, 8, 22),
      ], now);
      expect(streak, 1);
    });

    test('empty history returns 0', () {
      expect(computeStreak(const [], now), 0);
    });
  });
}
