import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_detection_result.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_recognition_config.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_stabilizer.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/training_settings.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/training_state_machine.dart';

const c4 = MusicalNote(pitchClass: PitchClass.c, octave: 4);
const cSharp4 = MusicalNote(pitchClass: PitchClass.cSharp, octave: 4);

/// Intervallo tra due frame del rilevatore (hop di 1024 campioni a 44.1 kHz).
const frame = Duration(milliseconds: 23);

/// Frame grezzo come lo produce il rilevatore: nota più vicina e scarto.
PitchDetectionResult sung(double midi) {
  final frequency = 440 * math.pow(2, (midi - 69) / 12).toDouble();
  final note = MusicalNote.fromFrequency(frequency);
  return PitchDetectionResult(
    frequency: frequency,
    note: note,
    cents: note.centsFromFrequency(frequency),
    confidence: 0.95,
    isStable: true,
  );
}

/// Midi frazionario di [note] spostato di [cents].
double at(MusicalNote note, double cents) => note.midiNumber + cents / 100;

/// Vibrato: oscillazione sinusoidale di ±[extentCents] a [rateHz] attorno a [centerCents].
double vibrato(MusicalNote note, Duration t,
    {double centerCents = 0, double extentCents = 60, double rateHz = 5.5}) {
  final seconds = t.inMicroseconds / 1e6;
  return at(note, centerCents + extentCents * math.sin(2 * math.pi * rateHz * seconds));
}

