import 'package:flutter_test/flutter_test.dart';
import 'package:vocal_scale_trainer/core/music/note.dart';
import 'package:vocal_scale_trainer/services/audio/piano_audio_service.dart';

import 'support/audio_fakes.dart';

void main() {
  const c4 = MusicalNote(pitchClass: PitchClass.c, octave: 4);
  const d4 = MusicalNote(pitchClass: PitchClass.d, octave: 4);
  const e4 = MusicalNote(pitchClass: PitchClass.e, octave: 4);

  test('concurrent initialize loads the SoundFont only once', () async {
    final midi = FakeMidiPro();
    final audio = PianoAudioService(midiPro: midi);

    await Future.wait([audio.initialize(), audio.initialize(), audio.playNote(c4)]);

    expect(midi.loadCount, 1);
  });

  test('stopAll cancels a running sequence, which reports it was interrupted', () async {
    final midi = FakeMidiPro();
    final audio = PianoAudioService(midiPro: midi);
    final indexes = <int>[];

    final run = audio.playSequence(
      notes: const [c4, d4, e4],
      bpm: 600, // 100 ms per nota
      loop: true,
      onNote: indexes.add,
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await audio.stopAll();
    final completed = await run;
    final countAtStop = indexes.length;
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(completed, isFalse);
    expect(indexes.length, countAtStop, reason: 'nessuna nota dopo lo stop');
    expect(midi.sounding, isEmpty);
  });

  test('Stop then Play quickly does not leave two overlapping sequences', () async {
    final midi = FakeMidiPro();
    final audio = PianoAudioService(midiPro: midi);
    final first = <int>[];
    final second = <int>[];

    final run1 = audio.playSequence(
      notes: const [c4, d4, e4],
      bpm: 600,
      loop: true,
      onNote: first.add,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await audio.stopAll();
    final firstCountAtStop = first.length;
    // Nuova sequenza mentre la prima è ancora in attesa del beat.
    final run2 = audio.playSequence(
      notes: const [c4, d4, e4],
      bpm: 600,
      loop: false,
      onNote: second.add,
    );

    expect(await run1, isFalse);
    expect(await run2, isTrue);
    expect(first.length, firstCountAtStop, reason: 'la prima sequenza non deve ripartire');
    expect(second, [0, 1, 2]);
  });

  test('delayed stop of a note does not cut a later repetition of the same note', () async {
    final midi = FakeMidiPro();
    final audio = PianoAudioService(midiPro: midi);

    await audio.playNote(c4, duration: const Duration(milliseconds: 80));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await audio.playNote(c4, duration: const Duration(milliseconds: 200));
    // Scade lo stop programmato della prima pressione.
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(midi.sounding, contains(c4.midiNumber));

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(midi.sounding, isEmpty);
  });

  test('dispose stops notes and unloads the SoundFont', () async {
    final midi = FakeMidiPro();
    final audio = PianoAudioService(midiPro: midi);

    await audio.playNote(c4, duration: const Duration(seconds: 5));
    await audio.dispose();

    expect(midi.sounding, isEmpty);
    expect(midi.unloaded, [1]);
  });
}
