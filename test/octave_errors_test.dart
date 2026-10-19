import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_detection_result.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_frame_analyzer.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_stabilizer.dart';
import 'package:vocal_scale_trainer/core/pitch/yin_pitch_detector.dart';
import 'package:vocal_scale_trainer/features/extreme_notes/domain/extreme_notes.dart';

const _sampleRate = 44100;

/// Tratto di voce sintetica: fondamentale [f0] con le armoniche [harmonics]
/// (ampiezze relative), vibrato, jitter di periodo, shimmer d'ampiezza,
/// rumore, attacco e ampiezza complessiva.
class Segment {
  const Segment(
    this.f0,
    this.seconds, {
    this.harmonics = const [1.0, 0.6, 0.4, 0.2],
    this.vibratoCents = 50,
    this.jitter = 0.005,
    this.shimmer = 0.1,
    this.noise = 0.0,
    this.amplitude = 0.25,
    this.attackMs = 30,
  });

  /// Silenzio (pausa, respiro).
  const Segment.rest(this.seconds)
      : f0 = 0,
        harmonics = const [],
        vibratoCents = 0,
        jitter = 0,
        shimmer = 0,
        noise = 0,
        amplitude = 0,
        attackMs = 0;

  final double f0;
  final double seconds;
  final List<double> harmonics;
  final double vibratoCents;
  final double jitter;
  final double shimmer;
  final double noise;
  final double amplitude;
  final int attackMs;
}

List<double> synth(List<Segment> segments, {int seed = 7}) {
  final random = math.Random(seed);
  final out = <double>[];
  var phase = 0.0;
  var jitter = 0.0;
  var shimmer = 1.0;
  for (final segment in segments) {
    final n = (segment.seconds * _sampleRate).round();
    for (var i = 0; i < n; i++) {
      if (segment.f0 == 0) {
        out.add(0);
        continue;
      }
      final t = i / _sampleRate;
      if (i % 200 == 0) {
        jitter = (random.nextDouble() * 2 - 1) * segment.jitter;
        shimmer = 1 + (random.nextDouble() * 2 - 1) * segment.shimmer;
      }
      final f = segment.f0 *
          math.pow(2, segment.vibratoCents / 1200 * math.sin(2 * math.pi * 5.5 * t)) *
          (1 + jitter);
      phase += 2 * math.pi * f / _sampleRate;
      var sample = 0.0;
      for (var h = 0; h < segment.harmonics.length; h++) {
        if ((h + 1) * segment.f0 < _sampleRate / 2) {
          sample += segment.harmonics[h] * math.sin((h + 1) * phase + h * 0.7);
        }
      }
      final attack = segment.attackMs == 0 ? 1.0 : math.min(1.0, t * 1000 / segment.attackMs);
      out.add(segment.amplitude * shimmer * attack * sample +
          segment.noise * (random.nextDouble() * 2 - 1));
    }
  }
  return out;
}

/// Pipeline completa del servizio: analizzatore (rilevatore + banda bassa)
/// e stabilizzatore, con il tempo dei frame (~23 ms ciascuno).
class Pipeline {
  final analyzer = PitchFrameAnalyzer();
  final stabilizer = PitchStabilizer();
  var now = DateTime(2026, 10, 20, 9);

  List<PitchDetectionResult> raw = [];
  List<PitchDetectionResult> validated = [];

  void feed(List<double> samples) {
    for (final frame in analyzer.addSamples(samples)) {
      now = now.add(const Duration(microseconds: 23220));
      raw.add(frame);
      validated.add(stabilizer.process(frame, now));
    }
  }
}

double centsBetween(double frequency, double reference) =>
    1200 * math.log(frequency / reference) / math.ln2;

/// Frame stabili a un'ottava (o più) da [f0].
int octaveErrors(Iterable<PitchDetectionResult> frames, double f0) => frames
    .where((r) => r.isStable && r.frequency > 0 && centsBetween(r.frequency, f0).abs() > 600)
    .length;

