import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/exercise.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/features/access/domain/charge_ledger.dart';
import 'package:vocal_scale_trainer/features/access/domain/entitlement.dart';
import 'package:vocal_scale_trainer/features/library/application/exercise_providers.dart';
import 'package:vocal_scale_trainer/features/range/application/range_test_controller.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/training_settings.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/controllers/trainer_controller.dart';
import 'package:vocal_scale_trainer/features/tuner/application/tuner_controller.dart';
import 'package:vocal_scale_trainer/services/audio/piano_audio_service.dart';
import 'package:vocal_scale_trainer/services/storage/custom_exercise_repository.dart';

import 'support/access_fakes.dart';
import 'support/audio_fakes.dart';

class _MemoryCustomRepository extends CustomExerciseRepository {
  _MemoryCustomRepository(this.items);

  List<ExerciseDefinition> items;

  @override
  Future<List<ExerciseDefinition>> load() async => items;

  @override
  Future<void> save(List<ExerciseDefinition> exercises) async => items = exercises;
}

const _saved = ExerciseDefinition(
  id: 'custom_1',
  name: 'Vocalizzo salvato',
  category: ExerciseCategory.custom,
  steps: [0, 2, 4],
  isCustom: true,
  rootMidi: 60,
);

class _Harness {
  _Harness({
    Entitlement entitlement = Entitlement.free,
    ChargeLedger? stored,
    FakeClock? clock,
    InMemoryChargesRepository? repository,
    bool micPermission = true,
  })  : clock = clock ?? FakeClock(),
        charges = repository ?? InMemoryChargesRepository(stored),
        mic = FakeMicrophonePitchService(permissionGranted: micPermission),
        customs = _MemoryCustomRepository([_saved]) {
    container = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(this.clock.call),
      chargesRepositoryProvider.overrideWithValue(charges),
      entitlementSourceProvider.overrideWithValue(FixedEntitlementSource(entitlement)),
      microphonePitchServiceProvider.overrideWithValue(mic),
      pianoAudioServiceProvider.overrideWithValue(PianoAudioService(midiPro: FakeMidiPro())),
      customExerciseRepositoryProvider.overrideWithValue(customs),
    ]);
  }

  final FakeClock clock;
  final InMemoryChargesRepository charges;
  final FakeMicrophonePitchService mic;
  final _MemoryCustomRepository customs;
  late final ProviderContainer container;

  TrainerController get trainer => container.read(trainerControllerProvider.notifier);

  Future<int> chargesLeft() async =>
      (await container.read(chargesProvider.notifier).refresh()).charges;

  void dispose() => container.dispose();
}

