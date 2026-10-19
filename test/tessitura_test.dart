import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_detection_result.dart';
import 'package:vocal_scale_trainer/core/session/range_record.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/features/range/application/range_providers.dart';
import 'package:vocal_scale_trainer/features/settings/application/settings_providers.dart';
import 'package:vocal_scale_trainer/features/tessitura/application/tessitura_providers.dart';
import 'package:vocal_scale_trainer/features/tessitura/application/tessitura_test_controller.dart';
import 'package:vocal_scale_trainer/features/tessitura/domain/tessitura.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/controllers/trainer_controller.dart';
import 'package:vocal_scale_trainer/services/audio/piano_audio_service.dart';
import 'package:vocal_scale_trainer/services/storage/json_list_repository.dart';
import 'package:vocal_scale_trainer/services/storage/range_history_repository.dart';

import 'support/access_fakes.dart';
import 'support/audio_fakes.dart';

double _freq(double midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

/// Frame ogni 23 ms per [ms] millisecondi con l'altezza data da [midiAt].
List<PitchFrame> _frames(int ms, double Function(int t) midiAt,
    {bool Function(int t)? voicedAt, double confidence = 0.95}) {
  return [
    for (var t = 0; t < ms; t += 23)
      PitchFrame(
        atMs: t,
        frequency: (voicedAt?.call(t) ?? true) ? _freq(midiAt(t)) : 0,
        confidence: (voicedAt?.call(t) ?? true) ? confidence : 0,
        voiced: voicedAt?.call(t) ?? true,
      ),
  ];
}

/// Prova sintetica per la stima (le misure contano solo per "raggiunta").
TessituraAttempt _a(
  TessituraStage stage,
  int midi,
  AttemptOutcome outcome, {
  int direction = 0,
  EffortRating? effort,
  bool register = false,
  bool strain = false,
  bool reached = true,
}) {
  return TessituraAttempt(
    stage: stage,
    targetMidi: midi,
    outcome: outcome,
    direction: direction,
    effort: effort,
    registerShift: register,
    strain: strain,
    measure: AttemptMeasure(
      voicedMs: outcome == AttemptOutcome.invalid ? 100 : 2500,
      meanConfidence: 0.9,
      anomalyRatio: 0,
      spreadCents: 10,
      reached: reached && outcome != AttemptOutcome.invalid,
      holdMs: outcome == AttemptOutcome.success ? 2500 : 400,
    ),
  );
}

const _ok = AttemptOutcome.success;
const _ko = AttemptOutcome.failed;
const _invalid = AttemptOutcome.invalid;

/// Sessione completa e coerente: calibrazione su [center], esplorazione
/// (riuscite fino a [top]/[bottom], poi due note difficili), tenute e
/// ripetizioni facili ai bordi.
List<TessituraAttempt> _session({
  int center = 57,
  int top = 66,
  int bottom = 48,
  Map<int, EffortRating> holdEffort = const {},
  Map<int, List<AttemptOutcome>> repeats = const {},
  Map<int, EffortRating> repeatEffort = const {},
}) {
  final hiHold = top - 2;
  final loHold = bottom + 2;
  return [
    _a(TessituraStage.calibration, center, _ok),
    for (var n = center + 1; n <= top; n++) _a(TessituraStage.explore, n, _ok, direction: 1),
    for (final n in [top + 1, top + 1, top + 2, top + 2])
      _a(TessituraStage.explore, n, _ko, direction: 1),
    for (var n = center - 1; n >= bottom; n--) _a(TessituraStage.explore, n, _ok, direction: -1),
    for (final n in [bottom - 1, bottom - 1, bottom - 2, bottom - 2])
      _a(TessituraStage.explore, n, _ko, direction: -1),
    _a(TessituraStage.hold, center, _ok, effort: holdEffort[center] ?? EffortRating.veryEasy),
    _a(TessituraStage.hold, hiHold, _ok, effort: holdEffort[hiHold] ?? EffortRating.easy),
    _a(TessituraStage.hold, loHold, _ok, effort: holdEffort[loHold] ?? EffortRating.easy),
    for (final entry in (repeats.isEmpty
            ? {
                hiHold + 1: [_ok, _ok, _ok],
                loHold - 1: [_ok, _ok, _ok],
              }
            : repeats)
        .entries)
      for (final (i, outcome) in entry.value.indexed)
        _a(TessituraStage.repeat, entry.key, outcome,
            effort:
                i == entry.value.length - 1 ? repeatEffort[entry.key] ?? EffortRating.easy : null),
  ];
}

class _MemoryRanges extends RangeHistoryRepository {
  _MemoryRanges(this.items);
  final List<RangeRecord> items;
  @override
  Future<List<RangeRecord>> load() async => items;
  @override
  Future<void> save(List<RangeRecord> records) async {}
}

class _MemoryTessitura extends JsonListRepository<TessituraRecord> {
  _MemoryTessitura()
      : super(
          fileName: 'unused.json',
          fromJson: TessituraRecord.fromJson,
          toJson: (record) => record.toJson(),
        );
  List<TessituraRecord> saved = [];
  @override
  Future<List<TessituraRecord>> load() async => saved;
  @override
  Future<void> save(List<TessituraRecord> items) async => saved = List.of(items);
}

void main() {
  group('AttemptMeasure: what the detector data can tell', () {
    test('a steady note held for 3 seconds is a valid, successful trial', () {
      final measure = AttemptMeasure.analyze(_frames(3000, (t) => 60.05), 60);
      expect(measure.reached, isTrue);
      expect(measure.holdMs, greaterThan(2900));
      expect(measure.medianCents!.abs(), lessThan(10));
      expect(measure.classify(const Duration(seconds: 3)), AttemptOutcome.success);
    });

    test('natural vibrato is not mistaken for instability', () {
      // ±60 cent a 5,5 Hz: oltre la tolleranza per brevi istanti a ogni ciclo.
      final vibrato = AttemptMeasure.analyze(
          _frames(3000, (t) => 60 + 0.6 * math.sin(2 * math.pi * 5.5 * t / 1000)), 60);
      expect(vibrato.driftCents, lessThan(25));
      expect(vibrato.classify(const Duration(seconds: 3)), AttemptOutcome.success);
      // Una deriva lenta di oltre mezzo semitono invece sì.
      final drifting = AttemptMeasure.analyze(_frames(3000, (t) => 59.7 + 0.6 * t / 3000), 60);
      expect(drifting.classify(const Duration(seconds: 3)), AttemptOutcome.failed);
    });

    test('too little signal, octave errors or speech-like pitch are not valid trials', () {
      // Quasi solo silenzio: non valutabile, non "non riuscita".
      final weak = AttemptMeasure.analyze(_frames(3000, (t) => 60, voicedAt: (t) => t < 300), 60);
      expect(weak.classify(const Duration(seconds: 3)), AttemptOutcome.invalid);
      // Metà dei frame un'ottava sopra (errore d'ottava del rilevatore).
      final octave = AttemptMeasure.analyze(_frames(3000, (t) => (t ~/ 23).isEven ? 60 : 72), 60);
      expect(octave.anomalyRatio, greaterThan(0.3));
      expect(octave.classify(const Duration(seconds: 3)), AttemptOutcome.invalid);
      // Altezza che salta di continuo (parlato, rumore).
      final speech =
          AttemptMeasure.analyze(_frames(3000, (t) => 55 + ((t * 7919) % 1300) / 100), 60);
      expect(speech.classify(const Duration(seconds: 3)), AttemptOutcome.invalid);
    });

    test('a clean signal on another note is a valid trial that did not succeed', () {
      final measure = AttemptMeasure.analyze(_frames(3000, (t) => 58), 60);
      expect(measure.sungMidi, 58);
      expect(measure.classify(const Duration(seconds: 3)), AttemptOutcome.failed);
    });

    test('a short hold of a long note does not succeed', () {
      final measure = AttemptMeasure.analyze(_frames(2000, (t) => 60), 60);
      expect(measure.classify(const Duration(seconds: 6)), AttemptOutcome.failed);
    });
  });

  group('TessituraPlanner', () {
    final planner = TessituraPlanner(centerMidi: 57, lowMidi: 45, highMidi: 72);

    TessituraStep step(List<TessituraAttempt> attempts) => planner.next(attempts).step!;

    test('calibrates first, retries an unheard note and recenters on the natural note', () {
      expect(step(const []).stage, TessituraStage.calibration);
      expect(step(const []).midi, 57);
      final notHeard = step([_a(TessituraStage.calibration, 57, _invalid)]);
      expect(notHeard.midi, 57);
      expect(notHeard.cue, TessituraCue.notHeard);
      final sungLower = TessituraAttempt(
        stage: TessituraStage.calibration,
        targetMidi: 57,
        outcome: _ko,
        measure: AttemptMeasure.analyze(_frames(3000, (t) => 54), 57),
      );
      final recenter = step([sungLower, sungLower]);
      expect(recenter.cue, TessituraCue.recenter);
      expect(recenter.midi, 54);
      expect(
          planner.next(
              [for (var i = 0; i < 4; i++) _a(TessituraStage.calibration, 57, _invalid)]).kind,
          PlanKind.cannotCalibrate);
    });

    test('explores by semitones, repeats a difficult note and tolerates an isolated error', () {
      final calibrated = [_a(TessituraStage.calibration, 57, _ok)];
      var next = step(calibrated);
      expect((next.stage, next.midi, next.cue), (TessituraStage.explore, 58, TessituraCue.stepUp));
      final up = [
        ...calibrated,
        _a(TessituraStage.explore, 58, _ok, direction: 1),
        _a(TessituraStage.explore, 59, _ko, direction: 1),
      ];
      next = step(up);
      expect((next.midi, next.cue), (59, TessituraCue.retry),
          reason: 'si ripete prima di decidere');
      up.add(_a(TessituraStage.explore, 59, _ko, direction: 1));
      expect(step(up).midi, 60, reason: 'un solo errore non ferma la salita');
      up.add(_a(TessituraStage.explore, 60, _ok, direction: 1));
      expect(step(up).midi, 61);
      // Due note difficili di fila: si torna a note comode e si scende.
      up.addAll([
        for (final n in [61, 61, 62, 62]) _a(TessituraStage.explore, n, _ko, direction: 1),
      ]);
      next = step(up);
      expect((next.midi, next.direction, next.cue), (56, -1, TessituraCue.backToComfort));
    });

    test('an unheard note is not a difficulty, and strain ends the direction at once', () {
      final attempts = [
        _a(TessituraStage.calibration, 57, _ok),
        _a(TessituraStage.explore, 58, _invalid, direction: 1),
      ];
      expect(step(attempts).cue, TessituraCue.notHeard);
      attempts.add(_a(TessituraStage.explore, 58, _invalid, direction: 1));
      expect(step(attempts).midi, 59, reason: 'non valutabile: si prosegue');
      attempts.add(TessituraAttempt(
        stage: TessituraStage.explore,
        targetMidi: 59,
        direction: 1,
        outcome: AttemptOutcome.interrupted,
        effort: EffortRating.veryHard,
        strain: true,
      ));
      expect(step(attempts).direction, -1, reason: 'sforzo eccessivo: niente più acuti');
    });

    test('then holds, repeats near the edges, offers the melodic check and finishes', () {
      final explored =
          _session().where((a) => a.stage.index <= TessituraStage.explore.index).toList();
      var next = step(explored);
      expect((next.stage, next.midi, next.askEffort), (TessituraStage.hold, 57, true));
      expect(TessituraPlanner.holdNotes(57, 66, 48), [57, 64, 50]);
      final full = _session();
      expect(planner.next(full).kind, PlanKind.offerMelodic);
      // Tenuta facile al bordo: la ripetizione prova un semitono più in fuori.
      expect(planner.repeatNotes(full, 57, 66, 48), [65, 49]);
      final hardHold = _session(holdEffort: {64: EffortRating.moderate});
      expect(planner.repeatNotes(hardHold, 57, 66, 48), [63, 49]);
      // Verifica melodica: 9 note dentro la zona, poi fine.
      final phrase = planner.melodicPhrase(full);
      expect(phrase, hasLength(9));
      expect(phrase.reduce(math.min), greaterThanOrEqualTo(49));
      expect(phrase.reduce(math.max), lessThanOrEqualTo(65));
      expect(planner.next(full, melodic: true).step!.stage, TessituraStage.melodic);
      expect(planner.next(full, melodic: false).kind, PlanKind.finished);
    });
  });

  group('TessituraEstimate', () {
    test('1/8. stable, repeatable low and high notes: zone, usable and observed range differ', () {
      final estimate = TessituraEstimate.from(_session());
      expect((estimate.comfortLow, estimate.comfortHigh), (49, 65));
      expect((estimate.usableLow, estimate.usableHigh), (49, 65));
      // L'estensione osservata include le note raggiunte solo di sfuggita.
      expect((estimate.observedLow, estimate.observedHigh), (46, 68));
      expect(estimate.reliability, TessituraReliability.high);
    });

    test('2. an extreme note reached only once stays out of the usable range', () {
      final estimate = TessituraEstimate.from(_session(top: 66));
      expect(estimate.toVerify, contains(66));
      expect(estimate.usableHigh, 65);
      expect(estimate.observedHigh, greaterThanOrEqualTo(66));
    });

    test('3. detection problems are not failures, but lower the reliability', () {
      final attempts = [
        ..._session(),
        for (var i = 0; i < 30; i++) _a(TessituraStage.explore, 60, _invalid, direction: 1),
      ];
      final estimate = TessituraEstimate.from(attempts);
      expect(estimate.evidence[60]!.failures, 0);
      expect(estimate.zones[60], NoteZone.comfortable);
      expect(estimate.invalidRatio, greaterThan(0.4));
      expect(estimate.reliability, TessituraReliability.low);
    });

    test('4. one failed note among many good ones does not shrink the zone', () {
      final attempts = [
        for (final a in _session())
          if (a.stage == TessituraStage.explore && a.targetMidi == 61)
            _a(TessituraStage.explore, 61, _ko, direction: 1)
          else
            a,
      ];
      final estimate = TessituraEstimate.from(attempts);
      expect((estimate.comfortLow, estimate.comfortHigh), (49, 65));
      expect(estimate.toVerify, contains(61));
    });

    test('5. a stable note sung with high effort is not comfortable', () {
      final estimate = TessituraEstimate.from(_session(
        holdEffort: {64: EffortRating.hard},
        repeats: {
          63: [_ok, _ok, _ok],
          49: [_ok, _ok, _ok]
        },
      ));
      expect(estimate.comfortHigh, lessThan(64));
      expect(estimate.zones[64], NoteZone.outside);
      expect(estimate.usableHigh, greaterThanOrEqualTo(64), reason: 'resta utilizzabile');
    });

    test('6. a note sustained well but not reproducible is to verify, not an edge', () {
      final estimate = TessituraEstimate.from(_session(
        repeats: {
          65: [_ok, _ko, _ko],
          49: [_ok, _ok, _ok]
        },
      ));
      expect(estimate.toVerify, contains(65));
      expect(estimate.comfortHigh, 64);
    });

    test('7. too little data gives an insufficient estimate, not an invented zone', () {
      final estimate = TessituraEstimate.from([
        _a(TessituraStage.calibration, 57, _ok),
        _a(TessituraStage.explore, 58, _ok, direction: 1),
        _a(TessituraStage.explore, 59, _ok, direction: 1),
      ]);
      expect(estimate.hasZone, isFalse);
      expect(estimate.reliability, TessituraReliability.insufficient);
      expect(estimate.observedLow, 57);
      expect(estimate.usableLow, isNotNull);
    });

    test('a missing effort answer is not taken as comfort', () {
      final attempts = [
        for (final a in _session()) a.effort == null ? a : a.withEffort(null),
      ];
      expect(TessituraEstimate.from(attempts).hasZone, isFalse);
    });

    test('9. a reported register change is flagged, kept in the range, never a zone edge', () {
      final attempts = [
        for (final a in _session())
          a.targetMidi == 65
              ? _a(a.stage, 65, a.outcome, direction: a.direction, effort: a.effort, register: true)
              : a,
      ];
      final estimate = TessituraEstimate.from(attempts);
      expect(estimate.registerNotes, [65]);
      expect(estimate.toVerify, contains(65));
      expect(estimate.comfortHigh, 64);
      expect(estimate.observedHigh, 68);
    });

    test('reliability measures the data, not the width of the zone', () {
      // Zona stretta ma ben verificata: attendibile.
      final narrow = TessituraEstimate.from(_session(top: 61, bottom: 53));
      expect(narrow.comfortHigh! - narrow.comfortLow!, lessThan(8));
      expect(narrow.reliability, isNot(TessituraReliability.low));
      // Zona ampia ma con molte prove non valutabili: poco attendibile.
      final wide = TessituraEstimate.from([
        ..._session(),
        for (var i = 0; i < 40; i++) _a(TessituraStage.explore, 70, _invalid, direction: 1),
      ]);
      expect(wide.comfortHigh! - wide.comfortLow!, greaterThan(15));
      expect(wide.reliability, TessituraReliability.low);
    });
  });

  group('TessituraRecord', () {
    test('round trip, and older records without the new fields still load', () {
      final record = TessituraRecord.fromEstimate(
        timestamp: DateTime(2026, 10, 12, 18),
        estimate: TessituraEstimate.from(_session()),
      );
      final back = TessituraRecord.fromJson(record.toJson());
      expect(back.comfortLow, record.comfortLow);
      expect(back.usableHigh, record.usableHigh);
      expect(back.reliability, record.reliability);
      expect(back.toVerify, record.toVerify);

      final legacy = TessituraRecord.fromJson({
        'timestamp': '2026-10-01T09:00:00.000',
        'comfortLow': 50,
        'comfortHigh': 60,
        'rangeLow': 45,
        'rangeHigh': 69,
        'toVerify': [62],
        'reliability': 'medium',
        'provisional': false,
        'trials': 8,
      });
      expect(legacy.hasZone, isTrue);
      expect(legacy.hasUsable, isFalse);
      expect(legacy.registerNotes, isEmpty);
      expect(legacy.signalIssues, isFalse);
      expect(TessituraRecord.fromJson({'timestamp': '2026-10-01T09:00:00.000'}).reliability,
          TessituraReliability.low);
    });
  });

  group('TessituraTestController', () {
    late FakeMicrophonePitchService mic;
    late FakeMidiPro midi;
    late _MemoryTessitura store;
    late DateTime now;
    late ProviderContainer container;

    ProviderContainer create({List<RangeRecord> ranges = const []}) {
      mic = FakeMicrophonePitchService();
      midi = FakeMidiPro();
      store = _MemoryTessitura();
      now = DateTime(2026, 10, 19, 9);
      final c = ProviderContainer(overrides: [
        microphonePitchServiceProvider.overrideWithValue(mic),
        pianoAudioServiceProvider.overrideWithValue(PianoAudioService(midiPro: midi)),
        chargesRepositoryProvider.overrideWithValue(InMemoryChargesRepository()),
        deviceLocaleProvider.overrideWithValue(const Locale('it')),
        rangeHistoryRepositoryProvider.overrideWithValue(_MemoryRanges(ranges)),
        tessituraRepositoryProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    TessituraTestState read() => container.read(tessituraTestControllerProvider);
    TessituraTestController controller() =>
        container.read(tessituraTestControllerProvider.notifier);

    Future<void> frames(Duration duration, PitchDetectionResult Function() frame) async {
      for (var t = 0; t < duration.inMilliseconds; t += 25) {
        now = now.add(const Duration(milliseconds: 25));
        mic.emit(frame());
        await Future<void>.delayed(Duration.zero);
      }
    }

    Future<void> sing(int note, Duration duration) => frames(duration, () {
          final n = MusicalNote.fromMidi(note);
          return PitchDetectionResult(
              frequency: n.frequency, note: n, cents: 0, confidence: 0.95, isStable: true);
        });

    Future<void> silence(Duration duration) => frames(duration, () => PitchDetectionResult.silence);

    /// Pausa e nota guida, poi la nota della prova in corso per [duration].
    Future<void> singCurrent([Duration duration = const Duration(milliseconds: 3200)]) async {
      await silence(const Duration(milliseconds: 1900));
      expect(read().attemptStep, AttemptStep.waiting);
      await sing(read().targetMidi!, duration);
    }

    Future<void> startWithRange() async {
      container = create(ranges: [
        RangeRecord(timestamp: DateTime(2026, 10, 1), minMidi: 48, maxMidi: 72),
      ]);
      await container.read(rangeHistoryProvider.future);
      final sub = container.listen(tessituraTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      await controller().start();
    }

    test('calibration plays the reference note, then exploration goes up by a semitone', () async {
      await startWithRange();
      var state = read();
      expect(state.phase, TessituraPhase.attempt);
      // Centro al 40% dell'estensione (DO3–DO5): 58.
      expect((state.step!.stage, state.targetMidi), (TessituraStage.calibration, 58));
      await silence(const Duration(milliseconds: 800));
      expect(read().attemptStep, AttemptStep.guide);
      await Future<void>.delayed(const Duration(milliseconds: 20)); // caricamento del piano
      expect(midi.played, contains(58), reason: 'nota di riferimento al piano');

      await singCurrent();
      state = read();
      expect(state.attempts.single.outcome, AttemptOutcome.success);
      expect((state.step!.stage, state.targetMidi, state.step!.cue),
          (TessituraStage.explore, 59, TessituraCue.stepUp));
    });

    test('silence after the reference is "not heard", never a failed note', () async {
      await startWithRange();
      await silence(const Duration(milliseconds: 1900) + TessituraTestController.voiceTimeout);
      final state = read();
      expect(state.attempts.single.outcome, AttemptOutcome.invalid);
      expect((state.targetMidi, state.step!.cue), (58, TessituraCue.notHeard));
    });

    test('effort is asked after a hold, can be skipped, and is stored with the trial', () async {
      await startWithRange();
      await singCurrent(); // calibrazione
      // Esplorazione: sale e poi scende finché le note non riescono.
      while (read().step!.stage == TessituraStage.explore) {
        final target = read().targetMidi!;
        if ((target - 58).abs() <= 1) {
          await singCurrent();
        } else {
          await silence(const Duration(milliseconds: 1900));
          await sing(target - 3, const Duration(milliseconds: 3200)); // nota sbagliata
        }
      }
      expect(read().step!.stage, TessituraStage.hold);
      await singCurrent(const Duration(milliseconds: 6200));
      expect(read().phase, TessituraPhase.rating);
      controller().rate(EffortRating.easy);
      final state = read();
      expect(state.attempts.last.stage, TessituraStage.hold);
      expect(state.attempts.last.effort, EffortRating.easy);
      expect(state.phase, TessituraPhase.attempt);
    });

    test('strain stops the direction and offers comfortable notes or the end', () async {
      await startWithRange();
      await singCurrent();
      expect(read().step!.direction, 1);
      controller().reportStrain();
      expect(read().phase, TessituraPhase.strainChoice);
      expect(read().attempts.last.strain, isTrue);
      controller().continueAfterStrain();
      final state = read();
      expect((state.step!.direction, state.step!.cue), (-1, TessituraCue.backToComfort));
    });

    test('a register change marked during a trial is stored with it', () async {
      await startWithRange();
      controller().toggleRegisterShift();
      await singCurrent();
      expect(read().attempts.single.registerShift, isTrue);
      expect(read().registerShift, isFalse, reason: 'la prova successiva riparte da zero');
    });

    test('10. finishing early saves an honest partial result; cancel saves nothing', () async {
      await startWithRange();
      await singCurrent();
      await controller().finish();
      var state = read();
      expect(state.phase, TessituraPhase.done);
      expect(state.record!.hasZone, isFalse);
      expect(state.record!.reliability, TessituraReliability.insufficient);
      expect(store.saved, hasLength(1));
      expect(mic.isRecording, isFalse);

      await controller().start();
      expect(mic.isRecording, isTrue);
      await controller().cancel();
      state = read();
      expect(state.phase, TessituraPhase.intro);
      expect(store.saved, hasLength(1), reason: 'annullato: niente di nuovo');
      expect(mic.isRecording, isFalse);
    });

    test('finishing with no valid trial saves nothing', () async {
      await startWithRange();
      await controller().finish();
      expect(read().phase, TessituraPhase.done);
      expect(read().record, isNull);
      expect(store.saved, isEmpty);
    });

    test('a microphone that stops mid-test ends it with the data collected', () async {
      await startWithRange();
      await singCurrent();
      mic.emitError(StateError('audio interrupted'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final state = read();
      expect(state.phase, TessituraPhase.done);
      expect(state.message, TessituraMessage.interrupted);
      expect(store.saved, hasLength(1));
      expect(mic.isRecording, isFalse);
    });

    test('without a range test it starts from a held comfortable note', () async {
      container = create();
      final sub = container.listen(tessituraTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      await controller().start();
      expect(read().phase, TessituraPhase.findingStart);
      await sing(57, TessituraTestController.startHold + const Duration(milliseconds: 200));
      expect((read().phase, read().targetMidi), (TessituraPhase.attempt, 57));
    });

    test('microphone denied or unavailable stays on the intro with a message', () async {
      container = create();
      mic.permissionGranted = false;
      final sub = container.listen(tessituraTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      await controller().start();
      expect((read().phase, read().message),
          (TessituraPhase.intro, TessituraMessage.microphoneDenied));
      mic
        ..permissionGranted = true
        ..startError = StateError('no audio');
      await controller().start();
      expect(read().message, TessituraMessage.audioUnavailable);
    });
  });

  test('history keeps previous results for comparison', () async {
    final store = _MemoryTessitura();
    final container = ProviderContainer(overrides: [
      tessituraRepositoryProvider.overrideWithValue(store),
    ]);
    addTearDown(container.dispose);
    final first = TessituraRecord.fromEstimate(
        timestamp: DateTime(2026, 10, 1), estimate: TessituraEstimate.from(_session()));
    final second = TessituraRecord.fromEstimate(
        timestamp: DateTime(2026, 10, 8), estimate: TessituraEstimate.from(_session(top: 64)));
    await container.read(tessituraHistoryProvider.notifier).add(first);
    await container.read(tessituraHistoryProvider.notifier).add(second);
    expect(store.saved.map((r) => r.timestamp), [first.timestamp, second.timestamp]);
  });
}
