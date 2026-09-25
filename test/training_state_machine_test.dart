import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_detection_result.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/training_state_machine.dart';

void main() {
  test('does not advance while singer holds the previous accepted note', () {
    final machine = TrainingStateMachine(toleranceCents: 20, stabilityMs: 100);
    final target = const MusicalNote(pitchClass: PitchClass.c, octave: 4);
    final c4 = _result(target, 0);
    final now = DateTime(2026);

    machine.evaluate(target: target, detected: c4, now: now);
    final correct = machine.evaluate(
      target: target,
      detected: c4,
      now: now.add(const Duration(milliseconds: 120)),
    );

    expect(correct.event, TrainingValidationEvent.correct);
    expect(machine.state, TrainingValidationState.waitChange);

    final held = machine.evaluate(
      target: target,
      detected: c4,
      now: now.add(const Duration(milliseconds: 260)),
    );

    expect(held.event, TrainingValidationEvent.none);
    expect(held.canAdvance, isFalse);
  });

  test('advances on the SAME note when re-attacked after a break', () {
    final machine = TrainingStateMachine(toleranceCents: 20, stabilityMs: 100, breakMs: 150);
    final target = const MusicalNote(pitchClass: PitchClass.c, octave: 4);
    final c4 = _result(target, 0);
    var now = DateTime(2026);

    // Prima nota corretta.
    machine.evaluate(target: target, detected: c4, now: now);
    now = now.add(const Duration(milliseconds: 120));
    final correct = machine.evaluate(target: target, detected: c4, now: now);
    expect(correct.event, TrainingValidationEvent.correct);

    // Pausa (silenzio/instabile) più lunga di breakMs.
    now = now.add(const Duration(milliseconds: 50));
    machine.evaluate(target: target, detected: PitchDetectionResult.silence, now: now);
    now = now.add(const Duration(milliseconds: 200));
    machine.evaluate(target: target, detected: PitchDetectionResult.silence, now: now);

    // Riattacco della stessa nota: dopo la stabilità deve avanzare.
    now = now.add(const Duration(milliseconds: 50));
    machine.evaluate(target: target, detected: c4, now: now);
    now = now.add(const Duration(milliseconds: 120));
    final reattack = machine.evaluate(target: target, detected: c4, now: now);

    expect(reattack.event, TrainingValidationEvent.advanced);
    expect(reattack.canAdvance, isTrue);
  });

  test('a short instability (vibrato) does NOT count as a break', () {
    final machine = TrainingStateMachine(toleranceCents: 20, stabilityMs: 100, breakMs: 150);
    final target = const MusicalNote(pitchClass: PitchClass.c, octave: 4);
    final c4 = _result(target, 0);
    var now = DateTime(2026);

    machine.evaluate(target: target, detected: c4, now: now);
    now = now.add(const Duration(milliseconds: 120));
    machine.evaluate(target: target, detected: c4, now: now);
    expect(machine.state, TrainingValidationState.waitChange);

    // Dip instabile di soli 50 ms.
    now = now.add(const Duration(milliseconds: 30));
    machine.evaluate(target: target, detected: PitchDetectionResult.silence, now: now);
    now = now.add(const Duration(milliseconds: 50));
    machine.evaluate(target: target, detected: PitchDetectionResult.silence, now: now);

    // La stessa nota tenuta non deve avanzare.
    now = now.add(const Duration(milliseconds: 30));
    machine.evaluate(target: target, detected: c4, now: now);
    now = now.add(const Duration(milliseconds: 120));
    final held = machine.evaluate(target: target, detected: c4, now: now);

    expect(held.event, TrainingValidationEvent.none);
    expect(held.canAdvance, isFalse);
  });

  test('retry waits for a real note change after a wrong note', () {
    final machine = TrainingStateMachine(toleranceCents: 20, stabilityMs: 100);
    final target = const MusicalNote(pitchClass: PitchClass.c, octave: 4);
    final wrong = const MusicalNote(pitchClass: PitchClass.d, octave: 4);
    final now = DateTime(2026);

    machine.evaluate(target: target, detected: _result(wrong, 0), now: now);
    final wrongStable = machine.evaluate(
      target: target,
      detected: _result(wrong, 0),
      now: now.add(const Duration(milliseconds: 120)),
    );

    expect(wrongStable.event, TrainingValidationEvent.wrong);
    expect(machine.state, TrainingValidationState.waitRetry);

    final sameWrong = machine.evaluate(
      target: target,
      detected: _result(wrong, 0),
      now: now.add(const Duration(milliseconds: 260)),
    );

    expect(sameWrong.event, TrainingValidationEvent.none);
    expect(machine.state, TrainingValidationState.waitRetry);
  });
}

PitchDetectionResult _result(MusicalNote note, double cents) {
  return PitchDetectionResult(
    frequency: note.frequency,
    note: note,
    cents: cents,
    confidence: 0.95,
    isStable: true,
  );
}