void main() {
  test('first launch: 7 charges', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    expect(await h.chargesLeft(), 7);
  });

  test('opening an exercise and changing its parameters does not consume charges', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.trainer.selectExercise(const ExerciseLibrary().builtIn.first);
    h.trainer
      ..updateKey(PitchClass.d)
      ..updateOctave(3)
      ..updateBpm(90)
      ..updateTolerance(30)
      ..updateMode(TrainerMode.train);
    expect(await h.chargesLeft(), 7);
    expect(h.charges.saves, 0);
  });

  test('each started session consumes exactly one charge; repeating consumes another', () async {
    final h = _Harness();
    addTearDown(h.dispose);

    expect(await h.trainer.play(), isTrue);
    expect(h.mic.isRecording, isTrue);
    expect(await h.chargesLeft(), 6);

    await h.trainer.stop();
    expect(await h.chargesLeft(), 6, reason: 'fermare non consuma');

    // Ripetere, o ripartire dopo aver cambiato tonalità, è una nuova sessione.
    expect(await h.trainer.replay(), isTrue);
    await h.trainer.stop();
    h.trainer.updateKey(PitchClass.e);
    expect(await h.trainer.play(), isTrue);
    await h.trainer.stop();
    expect(await h.chargesLeft(), 4);
  });

  test('a double tap starts one session and consumes one charge', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final first = h.trainer.play();
    final second = h.trainer.play();
    await Future.wait([first, second]);
    expect(await h.chargesLeft(), 6);
    await h.trainer.stop();
  });

  test('a technical failure before the session starts keeps the charge', () async {
    final h = _Harness(micPermission: false);
    addTearDown(h.dispose);
    await h.trainer.play();
    expect(h.container.read(trainerControllerProvider).isPlaying, isFalse);
    expect(await h.chargesLeft(), 7);
  });

  test('listening to the sequence does not consume charges', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.trainer
      ..updateMode(TrainerMode.listen)
      ..updateBpm(140);
    unawaited(h.trainer.play());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await h.trainer.stop();
    await h.trainer.listenNote(0);
    expect(await h.chargesLeft(), 7);
  });

  test('with no charges the session does not start', () async {
    final h = _Harness(stored: ChargeLedger(charges: 0, regenStartedAt: DateTime(2026, 10, 14, 8)));
    addTearDown(h.dispose);
    expect(await h.trainer.play(), isFalse);
    expect(h.mic.startCalls, 0);
    expect(h.container.read(trainerControllerProvider).isPlaying, isFalse);
    expect(h.container.read(exerciseAccessProvider).canStartSession, isFalse);

    // Dopo 3 ore (anche ad app chiusa) è maturata una carica.
    h.clock.advance(const Duration(hours: 2));
    expect(await h.trainer.play(), isTrue);
    expect(await h.chargesLeft(), 0);
  });

  test('regeneration continues while the app is closed and persists across restarts', () async {
    final clock = FakeClock();
    final repository = InMemoryChargesRepository();
    final first = _Harness(clock: clock, repository: repository);
    for (var i = 0; i < 3; i++) {
      await first.trainer.play();
      await first.trainer.stop();
    }
    expect(await first.chargesLeft(), 4);
    first.dispose();

    // App chiusa per 7 ore: alla riapertura 2 cariche maturate (4 + 2).
    clock.advance(const Duration(hours: 7));
    final second = _Harness(clock: clock, repository: repository);
    addTearDown(second.dispose);
    expect(await second.chargesLeft(), 6);
    expect(second.container.read(chargesProvider).timeToNext(clock.now), const Duration(hours: 2),
        reason: "l'ora già maturata si conserva");

    // Un giorno dopo: piene, senza superare il limite.
    clock.advance(const Duration(days: 1));
    expect(await second.chargesLeft(), ChargeLedger.max);
  });

  test('Pro: unlimited exercises, charges never consumed', () async {
    final h = _Harness(
      entitlement: const Entitlement(plan: Plan.pro),
      stored: const ChargeLedger(charges: 0),
    );
    addTearDown(h.dispose);
    for (var i = 0; i < 10; i++) {
      expect(await h.trainer.play(), isTrue);
      await h.trainer.stop();
    }
    expect(h.charges.saves, 0);
    expect(h.container.read(exerciseAccessProvider).canStartSession, isTrue);
  });

  test('real-time recognition and range test stay free with no charges', () async {
    final h = _Harness(stored: ChargeLedger(charges: 0, regenStartedAt: DateTime(2026, 10, 14, 8)));
    addTearDown(h.dispose);

    await h.container.read(tunerControllerProvider.notifier).start();
    expect(h.container.read(tunerControllerProvider).active, isTrue);
    await h.container.read(tunerControllerProvider.notifier).stop();

    final sub = h.container.listen(rangeTestControllerProvider, (previous, next) {});
    addTearDown(sub.close);
    await h.container.read(rangeTestControllerProvider.notifier).start();
    expect(h.container.read(rangeTestControllerProvider).phase, RangePhase.findingStart);
    expect(h.mic.isRecording, isTrue);
    await h.container.read(rangeTestControllerProvider.notifier).cancel();

    expect(await h.chargesLeft(), 0);
    expect(h.charges.saves, 0);
  });

  group('custom sequences', () {
    const created = ExerciseDefinition(
      id: 'custom_2',
      name: 'Nuova',
      category: ExerciseCategory.custom,
      steps: [0, 7],
      isCustom: true,
      rootMidi: 60,
    );

    test('Free: cannot create or edit, existing sequences are kept and playable', () async {
      final h = _Harness();
      addTearDown(h.dispose);
      final notifier = h.container.read(customExercisesProvider.notifier);
      await h.container.read(customExercisesProvider.future);

      expect(await notifier.upsert(created), isFalse);
      expect(await notifier.upsert(_saved.copyWithName('Rinominata')), isFalse);
      expect(h.customs.items.map((e) => e.name), ['Vocalizzo salvato']);

      // La sequenza già salvata si può allenare (con una carica).
      await h.trainer.selectExercise(_saved);
      expect(await h.trainer.play(), isTrue);
      expect(await h.chargesLeft(), 6);
    });

    test('Pro: can create and edit', () async {
      final h = _Harness(entitlement: const Entitlement(plan: Plan.pro));
      addTearDown(h.dispose);
      final notifier = h.container.read(customExercisesProvider.notifier);
      await h.container.read(customExercisesProvider.future);
      expect(await notifier.upsert(created), isTrue);
      expect(h.customs.items.map((e) => e.id), ['custom_1', 'custom_2']);
    });
  });
}

extension on ExerciseDefinition {
  ExerciseDefinition copyWithName(String name) => ExerciseDefinition(
        id: id,
        name: name,
        category: category,
        steps: steps,
        isCustom: isCustom,
        rootMidi: rootMidi,
      );
}
