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

/// Prova con tutte le note del frammento intonate (o tutte mancate).
TessituraTrial _trial(int root, ComfortRating? comfort,
    {bool validated = true, double cents = 0, double spread = 3}) {
  return TessituraTrial(
    rootMidi: root,
    comfort: comfort,
    measures: {
      for (final step in const [0, 2, 4])
        root + step: NoteMeasure(
          validated: validated,
          meanCents: cents,
          spreadCents: spread,
          sustainRatio: step == 0 ? (validated ? 0.9 : 0) : null,
        ),
    },
  );
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
  group('TessituraPlanner', () {
    final planner = TessituraPlanner(centerMidi: 60, lowMidi: 45, highMidi: 77);

    test('goes up while comfortable, then down, then repeats the edges', () {
      final trials = <TessituraTrial>[];
      int? next() => planner.next(trials);

      expect(next(), 58, reason: 'il centro sta nel mezzo del primo frammento');
      trials.add(_trial(58, ComfortRating.easy));
      expect(next(), 61);
      trials.add(_trial(61, ComfortRating.effort));
      expect(next(), 64);
      trials.add(_trial(64, ComfortRating.hard));
      // Salita finita: si scende dal primo frammento.
      expect(next(), 55);
      trials.add(_trial(55, ComfortRating.easy));
      expect(next(), 52);
      trials.add(_trial(52, null));
      // Verifica: prove comode più alta e più bassa.
      expect(next(), 61);
      trials.add(_trial(61, ComfortRating.easy));
      expect(next(), 55);
      trials.add(_trial(55, ComfortRating.easy));
      expect(next(), isNull);
    });

    test('stays within the known range and is capped', () {
      final narrow = TessituraPlanner(centerMidi: 60, lowMidi: 57, highMidi: 66);
      final trials = [_trial(58, ComfortRating.easy)];
      // Il frammento successivo (61–65) sta nell'estensione, quello dopo no.
      expect(narrow.next(trials), 61);
      trials.add(_trial(61, ComfortRating.easy));
      expect(narrow.next(trials), 61, reason: 'niente discesa sotto il limite: si verifica');

      final many =
          List.generate(TessituraPlanner.maxTrials, (i) => _trial(40 + i, ComfortRating.easy));
      expect(planner.next(many), isNull);
    });

    test('is deterministic', () {
      final trials = [_trial(58, ComfortRating.easy), _trial(61, ComfortRating.hard)];
      expect(planner.next(trials), planner.next(List.of(trials)));
    });
  });

  group('TessituraEstimate', () {
    test('comfortable notes form the zone; strained ones stay out', () {
      final estimate = TessituraEstimate.from([
        _trial(58, ComfortRating.easy),
        _trial(61, ComfortRating.easy),
        _trial(64, ComfortRating.hard),
        _trial(55, ComfortRating.easy),
        _trial(52, ComfortRating.hard),
        _trial(61, ComfortRating.easy),
        _trial(55, ComfortRating.easy),
      ]);
      expect(estimate.comfortLow, 55);
      // 61–65 cantato comodo due volte; 64 e 66 solo nel frammento difficile.
      expect(estimate.comfortHigh, 65);
      expect(estimate.zones[68], NoteZone.outside, reason: 'la nota più esterna del frammento');
      expect(estimate.toVerify, containsAll([56, 66]));
      expect(estimate.provisional, isFalse);
      expect(estimate.reliability, isNot(TessituraReliability.low));
    });

    test('perfect pitch is not enough: a note declared hard is not comfortable', () {
      final estimate = TessituraEstimate.from([
        _trial(58, ComfortRating.hard, cents: 0, spread: 0),
        _trial(58, ComfortRating.hard, cents: 0, spread: 0),
      ]);
      expect(estimate.comfortLow, isNull);
      expect(estimate.zones.values, isNot(contains(NoteZone.comfortable)));
      expect(estimate.provisional, isTrue);
    });

    test('a comfortable note sung badly is to verify, not comfortable', () {
      final estimate = TessituraEstimate.from([
        _trial(58, ComfortRating.effort, validated: false),
      ]);
      expect(estimate.zones[58], NoteZone.toVerify);
    });

    test('inconsistent repeats are marked to verify', () {
      final estimate = TessituraEstimate.from([
        _trial(58, ComfortRating.easy),
        _trial(61, ComfortRating.easy),
        _trial(61, null, validated: false),
      ]);
      expect(estimate.toVerify, containsAll([61, 63]));
      expect(estimate.zones[58], NoteZone.comfortable);
    });

    test('insufficient data gives a provisional estimate', () {
      final none = TessituraEstimate.from(const []);
      expect(none.comfortLow, isNull);
      expect(none.provisional, isTrue);
      expect(none.reliability, TessituraReliability.low);

      final one = TessituraEstimate.from([_trial(58, ComfortRating.easy)]);
      expect(one.comfortLow, 58);
      expect(one.comfortHigh, 62);
      expect(one.provisional, isTrue, reason: 'una sola prova');
    });
  });

  group('TessituraRecord', () {
    test('survives a JSON round trip and tolerates missing fields', () {
      final record = TessituraRecord(
        timestamp: DateTime(2026, 10, 19, 9, 30),
        comfortLow: 55,
        comfortHigh: 63,
        rangeLow: 45,
        rangeHigh: 77,
        toVerify: const [64],
        reliability: TessituraReliability.medium,
        provisional: false,
        trials: 7,
      );
      final copy = TessituraRecord.fromJson(record.toJson());
      expect(copy.timestamp, record.timestamp);
      expect(copy.comfortLow, 55);
      expect(copy.comfortHigh, 63);
      expect(copy.toVerify, [64]);
      expect(copy.reliability, TessituraReliability.medium);
      expect(copy.provisional, isFalse);

      final sparse = TessituraRecord.fromJson({'timestamp': '2026-10-01T10:00:00.000'});
      expect(sparse.hasZone, isFalse);
      expect(sparse.provisional, isTrue);
      expect(sparse.reliability, TessituraReliability.low);
    });
  });

  group('TessituraTestController', () {
    late FakeMicrophonePitchService mic;
    late _MemoryTessitura store;
    late DateTime now;
    late ProviderContainer container;

    ProviderContainer create({List<RangeRecord> ranges = const []}) {
      mic = FakeMicrophonePitchService();
      store = _MemoryTessitura();
      now = DateTime(2026, 10, 19, 9);
      final c = ProviderContainer(overrides: [
        microphonePitchServiceProvider.overrideWithValue(mic),
        pianoAudioServiceProvider.overrideWithValue(PianoAudioService(midiPro: FakeMidiPro())),
        chargesRepositoryProvider.overrideWithValue(InMemoryChargesRepository()),
        deviceLocaleProvider.overrideWithValue(const Locale('it')),
        rangeHistoryRepositoryProvider.overrideWithValue(_MemoryRanges(ranges)),
        tessituraRepositoryProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    /// Frame di [note] ogni 25 ms (orologio finto) per [duration].
    Future<void> sing(int midi, Duration duration) async {
      final note = MusicalNote.fromMidi(midi);
      for (var t = 0; t < duration.inMilliseconds; t += 25) {
        now = now.add(const Duration(milliseconds: 25));
        mic.emit(PitchDetectionResult(
          frequency: note.frequency,
          note: note,
          cents: 0,
          confidence: 1,
          isStable: true,
        ));
        await Future<void>.delayed(Duration.zero);
      }
    }

    Future<void> silence(Duration duration) async {
      for (var t = 0; t < duration.inMilliseconds; t += 25) {
        now = now.add(const Duration(milliseconds: 25));
        mic.emit(PitchDetectionResult.silence);
        await Future<void>.delayed(Duration.zero);
      }
    }

    /// Canta tutto il frammento in corso, nota per nota, e la tenuta finale.
    Future<void> singTrial() async {
      for (var i = 0; i < TessituraTrial.pattern.length; i++) {
        final target = container.read(tessituraTestControllerProvider).targetMidi!;
        await silence(const Duration(milliseconds: 1200)); // nota guida
        await sing(target, const Duration(milliseconds: 400));
      }
      await sing(container.read(tessituraTestControllerProvider).targetMidi!,
          TessituraTestController.sustainDuration + const Duration(milliseconds: 100));
    }

    test('with a range test: phrases, comfort question and a saved result', () async {
      container = create(ranges: [
        RangeRecord(timestamp: DateTime(2026, 10, 1), minMidi: 48, maxMidi: 72),
      ]);
      await container.read(rangeHistoryProvider.future);
      final sub = container.listen(tessituraTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      final controller = container.read(tessituraTestControllerProvider.notifier);
      expect(container.read(tessituraTestControllerProvider).hasRange, isTrue);

      await controller.start();
      var state = container.read(tessituraTestControllerProvider);
      expect(state.phase, TessituraPhase.singing);
      // Centro al 40% dell'estensione (DO3–DO5): 58, primo frammento da 56.
      expect(state.rootMidi, 56);

      await singTrial();
      state = container.read(tessituraTestControllerProvider);
      expect(state.phase, TessituraPhase.rating);

      await controller.rate(ComfortRating.easy);
      state = container.read(tessituraTestControllerProvider);
      expect(state.trials, hasLength(1));
      expect(state.trials.single.measures[56]!.validated, isTrue);
      expect(state.trials.single.measures[56]!.sustainRatio, greaterThan(0.8));
      expect(state.phase, TessituraPhase.singing);
      expect(state.rootMidi, 59, reason: 'prova comoda: si sale');

      // Interrotto dall'utente: risultato provvisorio salvato.
      await controller.finish();
      state = container.read(tessituraTestControllerProvider);
      expect(state.phase, TessituraPhase.done);
      expect(state.record!.provisional, isTrue);
      expect(store.saved, hasLength(1));
      expect(store.saved.single.rangeLow, 48);
      expect(mic.isRecording, isFalse);
    });

    test('a note not sung in time counts as missed and the phrase goes on', () async {
      container = create(ranges: [
        RangeRecord(timestamp: DateTime(2026, 10, 1), minMidi: 48, maxMidi: 72),
      ]);
      await container.read(rangeHistoryProvider.future);
      final sub = container.listen(tessituraTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      await container.read(tessituraTestControllerProvider.notifier).start();

      await silence(TessituraTestController.noteTimeout + const Duration(milliseconds: 100));
      final state = container.read(tessituraTestControllerProvider);
      expect(state.noteIndex, 1);
    });

    test('without a range test it starts from a held comfortable note', () async {
      container = create();
      final sub = container.listen(tessituraTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      final controller = container.read(tessituraTestControllerProvider.notifier);

      await controller.start();
      expect(container.read(tessituraTestControllerProvider).phase, TessituraPhase.findingStart);
      await sing(57, TessituraTestController.startHold + const Duration(milliseconds: 200));
      final state = container.read(tessituraTestControllerProvider);
      expect(state.phase, TessituraPhase.singing);
      expect(state.rootMidi, 55);
    });

    test('cancel saves nothing and releases the microphone', () async {
      container = create();
      final sub = container.listen(tessituraTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      final controller = container.read(tessituraTestControllerProvider.notifier);
      await controller.start();
      expect(mic.isRecording, isTrue);
      await controller.cancel();
      expect(container.read(tessituraTestControllerProvider).phase, TessituraPhase.intro);
      expect(store.saved, isEmpty);
      expect(mic.isRecording, isFalse);
    });

    test('finishing with no phrase saves nothing', () async {
      container = create();
      final sub = container.listen(tessituraTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      final controller = container.read(tessituraTestControllerProvider.notifier);
      await controller.start();
      await controller.finish();
      expect(container.read(tessituraTestControllerProvider).phase, TessituraPhase.intro);
      expect(store.saved, isEmpty);
    });

    test('microphone denied stays on the intro with a message', () async {
      container = create();
      mic.permissionGranted = false;
      final sub = container.listen(tessituraTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      await container.read(tessituraTestControllerProvider.notifier).start();
      final state = container.read(tessituraTestControllerProvider);
      expect(state.phase, TessituraPhase.intro);
      expect(state.message, TessituraMessage.microphoneDenied);
    });
  });

  test('history keeps previous results for comparison', () async {
    final store = _MemoryTessitura();
    final container = ProviderContainer(overrides: [
      tessituraRepositoryProvider.overrideWithValue(store),
    ]);
    addTearDown(container.dispose);
    final first = TessituraRecord.fromEstimate(
      timestamp: DateTime(2026, 10, 1),
      estimate: TessituraEstimate.from([_trial(58, ComfortRating.easy)]),
      rangeLow: null,
      rangeHigh: null,
    );
    final second = TessituraRecord.fromEstimate(
      timestamp: DateTime(2026, 10, 8),
      estimate:
          TessituraEstimate.from([_trial(58, ComfortRating.easy), _trial(61, ComfortRating.easy)]),
      rangeLow: null,
      rangeHigh: null,
    );
    await container.read(tessituraHistoryProvider.notifier).add(first);
    await container.read(tessituraHistoryProvider.notifier).add(second);
    expect(store.saved.map((r) => r.timestamp), [first.timestamp, second.timestamp]);
  });
}