void main() {
  group('detector octave check', () {
    test('1. a pure 440 Hz fundamental is LA4', () {
      final pipeline = Pipeline()
        ..feed(synth(const [
          Segment(440, 0.5, harmonics: [1.0], vibratoCents: 0, jitter: 0)
        ]));
      final stable = pipeline.raw.skip(2).where((r) => r.isStable).toList();
      expect(stable.length, greaterThan(15));
      expect(stable.every((r) => r.note.fullLabel == 'LA4'), isTrue);
    });

    test('2. 440 Hz with a stronger 880 Hz second harmonic stays LA4', () {
      for (final harmonics in const [
        [0.5, 1.0],
        [0.3, 1.0],
        [0.2, 1.0],
        [0.3, 1.0, 0.05, 0.4],
        [0.25, 1.0, 0.7, 0.4],
      ]) {
        for (final jitter in const [0.005, 0.02]) {
          final pipeline = Pipeline()
            ..feed(synth([Segment(440, 0.6, harmonics: harmonics, jitter: jitter)]));
          final frames = pipeline.raw.skip(3);
          expect(octaveErrors(frames, 440), 0, reason: '$harmonics jitter $jitter');
          final stable = frames.where((r) => r.isStable).length;
          expect(stable, greaterThan(frames.length * 0.8),
              reason: '$harmonics: troppi frame persi');
        }
      }
    });

    test('3. an 880 Hz fundamental is LA5, never corrected down to LA4', () {
      for (final harmonics in const [
        [1.0],
        [1.0, 0.5, 0.3],
        [1.0, 0.2],
      ]) {
        final pipeline = Pipeline()..feed(synth([Segment(880, 0.6, harmonics: harmonics)]));
        final stable = pipeline.raw.skip(3).where((r) => r.isStable);
        expect(stable, isNotEmpty);
        expect(octaveErrors(stable, 880), 0, reason: '$harmonics');
        expect(pipeline.validated.last.note.fullLabel, 'LA5');
      }
    });

    test('octave errors in noisy frames are removed, not just moved (regression)', () {
      // Prima della correzione: con rumore il periodo si allungava di una o
      // più ottave (finestra d'integrazione variabile) e la banda bassa
      // agganciava una sottoarmonica (220 Hz cantando 440 Hz).
      for (final f0 in const [220.0, 330.0, 440.0, 660.0, 880.0]) {
        for (final harmonics in const [
          [1.0],
          [1.0, 0.5, 0.3],
          [0.5, 1.0, 0.4],
        ]) {
          for (final noise in const [0.1, 0.15]) {
            final pipeline = Pipeline()
              ..feed(synth([
                Segment(f0, 0.5, harmonics: harmonics, noise: noise, vibratoCents: 0, jitter: 0)
              ]));
            expect(octaveErrors(pipeline.raw, f0), 0, reason: '$f0 $harmonics noise $noise');
          }
        }
      }
    });

    test('9. near the limits of the range: no invalid candidates, no wrong octave', () {
      // DO6 (1046,5 Hz): appena sotto il limite di 1100 Hz.
      var pipeline = Pipeline()
        ..feed(synth(const [
          Segment(1046.5, 0.5, harmonics: [1.0, 0.4])
        ]));
      expect(octaveErrors(pipeline.raw, 1046.5), 0);
      expect(pipeline.validated.last.note.fullLabel, 'DO6');
      // RE5: la seconda armonica (1175 Hz) cade appena oltre il limite.
      pipeline = Pipeline()
        ..feed(synth(const [
          Segment(587.3, 0.5, harmonics: [0.15, 1.0])
        ]));
      expect(octaveErrors(pipeline.raw, 587.3), 0);
      expect(pipeline.raw.skip(3).where((r) => r.isStable).length, greaterThan(10));
      // Oltre il limite (1150 Hz): nessuna nota, non un'ottava sotto.
      pipeline = Pipeline()
        ..feed(synth(const [
          Segment(1150, 0.5, harmonics: [1.0], vibratoCents: 0, jitter: 0)
        ]));
      expect(pipeline.raw.where((r) => r.isStable), isEmpty);
      // LA1 (55 Hz) e MI1 (41,2 Hz, banda bassa) restano riconosciute.
      for (final (f0, label) in const [(55.0, 'LA1'), (41.2, 'MI1'), (65.4, 'DO2')]) {
        pipeline = Pipeline()
          ..feed(synth([
            Segment(f0, 0.6, harmonics: const [1.0, 0.5, 0.3])
          ]));
        expect(octaveErrors(pipeline.raw, f0), 0, reason: label);
        expect(pipeline.validated.last.note.fullLabel, label);
      }
    });

    test('the candidate search stays inside the detector range', () {
      final detector = YinPitchDetector(sampleRate: _sampleRate);
      final analysis = detector.analyze(synth(const [
        Segment(440, 0.05, harmonics: [1.0])
      ]));
      expect(
          YinPitchDetector.localMinimumNear(analysis.cmndf, 10, analysis.minTau, analysis.maxTau),
          isNull);
      expect(
          YinPitchDetector.localMinimumNear(
              analysis.cmndf, analysis.maxTau * 2.0, analysis.minTau, analysis.maxTau),
          isNull);
    });
  });

  group('stabilizer', () {
    test('4/5. real octave jumps LA4 → LA5 → LA4 are followed promptly', () {
      final pipeline = Pipeline()
        ..feed(synth(const [
          Segment(440, 0.6),
          Segment(880, 0.6, attackMs: 0),
          Segment(440, 0.6, attackMs: 0),
        ]));
      final labels = [for (final r in pipeline.validated) r.isStable ? r.note.fullLabel : '-'];
      final up = labels.indexOf('LA5');
      final down = labels.lastIndexOf('LA5') + 1;
      expect(up, greaterThan(0));
      // Il salto arriva circa al frame 26 (0,6 s): riconosciuto entro ~6 frame.
      expect(up, lessThan(26 + 6));
      expect(labels.sublist(up, down).every((l) => l == 'LA5'), isTrue);
      // Ritorno a LA4: il frame a cavallo delle due note dà per un attimo un
      // valore intermedio (comportamento dello stabilizzatore per ogni salto
      // ampio), poi LA4 entro ~8 frame.
      expect(labels.sublist(down, down + 8), contains('LA4'));
      expect(labels.skip(down + 8).every((l) => l == 'LA4'), isTrue);
      expect(labels.skip(down).where((l) => l.startsWith('LA') && l.endsWith('5')), isEmpty);
      expect(down, lessThan(52 + 6));
    });

    test('two consecutive octave-error frames do not change the note', () {
      final stabilizer = PitchStabilizer();
      var now = DateTime(2026, 10, 20, 9);
      PitchDetectionResult frame(double frequency) {
        final r = Pipeline().analyzer.addSamples(synth([
              Segment(frequency, 0.1, harmonics: const [1.0], vibratoCents: 0, jitter: 0)
            ]));
        return r.last;
      }

      final la4 = frame(440);
      final la5 = frame(880);
      final notes = <String>[];
      for (final f in [la4, la4, la4, la4, la5, la5, la4, la4, la4]) {
        now = now.add(const Duration(milliseconds: 23));
        notes.add(stabilizer.process(f, now).note.fullLabel);
      }
      expect(notes.toSet(), {'LA4'});
    });

    test('a jump that is not an octave is still immediate', () {
      final stabilizer = PitchStabilizer();
      var now = DateTime(2026, 10, 20, 9);
      final pipeline = Pipeline()
        ..feed(synth(const [Segment(440, 0.3, vibratoCents: 0, jitter: 0)]));
      for (final r in pipeline.raw) {
        now = now.add(const Duration(milliseconds: 23));
        stabilizer.process(r, now);
      }
      final fifth = Pipeline()
        ..feed(synth(const [Segment(659.3, 0.3, vibratoCents: 0, jitter: 0)]));
      // Due frame: la mediana su tre scarta un frame isolato, ma un salto di
      // una quinta non aspetta la conferma riservata alle ottave.
      now = now.add(const Duration(milliseconds: 23));
      stabilizer.process(fifth.raw.last, now);
      now = now.add(const Duration(milliseconds: 23));
      expect(stabilizer.process(fifth.raw.last, now).note.fullLabel, 'MI5');
    });

    test('8. vibrato, noise, amplitude changes, attacks and short gaps stay steady', () {
      final pipeline = Pipeline()
        ..feed(synth(const [
          Segment(440, 0.5, vibratoCents: 80, jitter: 0.015, shimmer: 0.3, noise: 0.03),
          Segment.rest(0.04),
          Segment(440, 0.5, vibratoCents: 60, amplitude: 0.08, attackMs: 80, noise: 0.02),
          Segment.rest(0.05),
          Segment(440, 0.5, harmonics: [0.4, 1.0, 0.5], jitter: 0.02, amplitude: 0.4),
        ]));
      final stable = [
        for (final r in pipeline.validated.skip(3))
          if (r.isStable) r,
      ];
      // Nessun errore d'ottava; il vibrato largo può sfiorare per un attimo
      // il semitono vicino, mai di più.
      expect(octaveErrors(pipeline.raw, 440), 0);
      expect(octaveErrors(stable, 440), 0);
      expect(stable.every((r) => centsBetween(r.frequency, 440).abs() < 100), isTrue);
      // Le brevi pause non diventano note né cancellano la nota.
      expect(stable.length, greaterThan(pipeline.validated.length * 0.8));
    });
  });

  group('extreme notes from validated frames', () {
    ExtremeNotesResult extremes(List<Segment> segments) {
      final pipeline = Pipeline()..feed(synth(segments));
      final tracker = ExtremeNotesTracker();
      pipeline.validated.forEach(tracker.add);
      return tracker.result();
    }

    test('6. an isolated octave error does not become the highest or lowest note', () {
      final stabilizer = PitchStabilizer();
      final tracker = ExtremeNotesTracker();
      var now = DateTime(2026, 10, 20, 9);
      final la4 = Pipeline()
          .analyzer
          .addSamples(synth(const [
            Segment(440, 0.1, harmonics: [1.0], vibratoCents: 0, jitter: 0)
          ]))
          .last;
      final la5 = Pipeline()
          .analyzer
          .addSamples(synth(const [
            Segment(880, 0.1, harmonics: [1.0], vibratoCents: 0, jitter: 0)
          ]))
          .last;
      final la3 = Pipeline()
          .analyzer
          .addSamples(synth(const [
            Segment(220, 0.1, harmonics: [1.0], vibratoCents: 0, jitter: 0)
          ]))
          .last;
      for (var i = 0; i < 80; i++) {
        now = now.add(const Duration(milliseconds: 23));
        // Due frame consecutivi un'ottava sopra e poi sotto, due volte.
        final frame = (i == 20 || i == 21)
            ? la5
            : (i == 50 || i == 51)
                ? la3
                : la4;
        tracker.add(stabilizer.process(frame, now));
      }
      final result = tracker.result();
      expect((result.lowest, result.highest), (69, 69));
    });

    test('7. a real extreme note, even short, is kept', () {
      final result = extremes(const [
        Segment(440, 1.0),
        Segment(880, 0.35, attackMs: 0),
        Segment(440, 0.5, attackMs: 0),
        Segment(220, 0.35, attackMs: 0),
      ]);
      expect((result.lowest, result.highest), (57, 81));
    });

    test('10. uncertain frames do not produce arbitrary extremes', () {
      // Voce con fondamentale debolissima e rumore: l'ottava è ambigua.
      final ambiguous = extremes(const [
        Segment(440, 2.0, harmonics: [0.12, 1.0], noise: 0.08, jitter: 0.02),
      ]);
      expect(ambiguous.highest == null || ambiguous.highest! <= 69, isTrue,
          reason: 'nessun LA5 inventato');
      // Frame incerti alternati a silenzio: nessuna nota.
      final tracker = ExtremeNotesTracker();
      final stabilizer = PitchStabilizer();
      var now = DateTime(2026, 10, 20, 9);
      for (var i = 0; i < 60; i++) {
        now = now.add(const Duration(milliseconds: 23));
        tracker.add(stabilizer.process(
            i.isEven ? PitchDetectionResult.uncertainFrame : PitchDetectionResult.silence, now));
      }
      expect(tracker.result().isEmpty, isTrue);
    });
  });
}