void main() {
  final start = DateTime(2026);

  group('PitchStabilizer', () {
    test('normal and wide vibrato do not change the recognized note', () {
      // Ampiezza e frequenza tipiche, fino a un vibrato lirico ampio e lento.
      for (final (extent, rate) in [(30.0, 6.0), (60.0, 5.5), (100.0, 5.0), (100.0, 4.5)]) {
        final stabilizer = PitchStabilizer();
        final notes = <int>{};
        for (var t = Duration.zero; t < const Duration(seconds: 2); t += frame) {
          final out = stabilizer.process(
              sung(vibrato(c4, t, extentCents: extent, rateHz: rate)), start.add(t));
          notes.add(out.note.midiNumber);
        }
        expect(notes, {c4.midiNumber}, reason: 'vibrato ±$extent cent a $rate Hz');
      }
    });

    test('a slightly flat note with vibrato stays on that note', () {
      final stabilizer = PitchStabilizer();
      final notes = <int>{};
      for (var t = Duration.zero; t < const Duration(seconds: 2); t += frame) {
        // Centrato a -40 cent: il vibrato tocca -65, oltre il confine con SI3.
        final out = stabilizer.process(
            sung(vibrato(c4, t, centerCents: -40, extentCents: 25)), start.add(t));
        notes.add(out.note.midiNumber);
      }
      expect(notes, {c4.midiNumber});
    });

    test('moving to the adjacent semitone is recognized quickly', () {
      final config = PitchRecognitionConfig.standard;
      final stabilizer = PitchStabilizer();
      var t = Duration.zero;
      for (; t < const Duration(milliseconds: 300); t += frame) {
        stabilizer.process(sung(at(c4, 0)), start.add(t));
      }
      final switchStart = t;
      var switchedAt = Duration.zero;
      for (; t < const Duration(milliseconds: 600); t += frame) {
        final out = stabilizer.process(sung(at(cSharp4, 0)), start.add(t));
        if (out.note == cSharp4) {
          switchedAt = t - switchStart;
          break;
        }
      }
      expect(switchedAt.inMilliseconds,
          lessThanOrEqualTo(config.noteSwitchMs + 3 * frame.inMilliseconds));
    });

    test('a jump wider than a semitone is recognized at once', () {
      final stabilizer = PitchStabilizer();
      var t = Duration.zero;
      for (; t < const Duration(milliseconds: 300); t += frame) {
        stabilizer.process(sung(at(c4, 0)), start.add(t));
      }
      const e4 = MusicalNote(pitchClass: PitchClass.e, octave: 4);
      stabilizer.process(sung(at(e4, 0)), start.add(t));
      final out = stabilizer.process(sung(at(e4, 0)), start.add(t + frame));
      expect(out.note, e4, reason: 'solo il ritardo della mediana');
    });

    test('a different note sung inside the hysteresis margin is not held forever', () {
      final config = PitchRecognitionConfig.standard;
      final stabilizer = PitchStabilizer();
      var t = Duration.zero;
      for (; t < const Duration(milliseconds: 300); t += frame) {
        stabilizer.process(sung(at(c4, 0)), start.add(t));
      }
      // DO#4 calante di 40 cent = DO4 +60: vicino al confine, ma tenuto.
      final switchStart = t;
      Duration? switchedAt;
      for (; t < const Duration(milliseconds: 900); t += frame) {
        final out = stabilizer.process(sung(at(cSharp4, -40)), start.add(t));
        if (out.note == cSharp4) {
          switchedAt = t - switchStart;
          break;
        }
      }
      expect(switchedAt, isNotNull);
      expect(switchedAt!.inMilliseconds,
          lessThanOrEqualTo(config.noteSwitchMs + 3 * frame.inMilliseconds));
    });

    test('a single anomalous frame (octave error) is ignored', () {
      final stabilizer = PitchStabilizer();
      var t = Duration.zero;
      final notes = <int>[];
      for (var i = 0; i < 20; i++, t += frame) {
        final midi = i == 10 ? at(c4, 0) + 12 : at(c4, 0);
        notes.add(stabilizer.process(sung(midi), start.add(t)).note.midiNumber);
      }
      expect(notes.toSet(), {c4.midiNumber});
    });

    test('short dropouts keep the note, real silence clears it', () {
      final config = PitchRecognitionConfig.standard;
      final stabilizer = PitchStabilizer();
      stabilizer.process(sung(at(c4, 0)), start);
      stabilizer.process(PitchDetectionResult.silence, start.add(frame));
      stabilizer.process(PitchDetectionResult.silence, start.add(frame * 2));
      expect(stabilizer.current?.note, c4);

      stabilizer.process(PitchDetectionResult.silence,
          start.add(Duration(milliseconds: config.dropoutGraceMs + 30)));
      expect(stabilizer.current, isNull);
    });

    test('stale frames from before a long gap are discarded', () {
      final stabilizer = PitchStabilizer();
      for (var t = Duration.zero; t < const Duration(milliseconds: 200); t += frame) {
        stabilizer.process(sung(at(c4, 0)), start.add(t));
      }
      // Analisi sospesa (nota guida), poi la voce è già sulla nota nuova.
      final out =
          stabilizer.process(sung(at(cSharp4, 0)), start.add(const Duration(milliseconds: 1300)));
      expect(out.note, cSharp4);
    });

    test('cents are measured from the recognized note, detection precision is kept', () {
      final stabilizer = PitchStabilizer();
      final out = stabilizer.process(sung(at(c4, 23)), start);
      expect(out.note, c4);
      expect(out.cents, closeTo(23, 0.01));
    });
  });

  group('exercise tolerance', () {
    test('default exercise tolerance is suited to the human voice', () {
      final defaults = TrainingSettings.defaults();
      expect(defaults.toleranceCents, PitchRecognitionConfig.defaultExerciseToleranceCents);
      expect(defaults.toleranceCents, 45);
      expect(defaults.stabilityMs, PitchRecognitionConfig.defaultStabilityMs);
      expect(defaults.stabilityMs, 100);
    });

    TrainingValidationEvent judge(double cents, {int tolerance = 35}) {
      final machine = TrainingStateMachine(toleranceCents: tolerance, stabilityMs: 200);
      var event = TrainingValidationEvent.none;
      for (var t = Duration.zero; t <= const Duration(milliseconds: 300); t += frame) {
        final out = machine.evaluate(target: c4, detected: sung(at(c4, cents)), now: start.add(t));
        if (out.event != TrainingValidationEvent.none) {
          event = out.event;
          break;
        }
      }
      return event;
    }

    test('boundaries of a ±35 cent tolerance', () {
      expect(judge(0), TrainingValidationEvent.correct);
      expect(judge(34), TrainingValidationEvent.correct);
      expect(judge(-35), TrainingValidationEvent.correct);
      expect(judge(36), TrainingValidationEvent.wrong);
      expect(judge(-45), TrainingValidationEvent.wrong);
    });

    test('precision exercises keep a stricter tolerance', () {
      expect(judge(15, tolerance: 10), TrainingValidationEvent.wrong);
      expect(judge(8, tolerance: 10), TrainingValidationEvent.correct);
    });

    test('a note in tune on average is accepted despite vibrato', () {
      final machine = TrainingStateMachine(toleranceCents: 35, stabilityMs: 200);
      var event = TrainingValidationEvent.none;
      for (var t = Duration.zero; t < const Duration(seconds: 1); t += frame) {
        final out = machine.evaluate(
            target: c4, detected: sung(vibrato(c4, t, extentCents: 50)), now: start.add(t));
        if (out.event != TrainingValidationEvent.none) {
          event = out.event;
          break;
        }
      }
      expect(event, TrainingValidationEvent.correct);
    });

    test('a short dropout does not restart the stability time', () {
      final machine = TrainingStateMachine(toleranceCents: 35, stabilityMs: 200);
      Duration? correctAt;
      for (var t = Duration.zero; t < const Duration(milliseconds: 600); t += frame) {
        // Due frame senza voce (~46 ms) a metà della nota.
        final silent =
            t >= const Duration(milliseconds: 90) && t < const Duration(milliseconds: 140);
        final out = machine.evaluate(
          target: c4,
          detected: silent ? PitchDetectionResult.silence : sung(at(c4, 5)),
          now: start.add(t),
        );
        if (out.event == TrainingValidationEvent.correct) {
          correctAt = t;
          break;
        }
      }
      expect(correctAt, isNotNull);
      expect(correctAt!.inMilliseconds, lessThan(260),
          reason: 'la stabilità non riparte da zero dopo la caduta');
    });

    test('the wrong adjacent note is not accepted as the target', () {
      expect(judge(100), TrainingValidationEvent.wrong); // DO#4 pieno
      expect(judge(100, tolerance: 45), TrainingValidationEvent.wrong);
      expect(judge(44, tolerance: 45), TrainingValidationEvent.correct);
    });

    test('the next note is validated within one stability window', () {
      const d4 = MusicalNote(pitchClass: PitchClass.d, octave: 4);
      final machine = TrainingStateMachine(toleranceCents: 45, stabilityMs: 100);
      var t = Duration.zero;
      TrainingValidationEvent event = TrainingValidationEvent.none;
      for (; event != TrainingValidationEvent.correct; t += frame) {
        event = machine.evaluate(target: c4, detected: sung(at(c4, 0)), now: start.add(t)).event;
      }
      // Il cantante passa alla nota successiva: il cambio fa avanzare e la
      // nota viene subito valutata contro il nuovo obiettivo.
      final changeAt = t;
      var target = c4;
      Duration? correctAt;
      for (; t < changeAt + const Duration(milliseconds: 600); t += frame) {
        final out = machine.evaluate(target: target, detected: sung(at(d4, 0)), now: start.add(t));
        if (out.event == TrainingValidationEvent.advanced) {
          machine.markAdvanced();
          target = d4;
        } else if (out.event == TrainingValidationEvent.correct) {
          correctAt = t - changeAt;
          break;
        }
      }
      expect(correctAt, isNotNull);
      expect(correctAt!.inMilliseconds, lessThan(100 + 4 * frame.inMilliseconds),
          reason: 'una sola finestra di stabilità, non due');
    });
  });
}
