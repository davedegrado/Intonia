import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/features/range/application/range_test_controller.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/training_settings.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/controllers/trainer_controller.dart';
import 'package:vocal_scale_trainer/features/tuner/application/tuner_controller.dart';
import 'package:vocal_scale_trainer/services/audio/piano_audio_service.dart';

import 'support/audio_fakes.dart';

ProviderContainer _container(FakeMicrophonePitchService mic, FakeMidiPro midi) {
  return ProviderContainer(
    overrides: [
      microphonePitchServiceProvider.overrideWithValue(mic),
      pianoAudioServiceProvider.overrideWithValue(PianoAudioService(midiPro: midi)),
    ],
  );
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
