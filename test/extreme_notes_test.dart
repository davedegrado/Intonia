import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_detection_result.dart';
import 'package:vocal_scale_trainer/features/access/application/access_providers.dart';
import 'package:vocal_scale_trainer/features/extreme_notes/application/extreme_notes_controller.dart';
import 'package:vocal_scale_trainer/features/extreme_notes/domain/extreme_notes.dart';
import 'package:vocal_scale_trainer/features/settings/application/settings_providers.dart';
import 'package:vocal_scale_trainer/features/tessitura/application/tessitura_providers.dart';
import 'package:vocal_scale_trainer/features/tessitura/domain/tessitura.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/controllers/trainer_controller.dart';
import 'package:vocal_scale_trainer/services/storage/json_list_repository.dart';

import 'support/access_fakes.dart';
import 'support/audio_fakes.dart';

PitchDetectionResult _voiced(double midi, {double confidence = 0.95}) {
  final frequency = 440 * math.pow(2, (midi - 69) / 12).toDouble();
  return PitchDetectionResult(
    frequency: frequency,
    note: MusicalNote.fromFrequency(frequency),
    cents: 0,
    confidence: confidence,
    isStable: true,
  );
}

/// Alimenta il tracker con frame ogni 23 ms.
class _Feed {
  _Feed(this.tracker);

  final ExtremeNotesTracker tracker;

  void frames(int ms, PitchDetectionResult Function(int t) frame) {
    for (var t = 0; t < ms; t += 23) {
      tracker.add(frame(t));
    }
  }

  void sing(double midi, int ms) => frames(ms, (_) => _voiced(midi));
  void rest(int ms) => frames(ms, (_) => PitchDetectionResult.silence);
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
  group('ExtremeNotesTracker', () {
    test('11. finds the highest and lowest notes of a valid melody', () {
      final feed = _Feed(ExtremeNotesTracker());
      for (final note in <double>[55, 59, 62, 67, 64, 60, 52, 55]) {
        feed.sing(note, 400);
        feed.rest(120);
      }
      final result = feed.tracker.result();
      expect((result.lowest, result.highest), (52, 67));
      expect(result.confirmedNotes, 7);
    });

    test('12. ignores silent, unstable and low-confidence frames', () {
      final feed = _Feed(ExtremeNotesTracker());
      feed.rest(2000);
      // Frame "instabili" del rilevatore (confidenza sotto la soglia).
      feed.frames(
          2000,
          (t) => PitchDetectionResult(
                frequency: 300 + t.toDouble(),
                note: MusicalNote.fromFrequency(300 + t.toDouble()),
                cents: 0,
                confidence: 0.4,
                isStable: false,
              ));
      expect(feed.tracker.result().isEmpty, isTrue);
    });

    test('13. a single wrong frame (e.g. an octave error) does not create a false extreme', () {
      final feed = _Feed(ExtremeNotesTracker());
      feed.frames(1000, (t) => t == 460 ? _voiced(84) : _voiced(60));
      feed.frames(1000, (t) => t >= 230 && t < 276 ? _voiced(36) : _voiced(62));
      final result = feed.tracker.result();
      expect((result.lowest, result.highest), (60, 62));
      expect(result.spikes, greaterThan(0));
    });

    test('14. keeps an authentic extreme even if far from the other notes', () {
      final feed = _Feed(ExtremeNotesTracker());
      feed.sing(60, 2000);
      feed.sing(79, 300); // salto di quasi due ottave, breve ma tenuto
      feed.sing(60, 1000);
      var result = feed.tracker.result();
      expect(result.highest, 79);
      expect(result.highestCertain, isFalse, reason: 'sentita una volta, per poco: incerta');
      expect(result.lowestCertain, isTrue);
      feed.rest(300);
      feed.sing(79, 300);
      result = feed.tracker.result();
      expect(result.highestCertain, isTrue, reason: 'ritrovata in una seconda emissione');
    });

    test('15. a session without valid notes has no result', () {
      final feed = _Feed(ExtremeNotesTracker());
      feed.rest(3000);
      feed.sing(60, 120); // troppo breve per essere riconosciuta
      final result = feed.tracker.result();
      expect(result.isEmpty, isTrue);
      expect(result.spanSemitones, isNull);
      expect(result.quality, DetectionQuality.poor);
    });

    test('16. with a single reliable note there is no interval', () {
      final feed = _Feed(ExtremeNotesTracker());
      feed.sing(57.2, 3000);
      final result = feed.tracker.result();
      expect(result.single, isTrue);
      expect(result.lowest, 57);
      expect(result.spanSemitones, isNull);
    });

    test('17. the interval is counted in semitones across octaves', () {
      final feed = _Feed(ExtremeNotesTracker());
      feed.sing(45, 600); // LA2
      feed.sing(69, 600); // LA4
      feed.sing(76, 600); // MI5
      final result = feed.tracker.result();
      expect(result.spanSemitones, 31);
      expect(MusicalNote.fromMidi(result.lowest!).octave, 2);
      expect(MusicalNote.fromMidi(result.highest!).octave, 5);
    });

    test('notes are not limited to a previously estimated comfort zone', () {
      final feed = _Feed(ExtremeNotesTracker());
      feed.sing(38, 800); // RE2, molto grave
      feed.sing(84, 800); // DO6, molto acuto
      expect((feed.tracker.lowest, feed.tracker.highest), (38, 84));
    });
  });

