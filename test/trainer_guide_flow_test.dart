import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/core/pitch/pitch_detection_result.dart';
import 'package:vocal_scale_trainer/features/trainer/domain/note_progress.dart';
import 'package:vocal_scale_trainer/features/trainer/presentation/controllers/trainer_controller.dart';
import 'package:vocal_scale_trainer/services/audio/piano_audio_service.dart';

import 'support/audio_fakes.dart';

PitchDetectionResult _sung(MusicalNote note) => PitchDetectionResult(
      frequency: note.frequency,
      note: note,
      cents: 0,
      confidence: 1,
      isStable: true,
    );

/// Mantiene [note] stabile oltre la durata di stabilità (default 100 ms),
/// con un frame ogni ~25 ms come il rilevatore reale.
Future<void> _hold(FakeMicrophonePitchService mic, MusicalNote note) async {
  for (var i = 0; i < 12; i++) {
    mic.emit(_sung(note));
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

/// Attende la fine del mute dopo una nota guida (650 ms + 450 ms).
Future<void> _waitGuideMute() => Future<void>.delayed(const Duration(milliseconds: 1150));

void main() {
  late FakeMicrophonePitchService mic;
  late FakeMidiPro midi;
  late ProviderContainer container;

  setUp(() {
    mic = FakeMicrophonePitchService();
    midi = FakeMidiPro();
    container = ProviderContainer(
      overrides: [
        microphonePitchServiceProvider.overrideWithValue(mic),
        pianoAudioServiceProvider.overrideWithValue(PianoAudioService(midiPro: midi)),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('with the guide on every note, a correct note advances at once and plays the next guide',
      () async {
    final controller = container.read(trainerControllerProvider.notifier)
      ..updateGuideEveryNote(true);
    final sequence = container.read(trainerControllerProvider).sequence;
    expect(sequence[0], isNot(sequence[1]));

    await controller.play();
    await _waitGuideMute();
    await _hold(mic, sequence[0]);

    var state = container.read(trainerControllerProvider);
    expect(state.progress[0], NoteProgressStatus.correct);
    expect(state.currentIndex, 1, reason: 'avanza subito, senza cantare la nota successiva');
    expect(midi.played.last, sequence[1].midiNumber, reason: 'la guida suona la nota successiva');

    // Tenere ancora la nota precedente non è un errore sulla nuova nota.
    await _waitGuideMute();
    await _hold(mic, sequence[0]);
    state = container.read(trainerControllerProvider);
    expect(state.currentIndex, 1);
    expect(state.progress[1], NoteProgressStatus.current);

    // La nota successiva viene convalidata (una sola tenuta) e si avanza di nuovo.
    await _hold(mic, sequence[1]);
    state = container.read(trainerControllerProvider);
    expect(state.progress[1], NoteProgressStatus.correct);
    expect(state.currentIndex, 2);
    expect(state.sessionStats.attempts.where((a) => !a.correct), isEmpty);

    await controller.stop();
  });

  test('without the guide on every note, the next note waits for the singer to move on', () async {
    final controller = container.read(trainerControllerProvider.notifier)
      ..updateGuideEveryNote(false);
    final sequence = container.read(trainerControllerProvider).sequence;

    await controller.play();
    await _waitGuideMute();
    await _hold(mic, sequence[0]);

    var state = container.read(trainerControllerProvider);
    expect(state.progress[0], NoteProgressStatus.correct);
    expect(state.currentIndex, 0, reason: 'comportamento invariato senza guida su ogni nota');

    await _hold(mic, sequence[1]);
    state = container.read(trainerControllerProvider);
    expect(state.currentIndex, 1);

    await controller.stop();
  });

  test('tapping a note plays it once and pauses listening, without the guide on every note',
      () async {
    final controller = container.read(trainerControllerProvider.notifier)
      ..updateGuideEveryNote(false);
    final sequence = container.read(trainerControllerProvider).sequence;

    await controller.play();
    await _waitGuideMute();
    final playedBefore = midi.played.length;

    // Il cantante si è perso: tocca la nota corrente per riascoltarla.
    await controller.listenNote(0);
    expect(midi.played.length, playedBefore + 1, reason: 'una sola nota');
    expect(midi.played.last, sequence[0].midiNumber);

    // Mentre suona il piano l'ascolto è sospeso: il suono captato non conta.
    await _hold(mic, sequence[0]);
    var state = container.read(trainerControllerProvider);
    expect(state.progress[0], NoteProgressStatus.current);
    expect(state.sessionStats.attempts, isEmpty);

    // Finita la pausa si torna ad ascoltare normalmente.
    await _waitGuideMute();
    await _hold(mic, sequence[0]);
    state = container.read(trainerControllerProvider);
    expect(state.progress[0], NoteProgressStatus.correct);

    // Anche una nota diversa dalla corrente si può ascoltare.
    await controller.listenNote(2);
    expect(midi.played.last, sequence[2].midiNumber);
    expect(container.read(trainerControllerProvider).currentIndex, 0,
        reason: "ascoltare non fa avanzare l'esercizio");

    await controller.stop();
  });

  test('completing the exercise produces the result shown at the end', () async {
    final controller = container.read(trainerControllerProvider.notifier)
      ..updateGuideEveryNote(false);
    final sequence = container.read(trainerControllerProvider).sequence;

    await controller.play();
    await _waitGuideMute();
    expect(container.read(trainerControllerProvider).completedSession, isNull);
    for (final note in sequence) {
      await _hold(mic, note);
    }

    final state = container.read(trainerControllerProvider);
    final record = state.completedSession;
    expect(record, isNotNull);
    expect(record!.correct, sequence.length);
    expect(record.accuracyPercent, 100);
    expect(state.isPlaying, isFalse);

    // Un nuovo giro azzera il risultato.
    await controller.play();
    expect(container.read(trainerControllerProvider).completedSession, isNull);
    await controller.stop();
  });
}
