import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_detection_result.dart';
import 'package:vocal_scale_trainer/features/range/application/range_test_controller.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/training_settings.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/controllers/trainer_controller.dart';
import 'package:vocal_scale_trainer/features/tuner/application/tuner_controller.dart';
import 'package:vocal_scale_trainer/services/audio/piano_audio_service.dart';

import 'support/access_fakes.dart';
import 'support/audio_fakes.dart';

ProviderContainer _container(FakeMicrophonePitchService mic, FakeMidiPro midi) {
  return ProviderContainer(
    overrides: [
      microphonePitchServiceProvider.overrideWithValue(mic),
      pianoAudioServiceProvider.overrideWithValue(PianoAudioService(midiPro: midi)),
      chargesRepositoryProvider.overrideWithValue(InMemoryChargesRepository()),
    ],
  );
}

/// Canta [note] per [duration], con un frame ogni ~25 ms come il rilevatore.
Future<void> _sing(FakeMicrophonePitchService mic, MusicalNote note, Duration duration) async {
  final frames = duration.inMilliseconds ~/ 25;
  for (var i = 0; i < frames; i++) {
    mic.emit(PitchDetectionResult(
      frequency: note.frequency,
      note: note,
      cents: 0,
      confidence: 1,
      isStable: true,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

void main() {
  group('TunerController', () {
    test('disposing the container while listening releases the microphone', () async {
      final mic = FakeMicrophonePitchService();
      final container = _container(mic, FakeMidiPro());
      await container.read(tunerControllerProvider.notifier).start();
      expect(container.read(tunerControllerProvider).active, isTrue);

      // Prima della correzione: assertion "Cannot use Ref ... inside life-cycles".
      container.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(mic.isRecording, isFalse);
    });

    test('permission denied is reported instead of showing an active tuner', () async {
      final mic = FakeMicrophonePitchService(permissionGranted: false);
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);

      await container.read(tunerControllerProvider.notifier).start();

      final state = container.read(tunerControllerProvider);
      expect(state.active, isFalse);
      expect(state.permissionDenied, isTrue);
    });

    test('stop while start is pending leaves the microphone off', () async {
      final mic = FakeMicrophonePitchService()..startGate = Completer<void>();
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);
      final controller = container.read(tunerControllerProvider.notifier);

      final starting = controller.start();
      await controller.stop();
      mic.startGate!.complete();
      await starting;

      expect(container.read(tunerControllerProvider).active, isFalse);
      expect(mic.isRecording, isFalse);
    });
  });

  group('TrainerController', () {
    test('permission denied stops the run and shows a message', () async {
      final mic = FakeMicrophonePitchService(permissionGranted: false);
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);
      final controller = container.read(trainerControllerProvider.notifier);

      await controller.play();

      final state = container.read(trainerControllerProvider);
      expect(state.isPlaying, isFalse);
      expect(state.isListening, isFalse);
      expect(state.message, TrainerController.microphoneDeniedMessage);
    });

    test('stop during microphone start-up does not leave the microphone on', () async {
      final mic = FakeMicrophonePitchService()..startGate = Completer<void>();
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);
      final controller = container.read(trainerControllerProvider.notifier);

      final playing = controller.play();
      // Attende che il trainer sia arrivato all'avvio del microfono.
      while (mic.startCalls == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await controller.stop();
      mic.startGate!.complete();
      await playing;

      expect(mic.isRecording, isFalse);
      expect(container.read(trainerControllerProvider).isListening, isFalse);
    });

    test('a cancelled start does not switch off the microphone of a newer run', () async {
      final firstGate = Completer<void>();
      final secondGate = Completer<void>();
      final mic = FakeMicrophonePitchService()..perCallGates.addAll([firstGate, secondGate]);
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);
      final controller = container.read(trainerControllerProvider.notifier);

      final first = controller.play();
      while (mic.startCalls == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      // Stop e nuovo Play mentre il primo avvio è ancora pendente.
      final second = controller.play();
      while (mic.startCalls < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      // Il nuovo avvio termina per primo, quello annullato dopo.
      secondGate.complete();
      await second;
      firstGate.complete();
      await first;

      expect(mic.isRecording, isTrue);
      expect(container.read(trainerControllerProvider).isListening, isTrue);
      await controller.stop();
      expect(mic.isRecording, isFalse);
    });

    test('a stopped listening sequence does not reset a newly started one', () async {
      final mic = FakeMicrophonePitchService();
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);
      final controller = container.read(trainerControllerProvider.notifier)
        ..updateMode(TrainerMode.listen)
        ..updateBpm(140)
        ..updateLoop(true);

      unawaited(controller.play());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      unawaited(controller.play());
      // Lascia terminare la prima sequenza (interrotta).
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(container.read(trainerControllerProvider).isPlaying, isTrue);
      await controller.stop();
      expect(container.read(trainerControllerProvider).isPlaying, isFalse);
    });
  });

  group('RangeTestController', () {
    test('the comfortable note sung at the start becomes the starting note', () async {
      final mic = FakeMicrophonePitchService();
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);
      final sub = container.listen(rangeTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      final controller = container.read(rangeTestControllerProvider.notifier);

      await controller.start();
      expect(container.read(rangeTestControllerProvider).phase, RangePhase.findingStart);

      // Il cantante tiene un MI3 (frame ogni ~25 ms) oltre la durata richiesta.
      const e3 = MusicalNote(pitchClass: PitchClass.e, octave: 3);
      await _sing(mic, e3, RangeTestController.startHold + const Duration(milliseconds: 150));

      final state = container.read(rangeTestControllerProvider);
      expect(state.phase, RangePhase.descending);
      expect(state.startMidi, e3.midiNumber);
      expect(state.lowestMidi, e3.midiNumber, reason: 'la nota di partenza vale come convalidata');
      expect(state.highestMidi, e3.midiNumber);
      expect(state.validatedCount, 1);
      expect(state.targetMidi, e3.midiNumber - 1, reason: 'si scende dal semitono sotto');
    });

    test('a short note or a change of note does not set the starting note', () async {
      final mic = FakeMicrophonePitchService();
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);
      final sub = container.listen(rangeTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      final controller = container.read(rangeTestControllerProvider.notifier);

      await controller.start();
      const g3 = MusicalNote(pitchClass: PitchClass.g, octave: 3);
      const c4 = MusicalNote(pitchClass: PitchClass.c, octave: 4);
      await _sing(mic, g3, const Duration(milliseconds: 500));
      var state = container.read(rangeTestControllerProvider);
      expect(state.phase, RangePhase.findingStart);
      expect(state.startHoldProgress, inExclusiveRange(0.3, 1));

      // Cambia nota: il conteggio riparte.
      await _sing(mic, c4, const Duration(milliseconds: 400));
      state = container.read(rangeTestControllerProvider);
      expect(state.phase, RangePhase.findingStart);
      await _sing(mic, c4, const Duration(milliseconds: 550));
      expect(container.read(rangeTestControllerProvider).startMidi, c4.midiNumber);
    });

    test('counts validated and skipped notes for the UI', () async {
      final mic = FakeMicrophonePitchService();
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);
      final sub = container.listen(rangeTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);
      final controller = container.read(rangeTestControllerProvider.notifier);

      await controller.start();
      const c4 = MusicalNote(pitchClass: PitchClass.c, octave: 4);
      await _sing(mic, c4, RangeTestController.startHold + const Duration(milliseconds: 150));
      var state = container.read(rangeTestControllerProvider);
      expect(state.validatedCount, 1);

      // Nota guida del SI3, poi il cantante la becca.
      await Future<void>.delayed(const Duration(milliseconds: 1150));
      await _sing(mic, state.targetNote, const Duration(milliseconds: 300));
      state = container.read(rangeTestControllerProvider);
      expect(state.validatedCount, 2);
      expect(state.skippedCount, 0);
      expect(state.lowestMidi, c4.midiNumber - 1);

      controller.skipNote();
      state = container.read(rangeTestControllerProvider);
      expect(state.skippedCount, 1);
      expect(state.validatedCount, 2);
    });

    test('permission denied returns to setup with a message', () async {
      final mic = FakeMicrophonePitchService(permissionGranted: false);
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);
      final sub = container.listen(rangeTestControllerProvider, (previous, next) {});
      addTearDown(sub.close);

      await container.read(rangeTestControllerProvider.notifier).start();

      final state = container.read(rangeTestControllerProvider);
      expect(state.phase, RangePhase.setup);
      expect(state.isListening, isFalse);
      expect(state.message, contains('Permesso microfono negato'));
    });

    test('auto-dispose while testing releases the microphone without errors', () async {
      final mic = FakeMicrophonePitchService();
      final container = _container(mic, FakeMidiPro());
      addTearDown(container.dispose);
      final sub = container.listen(rangeTestControllerProvider, (previous, next) {});

      await container.read(rangeTestControllerProvider.notifier).start();
      expect(mic.isRecording, isTrue);

      // Uscita dalla schermata: il provider autoDispose viene distrutto.
      sub.close();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(mic.isRecording, isFalse);
    });
  });
}