  group('ExtremeNotesController', () {
    late FakeMicrophonePitchService mic;
    late _MemoryTessitura tessitura;
    late DateTime now;
    late ProviderContainer container;

    setUp(() {
      mic = FakeMicrophonePitchService();
      tessitura = _MemoryTessitura();
      now = DateTime(2026, 10, 19, 9);
      container = ProviderContainer(overrides: [
        microphonePitchServiceProvider.overrideWithValue(mic),
        chargesRepositoryProvider.overrideWithValue(InMemoryChargesRepository()),
        deviceLocaleProvider.overrideWithValue(const Locale('it')),
        tessituraRepositoryProvider.overrideWithValue(tessitura),
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(container.dispose);
      final sub = container.listen(extremeNotesControllerProvider, (previous, next) {});
      addTearDown(sub.close);
    });

    ExtremeNotesState read() => container.read(extremeNotesControllerProvider);
    ExtremeNotesController controller() => container.read(extremeNotesControllerProvider.notifier);

    Future<void> sing(double midi, int ms) async {
      for (var t = 0; t < ms; t += 23) {
        now = now.add(const Duration(milliseconds: 23));
        mic.emit(_voiced(midi));
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('18. no reference notes: listens, updates live, stops the microphone at the end',
        () async {
      await controller().start();
      expect(read().phase, ExtremeNotesPhase.listening);
      expect(mic.isRecording, isTrue);
      await sing(55, 500);
      await sing(64, 500);
      expect((read().lowest, read().highest), (55, 64));
      await controller().stop();
      expect(read().phase, ExtremeNotesPhase.done);
      expect(mic.isRecording, isFalse);
      expect((read().result!.lowest, read().result!.highest), (55, 64));
      // Frame arrivati dopo la fine: ignorati.
      await sing(80, 500);
      expect(read().result!.highest, 64);
      expect(tessitura.saved, isEmpty, reason: 'la tessitura non cambia');
    });

    test('19/21. a new session starts from scratch, without data from the previous one', () async {
      await controller().start();
      await sing(40, 500);
      await sing(80, 500);
      await controller().stop();
      expect(read().result!.spanSemitones, 40);

      await controller().start();
      expect(read().lowest, isNull);
      expect(read().result, isNull);
      await sing(60, 800);
      await controller().stop();
      final result = read().result!;
      expect(result.single, isTrue);
      expect(result.lowest, 60);
    });

    test('20. microphone denied, audio unavailable and interruptions', () async {
      mic.permissionGranted = false;
      await controller().start();
      expect((read().phase, read().message),
          (ExtremeNotesPhase.intro, ExtremeNotesMessage.microphoneDenied));

      mic
        ..permissionGranted = true
        ..startError = StateError('no audio');
      await controller().start();
      expect(read().message, ExtremeNotesMessage.audioUnavailable);

      mic.startError = null;
      await controller().start();
      await sing(62, 500);
      mic.emitError(StateError('microphone lost'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(read().phase, ExtremeNotesPhase.done);
      expect(read().message, ExtremeNotesMessage.interrupted);
      expect(read().result!.lowest, 62, reason: 'si mostra quanto sentito fino a lì');
      expect(mic.isRecording, isFalse);
    });

    test('leaving the screen releases the microphone', () async {
      await controller().start();
      expect(mic.isRecording, isTrue);
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(mic.isRecording, isFalse);
    });
  });
}
